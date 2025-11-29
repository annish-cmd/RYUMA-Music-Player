import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/track.dart';

class AudioPlayerHandler {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Track> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffleEnabled = false;

  // Stream controllers - using BehaviorSubject for currentTrack so new listeners get the current value
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

  // Streams
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

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // Handle track completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // Listen for sequence state changes (for playlist navigation)
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex && _playlist.isNotEmpty) {
        _currentIndex = index;
        if (_currentIndex < _playlist.length) {
          _currentTrackController.add(_playlist[_currentIndex]);
        }
      }
    });
  }

  // Set playlist
  Future<void> setPlaylist(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;

    _playlist = List.from(tracks);
    _currentIndex = initialIndex.clamp(0, tracks.length - 1);
    _playlistController.add(_playlist);

    // Create audio sources
    final audioSources = tracks
        .map((track) => _createAudioSource(track))
        .toList();

    // Set the playlist
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: initialIndex,
    );

    _currentTrackController.add(_playlist[_currentIndex]);
  }

  AudioSource _createAudioSource(Track track) {
    return AudioSource.file(track.data!, tag: track.id.toString());
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

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

  // Custom methods
  Future<void> playTrack(Track track) async {
    final index = _playlist.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      _currentIndex = index;
      await _player.seek(Duration.zero, index: index);
      _currentTrackController.add(track);
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

  LoopMode get loopMode => _player.loopMode;

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
