import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Track> _allTracks = [];
  bool _isInitialized = false;

  // Getters
  List<Track> get allTracks => _allTracks;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<bool> initialize() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('Storage permission denied');
        return false;
      }

      await loadAllTracks();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing MusicService: $e');
      return false;
    }
  }

  // Check if storage permissions are already granted (without requesting)
  Future<bool> checkPermissionStatus() async {
    try {
      // Check for audio permission (Android 13+)
      if (await Permission.audio.isGranted) {
        return true;
      }

      // Check for storage permission (Android 12 and below)
      if (await Permission.storage.isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking permission status: $e');
      return false;
    }
  }

  // Request storage permissions
  Future<bool> requestPermissions() async {
    try {
      // Check if already granted first
      if (await checkPermissionStatus()) {
        return true;
      }

      // Request appropriate permission based on Android version
      PermissionStatus status;

      // Try audio permission first (Android 13+)
      status = await Permission.audio.request();
      if (status.isGranted) {
        return true;
      }

      // Fall back to storage permission (Android 12 and below)
      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // If denied, check if we can request again
      if (status.isDenied) {
        print('Permission denied. Please enable storage access in settings.');
      } else if (status.isPermanentlyDenied) {
        print('Permission permanently denied. Please enable in app settings.');
        await openAppSettings();
      }

      return false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // Minimum duration for music files (30 seconds in milliseconds)
  static const int _minDurationMs = 30000;

  // Paths to exclude (system sounds, notifications, ringtones, alarms)
  static const List<String> _excludedPaths = [
    '/system/',
    '/ringtones/',
    '/ringtone/',
    '/notifications/',
    '/notification/',
    '/alarms/',
    '/alarm/',
    '/ui/',
    '/ogg/',
    'sound_recorder',
    '/sounds/',
    'voice_recorder',
    'call_rec',
    '/recording/',
    'whatsapp audio',
    'telegram',
  ];

  // Check if a song should be excluded based on path
  bool _shouldExcludeSong(SongModel song) {
    final path = song.data.toLowerCase();

    // Exclude if path contains any excluded keywords
    for (final excluded in _excludedPaths) {
      if (path.contains(excluded.toLowerCase())) {
        return true;
      }
    }

    // Exclude very short audio files (likely sound effects)
    if (song.duration != null && song.duration! < _minDurationMs) {
      return true;
    }

    return false;
  }

  // Load all tracks from device
  Future<List<Track>> loadAllTracks({bool refresh = false}) async {
    try {
      if (_allTracks.isNotEmpty && !refresh) {
        return _allTracks;
      }

      print('Loading all tracks from device...');

      final List<SongModel> songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      print('Found ${songs.length} total audio files');

      // Filter out system sounds, notifications, ringtones, and short audio
      final filteredSongs = songs
          .where((song) => !_shouldExcludeSong(song))
          .toList();

      print('Filtered to ${filteredSongs.length} music tracks');

      _allTracks = filteredSongs
          .map((song) => Track.fromSongModel(song))
          .toList();

      return _allTracks;
    } catch (e) {
      print('Error loading tracks: $e');
      return [];
    }
  }

  // Reload tracks from device
  Future<List<Track>> refreshTracks() async {
    return await loadAllTracks(refresh: true);
  }

  // Get tracks by album
  Future<List<Track>> getTracksByAlbum(int albumId) async {
    try {
      final List<SongModel> songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        albumId,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      // Filter out system sounds and short audio
      final filteredSongs = songs
          .where((song) => !_shouldExcludeSong(song))
          .toList();

      return filteredSongs.map((song) => Track.fromSongModel(song)).toList();
    } catch (e) {
      print('Error loading tracks by album: $e');
      return [];
    }
  }

  // Get tracks by artist
  Future<List<Track>> getTracksByArtist(int artistId) async {
    try {
      final List<SongModel> songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ARTIST_ID,
        artistId,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      // Filter out system sounds and short audio
      final filteredSongs = songs
          .where((song) => !_shouldExcludeSong(song))
          .toList();

      return filteredSongs.map((song) => Track.fromSongModel(song)).toList();
    } catch (e) {
      print('Error loading tracks by artist: $e');
      return [];
    }
  }

  // Search tracks
  List<Track> searchTracks(String query) {
    if (query.isEmpty) return _allTracks;

    final lowerQuery = query.toLowerCase();
    return _allTracks.where((track) {
      return track.title.toLowerCase().contains(lowerQuery) ||
          track.artist.toLowerCase().contains(lowerQuery) ||
          (track.album?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get albums
  Future<List<AlbumModel>> getAlbums() async {
    try {
      return await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } catch (e) {
      print('Error loading albums: $e');
      return [];
    }
  }

  // Get artists
  Future<List<ArtistModel>> getArtists() async {
    try {
      return await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } catch (e) {
      print('Error loading artists: $e');
      return [];
    }
  }

  // Get album artwork
  Future<List<int>?> getAlbumArt(int albumId) async {
    try {
      return await _audioQuery.queryArtwork(
        albumId,
        ArtworkType.ALBUM,
        format: ArtworkFormat.JPEG,
        size: 200,
      );
    } catch (e) {
      print('Error loading album art: $e');
      return null;
    }
  }

  // Get track by ID
  Track? getTrackById(int id) {
    try {
      return _allTracks.firstWhere((track) => track.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get tracks by IDs
  List<Track> getTracksByIds(List<int> ids) {
    return _allTracks.where((track) => ids.contains(track.id)).toList();
  }

  // Get recently added tracks
  List<Track> getRecentlyAdded({int limit = 20}) {
    final sortedTracks = List<Track>.from(_allTracks)
      ..sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return sortedTracks.take(limit).toList();
  }

  // Get tracks sorted by duration
  List<Track> getTracksSortedByDuration({bool descending = false}) {
    final sortedTracks = List<Track>.from(_allTracks)
      ..sort((a, b) {
        final durationA = a.duration ?? 0;
        final durationB = b.duration ?? 0;
        return descending
            ? durationB.compareTo(durationA)
            : durationA.compareTo(durationB);
      });
    return sortedTracks;
  }

  // Get tracks by genre (if available)
  Future<List<Track>> getTracksByGenre(int genreId) async {
    try {
      final List<SongModel> songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.GENRE_ID,
        genreId,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      // Filter out system sounds and short audio
      final filteredSongs = songs
          .where((song) => !_shouldExcludeSong(song))
          .toList();

      return filteredSongs.map((song) => Track.fromSongModel(song)).toList();
    } catch (e) {
      print('Error loading tracks by genre: $e');
      return [];
    }
  }

  // Get genres
  Future<List<GenreModel>> getGenres() async {
    try {
      return await _audioQuery.queryGenres(
        sortType: GenreSortType.GENRE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } catch (e) {
      print('Error loading genres: $e');
      return [];
    }
  }

  // Get total duration of all tracks
  Duration getTotalDuration() {
    int totalMilliseconds = 0;
    for (var track in _allTracks) {
      totalMilliseconds += track.duration ?? 0;
    }
    return Duration(milliseconds: totalMilliseconds);
  }

  // Get total size of all tracks
  int getTotalSize() {
    int totalSize = 0;
    for (var track in _allTracks) {
      totalSize += track.size ?? 0;
    }
    return totalSize;
  }

  // Format file size
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // Check if device has any audio files
  Future<bool> hasAudioFiles() async {
    try {
      final songs = await _audioQuery.querySongs();
      return songs.isNotEmpty;
    } catch (e) {
      print('Error checking audio files: $e');
      return false;
    }
  }

  // Get track count
  int getTrackCount() => _allTracks.length;

  // Clear cache
  void clearCache() {
    _allTracks.clear();
    _isInitialized = false;
  }

  // Dispose
  void dispose() {
    clearCache();
  }
}
