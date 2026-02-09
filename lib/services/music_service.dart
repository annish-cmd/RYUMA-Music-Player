import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Track> _allTracks = [];
  DateTime? _lastLoadTime;
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

  // Minimum duration for music files (10 seconds in milliseconds) - less restrictive
  static const int _minDurationMs = 10000;

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
    final path = song.data?.toLowerCase() ?? '';

    // Exclude if path contains any excluded keywords
    for (final excluded in _excludedPaths) {
      if (path.contains(excluded.toLowerCase())) {
        print('Excluding track due to path: ${song.title} (path contains: $excluded)');
        return true;
      }
    }

    // Check duration validity
    if (song.duration != null) {
      // Minimum duration check (30 seconds)
      if (song.duration! < _minDurationMs) {
        print('Excluding short track: ${song.title} (${song.duration}ms < ${_minDurationMs}ms)');
        return true;
      }

      // Maximum reasonable duration: 24 hours (86400000 ms)
      const int maxDurationMs = 24 * 60 * 60 * 1000;
      
      if (song.duration! < 0) {
        print('Excluding track with negative duration: ${song.title} (${song.duration}ms)');
        return true;
      }
      
      if (song.duration! > maxDurationMs) {
        print('Warning: Track with very long duration: ${song.title} (${song.duration}ms > ${maxDurationMs}ms)');
        // Don't exclude very long tracks, just log the warning
      }
    } else {
      print('Warning: Track with null duration: ${song.title}');
      // Don't exclude tracks with null duration, they might still be playable
    }

    // Check if title is empty or too generic
    final title = song.title.trim();
    if (title.isEmpty || 
        title.toLowerCase() == 'unknown' ||
        title.toLowerCase() == '<unknown>') {
      print('Excluding track with invalid title: "$title"');
      return true;
    }

    // Check if artist is empty or too generic
    final artist = (song.artist ?? '').trim();
    if (artist.isEmpty || 
        artist.toLowerCase() == 'unknown' ||
        artist.toLowerCase() == '<unknown>') {
      print('Warning: Track with generic artist: ${song.title} - "$artist"');
      // Don't exclude, but log the warning
    }

    return false;
  }

  // Load all tracks from device
  Future<List<Track>> loadAllTracks({bool refresh = false}) async {
    try {
      // Check if we have cached tracks and it's been less than 30 seconds since last load
      if (_allTracks.isNotEmpty && !refresh && _lastLoadTime != null) {
        final timeDiff = DateTime.now().difference(_lastLoadTime!);
        if (timeDiff.inSeconds < 30) {
          return _allTracks;
        }
      }

      print('Loading all tracks from device...');

      final List<SongModel> songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      print('Found ${songs.length} total audio files');

      // Log some statistics about durations
      final validDurations = songs
          .where((song) => song.duration != null)
          .map((song) => song.duration!)
          .toList();
      
      if (validDurations.isNotEmpty) {
        final minDuration = validDurations.reduce((a, b) => a < b ? a : b);
        final maxDuration = validDurations.reduce((a, b) => a > b ? a : b);
        final avgDuration = validDurations.reduce((a, b) => a + b) ~/ validDurations.length;
        
        print('Duration stats: Min=${minDuration}ms, Max=${maxDuration}ms, Avg=${avgDuration}ms');
        print('Very long tracks (>1 hour): ${validDurations.where((d) => d > 3600000).length}');
        
        // Log some examples of very long tracks
        final longTracks = songs
            .where((song) => song.duration != null && song.duration! > 3600000)
            .take(5)
            .toList();
        
        if (longTracks.isNotEmpty) {
          print('Sample long tracks:');
          for (var song in longTracks) {
            final minutes = (song.duration! / 60000).floor();
            print('  - ${song.title}: ${minutes} minutes');
          }
        }
      }

      // Filter out system sounds, notifications, ringtones, and short audio
      // But be more permissive with long tracks
      final filteredSongs = <SongModel>[];
      
      for (final song in songs) {
        if (!_shouldExcludeSong(song)) {
          filteredSongs.add(song);
        } else {
          print('Excluded: ${song.title} - ${song.artist}');
        }
      }

      print('Filtered to ${filteredSongs.length} music tracks (excluded ${songs.length - filteredSongs.length})');

      _allTracks = filteredSongs
          .map((song) => Track.fromSongModel(song))
          .toList();

      _lastLoadTime = DateTime.now();
      
      // Log information about the loaded tracks
      if (_allTracks.isNotEmpty) {
        final longTracks = _allTracks.where((track) => 
            track.duration != null && track.duration! > 3600000).toList();
        if (longTracks.isNotEmpty) {
          print('Loaded ${longTracks.length} tracks longer than 1 hour:');
          for (var track in longTracks.take(5)) {
            print('  - ${track.title}: ${track.duration}ms (${(track.duration! / 1000 / 60).toStringAsFixed(1)} minutes)');
          }
        }
        
        // Check for tracks with null duration that were included
        final nullDurationTracks = _allTracks.where((track) => track.duration == null).toList();
        if (nullDurationTracks.isNotEmpty) {
          print('Loaded ${nullDurationTracks.length} tracks with null duration:');
          for (var track in nullDurationTracks.take(5)) {
            print('  - ${track.title} - ${track.artist}');
          }
        }
      } else {
        print('WARNING: No tracks loaded after filtering!');
        print('This might indicate overly restrictive filtering rules.');
      }

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

  // Clear the cache timestamp to force reload
  void clearCacheTimestamp() {
    _lastLoadTime = null;
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
