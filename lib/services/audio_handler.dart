import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Track> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffleEnabled = false;

  // Stream controllers for app-level state
  final _currentTrackController = BehaviorSubject<Track?>();
  final _playlistController = BehaviorSubject<List<Track>>.seeded([]);
  final _isShuffleController = BehaviorSubject<bool>.seeded(false);

  // Getters
  AudioPlayer get player => _player;
  List<Track> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Track? get currentTrack =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;
  bool get isShuffleEnabled => _isShuffleEnabled;

  // Streams for UI
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<List<Track>> get playlistStream => _playlistController.stream;
  Stream<bool> get isShuffleStream => _isShuffleController.stream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  LoopMode get loopMode => _player.loopMode;

  AudioPlayerHandler() {
    debugPrint('AudioPlayerHandler: Constructor called');
    _init();
  }

  Future<void> _init() async {
    debugPrint('AudioPlayerHandler: _init() starting...');

    // Broadcast playback state changes to system
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    // Handle track completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // Listen for current index changes
    _player.currentIndexStream.listen((index) {
      if (index != null && _playlist.isNotEmpty && index < _playlist.length) {
        _currentIndex = index;
        _currentTrackController.add(_playlist[_currentIndex]);
        // Update media item for lock screen notification
        mediaItem.add(_createMediaItem(_playlist[_currentIndex]));
      }
    });

    // Listen for duration changes to update media item
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  /// Broadcast the current playback state to the system (for lock screen/notification)
  void _broadcastState() {
    debugPrint(
      'AudioPlayerHandler: Broadcasting state - playing: ${_player.playing}, position: ${_player.position}',
    );
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _getProcessingState(),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ),
    );
  }

  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Create MediaItem from Track for lock screen display
  MediaItem _createMediaItem(Track track) {
    debugPrint(
      'AudioPlayerHandler: Creating MediaItem for "${track.title}" by ${track.artist}',
    );
    return MediaItem(
      id: track.data ?? track.id.toString(),
      title: track.title,
      artist: track.artist,
      album: track.album ?? 'Unknown Album',
      duration: track.duration != null
          ? Duration(milliseconds: track.duration!)
          : null,
      artUri: track.albumId != null
          ? Uri.parse(
              'content://media/external/audio/albumart/${track.albumId}',
            )
          : null,
      extras: {'trackId': track.id},
    );
  }

  /// Set playlist and start playback
  Future<void> setPlaylist(List<Track> tracks, {int initialIndex = 0}) async {
    debugPrint(
      'AudioPlayerHandler: setPlaylist() called with ${tracks.length} tracks',
    );
    if (tracks.isEmpty) return;

    _playlist = List.from(tracks);
    _currentIndex = initialIndex.clamp(0, tracks.length - 1);
    _playlistController.add(_playlist);

    // Create audio sources
    final audioSources = _playlist
        .map((track) => AudioSource.file(track.data!, tag: track.id.toString()))
        .toList();

    // Update the queue for audio_service
    debugPrint(
      'AudioPlayerHandler: Updating queue with ${tracks.length} items',
    );
    queue.add(tracks.map((t) => _createMediaItem(t)).toList());

    // Set the audio source
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: initialIndex,
    );

    // Update current track
    final currentTrack = _playlist[_currentIndex];
    debugPrint(
      'AudioPlayerHandler: Setting current track: "${currentTrack.title}"',
    );
    _currentTrackController.add(currentTrack);

    final item = _createMediaItem(currentTrack);
    debugPrint('AudioPlayerHandler: Adding mediaItem to stream');
    mediaItem.add(item);

    _broadcastState();
    debugPrint('AudioPlayerHandler: setPlaylist() completed');
  }

  // BaseAudioHandler overrides for lock screen controls

  @override
  Future<void> play() async {
    debugPrint('AudioPlayerHandler: play() called');
    await _player.play();
    _broadcastState();
    debugPrint(
      'AudioPlayerHandler: play() completed, isPlaying: ${_player.playing}',
    );
  }

  @override
  Future<void> pause() async {
    debugPrint('AudioPlayerHandler: pause() called');
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    if (_isShuffleEnabled) {
      final available = List.generate(
        _playlist.length,
        (i) => i,
      ).where((i) => i != _currentIndex).toList();
      if (available.isNotEmpty) {
        final newIndex =
            available[DateTime.now().millisecondsSinceEpoch % available.length];
        await _player.seek(Duration.zero, index: newIndex);
      }
    } else {
      if (_player.hasNext) {
        await _player.seekToNext();
      } else {
        // Loop back to start
        await _player.seek(Duration.zero, index: 0);
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_isShuffleEnabled) {
      final available = List.generate(
        _playlist.length,
        (i) => i,
      ).where((i) => i != _currentIndex).toList();
      if (available.isNotEmpty) {
        final newIndex =
            available[DateTime.now().millisecondsSinceEpoch % available.length];
        await _player.seek(Duration.zero, index: newIndex);
      }
    } else {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else {
        // Loop to end
        await _player.seek(Duration.zero, index: _playlist.length - 1);
      }
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    _isShuffleEnabled = enabled;
    _isShuffleController.add(enabled);
    await _player.setShuffleModeEnabled(enabled);
  }

  // App-level methods

  Future<void> playTrack(Track track) async {
    final index = _playlist.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      _currentIndex = index;
      await _player.seek(Duration.zero, index: index);
      _currentTrackController.add(track);
      mediaItem.add(_createMediaItem(track));
      await play();
    } else {
      await setPlaylist([track], initialIndex: 0);
      await play();
    }
  }

  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    await _player.seek(Duration.zero, index: index);
    _currentTrackController.add(_playlist[_currentIndex]);
    mediaItem.add(_createMediaItem(_playlist[_currentIndex]));
    await play();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    _isShuffleController.add(_isShuffleEnabled);
    _player.setShuffleModeEnabled(_isShuffleEnabled);
  }

  void setShuffle(bool enabled) {
    _isShuffleEnabled = enabled;
    _isShuffleController.add(_isShuffleEnabled);
    _player.setShuffleModeEnabled(_isShuffleEnabled);
  }

  Future<void> toggleRepeatMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  void _onTrackCompleted() {
    if (_player.loopMode == LoopMode.one) {
      seek(Duration.zero);
      play();
    } else if (_player.loopMode == LoopMode.all ||
        _currentIndex < _playlist.length - 1) {
      skipToNext();
    }
  }

  String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _currentTrackController.close();
    await _playlistController.close();
    await _isShuffleController.close();
  }
}
