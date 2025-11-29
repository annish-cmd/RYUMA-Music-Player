import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/track.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Streams
  final BehaviorSubject<List<Track>> _playlistController =
      BehaviorSubject<List<Track>>.seeded([]);
  final BehaviorSubject<Track?> _currentTrackController =
      BehaviorSubject<Track?>.seeded(null);
  final BehaviorSubject<int> _currentIndexController =
      BehaviorSubject<int>.seeded(0);
  final BehaviorSubject<bool> _isShuffleController =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<LoopMode> _loopModeController =
      BehaviorSubject<LoopMode>.seeded(LoopMode.off);

  // Getters for streams
  Stream<List<Track>> get playlistStream => _playlistController.stream;
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<bool> get isShuffleStream => _isShuffleController.stream;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<bool> get isPlayingStream =>
      _audioPlayer.playingStream.distinct().asBroadcastStream();
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  // Current values
  List<Track> get playlist => _playlistController.value;
  Track? get currentTrack => _currentTrackController.value;
  int get currentIndex => _currentIndexController.value;
  bool get isShuffling => _isShuffleController.value;
  LoopMode get loopMode => _loopModeController.value;
  bool get isPlaying => _audioPlayer.playing;
  Duration get currentPosition => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  // Initialize
  Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // Set audio session configuration
    await _audioPlayer.setLoopMode(LoopMode.off);
    await _audioPlayer.setVolume(1.0);
  }

  // Set playlist
  Future<void> setPlaylist(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;

    _playlistController.add(tracks);
    _currentIndexController.add(initialIndex);

    if (initialIndex >= 0 && initialIndex < tracks.length) {
      await _loadTrack(tracks[initialIndex]);
    }
  }

  // Load a specific track
  Future<void> _loadTrack(Track track) async {
    try {
      if (track.data != null) {
        _currentTrackController.add(track);
        await _audioPlayer.setFilePath(track.data!);
      }
    } catch (e) {
      print('Error loading track: $e');
    }
  }

  // Play current track
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing track: $e');
    }
  }

  // Pause
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing track: $e');
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  // Stop
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping track: $e');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // Play specific track by index
  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= playlist.length) return;

    _currentIndexController.add(index);
    await _loadTrack(playlist[index]);
    await play();
  }

  // Play specific track
  Future<void> playTrack(Track track) async {
    final index = playlist.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      await playTrackAt(index);
    } else {
      // If track not in playlist, create new playlist with this track
      await setPlaylist([track], initialIndex: 0);
      await play();
    }
  }

  // Next track
  Future<void> skipToNext() async {
    if (playlist.isEmpty) return;

    int nextIndex;
    if (isShuffling) {
      // Random next track (excluding current)
      final availableIndices = List.generate(
        playlist.length,
        (i) => i,
      ).where((i) => i != currentIndex).toList();
      if (availableIndices.isEmpty) {
        nextIndex = 0;
      } else {
        nextIndex =
            availableIndices[DateTime.now().millisecondsSinceEpoch %
                availableIndices.length];
      }
    } else {
      nextIndex = (currentIndex + 1) % playlist.length;
    }

    await playTrackAt(nextIndex);
  }

  // Previous track
  Future<void> skipToPrevious() async {
    if (playlist.isEmpty) return;

    // If current position > 3 seconds, restart current track
    if (currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex;
    if (isShuffling) {
      // Random previous track (excluding current)
      final availableIndices = List.generate(
        playlist.length,
        (i) => i,
      ).where((i) => i != currentIndex).toList();
      if (availableIndices.isEmpty) {
        prevIndex = 0;
      } else {
        prevIndex =
            availableIndices[DateTime.now().millisecondsSinceEpoch %
                availableIndices.length];
      }
    } else {
      prevIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    }

    await playTrackAt(prevIndex);
  }

  // Toggle shuffle
  Future<void> toggleShuffle() async {
    final newShuffleState = !isShuffling;
    _isShuffleController.add(newShuffleState);
  }

  // Set shuffle
  Future<void> setShuffle(bool enabled) async {
    _isShuffleController.add(enabled);
  }

  // Toggle repeat mode
  Future<void> toggleRepeatMode() async {
    LoopMode newMode;
    switch (loopMode) {
      case LoopMode.off:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.one;
        break;
      case LoopMode.one:
        newMode = LoopMode.off;
        break;
    }
    await setLoopMode(newMode);
  }

  // Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    _loopModeController.add(mode);
    await _audioPlayer.setLoopMode(mode);
  }

  // Handle track completion
  void _onTrackCompleted() {
    if (loopMode == LoopMode.one) {
      // Replay current track
      seek(Duration.zero);
      play();
    } else if (loopMode == LoopMode.all || currentIndex < playlist.length - 1) {
      // Play next track
      skipToNext();
    } else {
      // Stop at end of playlist
      stop();
    }
  }

  // Add track to playlist
  void addToPlaylist(Track track) {
    final updatedPlaylist = List<Track>.from(playlist)..add(track);
    _playlistController.add(updatedPlaylist);
  }

  // Add multiple tracks to playlist
  void addAllToPlaylist(List<Track> tracks) {
    final updatedPlaylist = List<Track>.from(playlist)..addAll(tracks);
    _playlistController.add(updatedPlaylist);
  }

  // Remove track from playlist
  void removeFromPlaylist(int index) {
    if (index < 0 || index >= playlist.length) return;

    final updatedPlaylist = List<Track>.from(playlist)..removeAt(index);
    _playlistController.add(updatedPlaylist);

    // Adjust current index if needed
    if (currentIndex >= updatedPlaylist.length && updatedPlaylist.isNotEmpty) {
      _currentIndexController.add(updatedPlaylist.length - 1);
    } else if (currentIndex == index) {
      // If removed track was playing, play next track
      if (updatedPlaylist.isNotEmpty) {
        playTrackAt(currentIndex.clamp(0, updatedPlaylist.length - 1));
      }
    }
  }

  // Clear playlist
  void clearPlaylist() {
    stop();
    _playlistController.add([]);
    _currentTrackController.add(null);
    _currentIndexController.add(0);
  }

  // Get track info
  String getCurrentTrackInfo() {
    if (currentTrack == null) return 'No track playing';
    return '${currentTrack!.title} - ${currentTrack!.artist}';
  }

  // Format duration to readable string
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

  // Dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playlistController.close();
    await _currentTrackController.close();
    await _currentIndexController.close();
    await _isShuffleController.close();
    await _loopModeController.close();
  }
}
