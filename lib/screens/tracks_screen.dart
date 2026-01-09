import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/track.dart';
import '../widgets/track_list_item.dart';
import '../widgets/mini_player.dart';
import '../widgets/alphabet_scrollbar.dart';
import '../services/music_service.dart';
import '../services/audio_handler.dart';
import '../services/theme_service.dart';
import '../main.dart';
import 'settings_screen.dart';

class TracksScreen extends StatefulWidget {
  const TracksScreen({super.key});

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MusicService _musicService = MusicService();
  AudioPlayerHandler get _audioPlayer => audioHandler;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final ScrollController _trackListScrollController = ScrollController();
  final Map<String, double> _letterScrollOffsets = {};
  Set<String> _availableLetters = {};
  String? _currentScrollLetter;

  static const String _cachedTracksKey = 'cached_tracks_data';
  static const String _permissionKey = 'permission_granted';
  static const String _favoritesKey = 'favorites_track_ids';
  static const String _recentlyPlayedKey = 'recently_played_ids';
  static const String _playCountKey = 'track_play_counts';

  // Track data
  List<Track> _tracks = [];
  List<Track> _filteredTracks = [];
  bool _isShuffleEnabled = false;

  // Sorting
  SortOption _currentSortOption = SortOption.titleAZ;

  // Albums & Artists
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];

  // Playlists
  List<PlaylistInfo> _playlists = [];

  // Favorites, Recently Played, Play Counts
  List<int> _favoriteIds = [];
  List<int> _recentlyPlayedIds = [];
  Map<int, int> _playCountMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _trackListScrollController.addListener(_onTrackListScroll);
    _loadCachedTracksAndRefresh();
  }

  void _onTrackListScroll() {
    if (_letterScrollOffsets.isEmpty) return;

    final currentOffset = _trackListScrollController.offset;
    String? newLetter;

    final sortedLetters = _letterScrollOffsets.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = sortedLetters.length - 1; i >= 0; i--) {
      if (currentOffset >= sortedLetters[i].value - 10) {
        newLetter = sortedLetters[i].key;
        break;
      }
    }

    if (newLetter != null && newLetter != _currentScrollLetter) {
      // Use immutable update
      setState(() {
        _currentScrollLetter = newLetter;
      });
    }
  }

  Future<void> _loadCachedTracksAndRefresh() async {
    await _loadCachedTracks();
    _silentRefresh();
  }

  Future<void> _loadCachedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedTracksKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final cachedTracks = jsonList.map((e) => Track.fromJson(e)).toList();

        if (cachedTracks.isNotEmpty && mounted) {
          setState(() {
            _tracks = cachedTracks;
            _filteredTracks = cachedTracks;
            _applySorting();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached tracks: $e');
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final hasPermission = await _musicService.checkPermissionStatus();

      if (!hasPermission) {
        final granted = await _musicService.requestPermissions();
        if (!granted) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_permissionKey, granted);
      }

      // Load tracks, albums, artists in parallel
      final results = await Future.wait([
        _musicService.loadAllTracks(),
        _audioQuery.queryAlbums(
          sortType: AlbumSortType.ALBUM,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
        ),
        _audioQuery.queryArtists(
          sortType: ArtistSortType.ARTIST,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
        ),
      ]);

      final freshTracks = results[0] as List<Track>;
      final albums = results[1] as List<AlbumModel>;
      final artists = results[2] as List<ArtistModel>;

      if (mounted) {
        setState(() {
          _tracks = freshTracks;
          _filteredTracks = freshTracks;
          _albums = albums;
          _artists = artists;
          _applySorting();
        });

        if (freshTracks.isNotEmpty) {
          await _cacheTracks(freshTracks);
        }
      }

      // Load playlists and other data
      await _loadPlaylists();
      await _loadFavorites();
      await _loadRecentlyPlayed();
      await _loadPlayCounts();
    } catch (e) {
      debugPrint('Error in silent refresh: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_favoritesKey);
      if (data != null) {
        final List<dynamic> ids = json.decode(data);
        final loadedFavorites = ids.cast<int>();
        
        if (mounted) {
          setState(() {
            _favoriteIds = loadedFavorites;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, json.encode(_favoriteIds));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_recentlyPlayedKey);
      if (data != null) {
        final List<dynamic> ids = json.decode(data);
        final loadedRecentlyPlayed = ids.cast<int>();
        
        if (mounted) {
          setState(() {
            _recentlyPlayedIds = loadedRecentlyPlayed;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading recently played: $e');
    }
  }

  Future<void> _saveRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _recentlyPlayedKey,
        json.encode(_recentlyPlayedIds),
      );
    } catch (e) {
      debugPrint('Error saving recently played: $e');
    }
  }

  Future<void> _addToRecentlyPlayed(int trackId) async {
    _recentlyPlayedIds.remove(trackId);
    _recentlyPlayedIds.insert(0, trackId);
    if (_recentlyPlayedIds.length > 50) {
      _recentlyPlayedIds = _recentlyPlayedIds.sublist(0, 50);
    }
    await _saveRecentlyPlayed();
  }

  Future<void> _loadPlayCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_playCountKey);
      if (data != null) {
        final Map<String, dynamic> counts = json.decode(data);
        final loadedPlayCounts = counts.map(
          (k, v) => MapEntry(int.parse(k), v as int),
        );
        
        if (mounted) {
          setState(() {
            _playCountMap = loadedPlayCounts;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading play counts: $e');
    }
  }

  Future<void> _savePlayCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _playCountMap.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_playCountKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving play counts: $e');
    }
  }

  Future<void> _incrementPlayCount(int trackId) async {
    _playCountMap[trackId] = (_playCountMap[trackId] ?? 0) + 1;
    await _savePlayCounts();
  }

  void _toggleFavorite(int trackId) {
    // Use immutable update to trigger rebuild only when needed
    final newFavoriteIds = Set<int>.from(_favoriteIds);
    if (newFavoriteIds.contains(trackId)) {
      newFavoriteIds.remove(trackId);
    } else {
      newFavoriteIds.add(trackId);
    }
    
    setState(() {
      _favoriteIds = newFavoriteIds.toList();
    });
    
    // Save asynchronously without blocking UI
    _saveFavorites();
  }

  bool _isFavorite(int trackId) => _favoriteIds.contains(trackId);

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistData = prefs.getString('user_playlists');

      if (playlistData != null) {
        final List<dynamic> jsonList = json.decode(playlistData);
        final loadedPlaylists = jsonList.map((e) => PlaylistInfo.fromJson(e)).toList();
        
        if (mounted) {
          setState(() {
            _playlists = loadedPlaylists;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _playlists.map((p) => p.toJson()).toList();
      await prefs.setString('user_playlists', json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  Future<void> _cacheTracks(List<Track> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tracks.map((t) => t.toJson()).toList();
      await prefs.setString(_cachedTracksKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error caching tracks: $e');
    }
  }

  // Custom sort: Letters first (A-Z), then Numbers, then Symbols
  int _customTitleCompare(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;

    final charA = a[0].toLowerCase();
    final charB = b[0].toLowerCase();

    final isLetterA = RegExp(r'[a-z]').hasMatch(charA);
    final isLetterB = RegExp(r'[a-z]').hasMatch(charB);
    final isNumberA = RegExp(r'[0-9]').hasMatch(charA);
    final isNumberB = RegExp(r'[0-9]').hasMatch(charB);

    // Letters come first
    if (isLetterA && !isLetterB) return -1;
    if (!isLetterA && isLetterB) return 1;

    // Numbers come after letters
    if (isNumberA && !isNumberB && !isLetterB) return -1;
    if (!isNumberA && !isLetterA && isNumberB) return 1;

    // Same category, compare normally
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  void _applySorting() {
    List<Track> sorted = List.from(_filteredTracks);

    switch (_currentSortOption) {
      case SortOption.titleAZ:
        sorted.sort((a, b) => _customTitleCompare(a.title, b.title));
        break;
      case SortOption.titleZA:
        sorted.sort((a, b) => _customTitleCompare(b.title, a.title));
        break;
      case SortOption.dateNewest:
        sorted.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
      case SortOption.dateOldest:
        sorted.sort((a, b) => (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0));
        break;
      case SortOption.mostPlayed:
        // For now, sort by date as placeholder (can be enhanced with play count tracking)
        sorted.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
    }

    _filteredTracks = sorted;
    _buildLetterIndex();
    
    // Only update state if needed
    setState(() {});
  }

  void _buildLetterIndex() {
    _letterScrollOffsets.clear();
    _availableLetters.clear();

    if (_filteredTracks.isEmpty) return;

    const itemHeight = 70.0;
    double currentOffset = 0;
    String? lastLetter;

    for (int i = 0; i < _filteredTracks.length; i++) {
      String letter = _filteredTracks[i].title.isNotEmpty
          ? _filteredTracks[i].title[0].toUpperCase()
          : '#';

      if (!RegExp(r'[A-Z]').hasMatch(letter)) {
        letter = '#';
      }

      if (letter != lastLetter) {
        _letterScrollOffsets[letter] = currentOffset;
        _availableLetters.add(letter);
        lastLetter = letter;
      }

      currentOffset += itemHeight;
    }

    if (_currentScrollLetter == null && _availableLetters.isNotEmpty) {
      _currentScrollLetter = _availableLetters.first;
    }
  }

  void _scrollToLetter(String letter) {
    final offset = _letterScrollOffsets[letter];
    if (offset == null) return;

    final maxOffset = _trackListScrollController.hasClients
        ? _trackListScrollController.position.maxScrollExtent
        : double.infinity;

    if (_trackListScrollController.hasClients) {
      _trackListScrollController.animateTo(
        offset.clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _filterTracks(String query) {
    List<Track> filtered;
    
    if (query.isEmpty) {
      filtered = _tracks;
    } else {
      final q = query.toLowerCase();
      filtered = _tracks.where((track) {
        return track.title.toLowerCase().contains(q) ||
            track.artist.toLowerCase().contains(q) ||
            (track.album?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    
    _filteredTracks = filtered;
    _applySorting();
    
    setState(() {});
  }

  Future<void> _refreshTracks() async {
    await _silentRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackListScrollController.removeListener(_onTrackListScroll);
    _trackListScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: appTheme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: appTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTracksTab(),
                    _buildPlaylistsTab(),
                    _buildAlbumsTab(),
                    _buildArtistsTab(),
                  ],
                ),
              ),
              MiniPlayer(audioPlayer: _audioPlayer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return appTheme.getTextGradientShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: const Text(
              'RYUMA',
              style: TextStyle(
                fontFamily: 'NightMachine',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              _buildEqualizerIcon(),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: appTheme.iconSecondaryColor,
                  size: 26,
                ),
                onPressed: _showSearchDialog,
                splashRadius: 22,
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: appTheme.iconSecondaryColor,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                splashRadius: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizerIcon() {
    return StreamBuilder<bool>(
      stream: _audioPlayer.playingStream,
      initialData: false,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              final heights = [12.0, 18.0, 10.0, 16.0];
              return Container(
                width: 3,
                height: isPlaying ? heights[index] : 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? appTheme.primaryColor
                      : appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: TabBar(
        controller: _tabController,
        indicatorColor: appTheme.primaryColor,
        indicatorWeight: 2,
        labelColor: appTheme.textPrimaryColor,
        unselectedLabelColor: appTheme.textHintColor,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(text: 'TRACKS'),
          Tab(text: 'PLAYLIST'),
          Tab(text: 'ALBUMS'),
          Tab(text: 'ARTISTS'),
        ],
      ),
    );
  }

  // ==================== TRACKS TAB ====================
  Widget _buildTracksTab() {
    return Column(
      children: [
        _buildTrackControls(),
        Expanded(child: _buildTrackList()),
      ],
    );
  }

  Widget _buildTrackControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: appTheme.textSecondaryColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${_filteredTracks.length} Tracks',
                style: TextStyle(
                  color: appTheme.textSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showSortOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort,
                        color: appTheme.textSecondaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getSortLabel(),
                        style: TextStyle(
                          color: appTheme.textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isShuffleEnabled = !_isShuffleEnabled;
                  });
                  _audioPlayer.setShuffle(_isShuffleEnabled);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isShuffleEnabled
                        ? appTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shuffle,
                        color: _isShuffleEnabled
                            ? appTheme.primaryColor
                            : appTheme.textSecondaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Shuffle',
                        style: TextStyle(
                          color: _isShuffleEnabled
                              ? appTheme.primaryColor
                              : appTheme.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _playAllTracks,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: appTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: appTheme.shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    if (_filteredTracks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.library_music_outlined,
        message: 'Your music will appear here',
      );
    }

    return Stack(
      children: [
        // Main track list
        RefreshIndicator(
          onRefresh: _refreshTracks,
          color: appTheme.primaryColor,
          backgroundColor: appTheme.surfaceColor,
          child: ListView.builder(
            controller: _trackListScrollController,
            padding: const EdgeInsets.only(bottom: 20, right: 28),
            physics: const BouncingScrollPhysics(),
            itemCount: _filteredTracks.length,
            itemBuilder: (context, index) {
              final track = _filteredTracks[index];
              return StreamBuilder<Track?>(
                stream: _audioPlayer.currentTrackStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data?.id == track.id;
                  return TrackListItem(
                    track: track,
                    isPlaying: isPlaying,
                    isFavorite: _isFavorite(track.id),
                    onTap: () => _playTrack(track),
                    onFavoriteToggle: () => _toggleFavorite(track.id),
                    onAddToPlaylist: (t) => _showAddToPlaylistDialog(t),
                  );
                },
              );
            },
          ),
        ),

        // Alphabet scrollbar on the right
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: AlphabetScrollbar(
            onLetterSelected: _scrollToLetter,
            availableLetters: _availableLetters,
            currentLetter: _currentScrollLetter,
            activeColor: appTheme.primaryColor,
            inactiveColor: appTheme.textHintColor,
          ),
        ),
      ],
    );
  }

  // ==================== PLAYLISTS TAB ====================
  Widget _buildPlaylistsTab() {
    return Column(
      children: [
        _buildPlaylistHeader(),
        Expanded(child: _buildPlaylistList()),
      ],
    );
  }

  Widget _buildPlaylistHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_playlists.length + 3} Playlists',
            style: TextStyle(
              color: appTheme.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: _showCreatePlaylistDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: appTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: appTheme.primaryColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Create',
                    style: TextStyle(
                      color: appTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList() {
    // Default playlists
    final defaultPlaylists = [
      _buildDefaultPlaylistTile(
        icon: Icons.favorite,
        iconColor: appTheme.primaryColor,
        title: 'Favorites',
        subtitle: 'Your liked songs',
        onTap: () => _openFavoritesPlaylist(),
      ),
      _buildDefaultPlaylistTile(
        icon: Icons.history,
        iconColor: appTheme.accentColor,
        title: 'Recently Played',
        subtitle: 'Your listening history',
        onTap: () => _openRecentlyPlayed(),
      ),
      _buildDefaultPlaylistTile(
        icon: Icons.access_time,
        iconColor: Colors.green,
        title: 'Most Played',
        subtitle: 'Your top tracks',
        onTap: () => _openMostPlayed(),
      ),
    ];

    if (_playlists.isEmpty && defaultPlaylists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.queue_music,
        message: 'Create your first playlist',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        ...defaultPlaylists,
        if (_playlists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your Playlists',
              style: TextStyle(
                color: appTheme.textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._playlists.map((playlist) => _buildUserPlaylistTile(playlist)),
        ],
      ],
    );
  }

  Widget _buildDefaultPlaylistTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: appTheme.textPrimaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: appTheme.textSecondaryColor, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: appTheme.textHintColor,
        size: 24,
      ),
    );
  }

  Widget _buildUserPlaylistTile(PlaylistInfo playlist) {
    return ListTile(
      onTap: () => _openPlaylist(playlist),
      onLongPress: () => _showPlaylistOptions(playlist),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.primaries[playlist.name.hashCode %
                  Colors.primaries.length],
              Colors.primaries[(playlist.name.hashCode + 3) %
                  Colors.primaries.length],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.music_note,
          color: appTheme.textPrimaryColor,
          size: 24,
        ),
      ),
      title: Text(
        playlist.name,
        style: TextStyle(
          color: appTheme.textPrimaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${playlist.trackIds.length} songs',
        style: TextStyle(color: appTheme.textSecondaryColor, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: appTheme.textHintColor,
        size: 24,
      ),
    );
  }

  // ==================== ALBUMS TAB ====================
  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return _buildEmptyState(
        icon: Icons.album_outlined,
        message: 'Albums will appear here',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return _buildAlbumCard(album);
      },
    );
  }

  Widget _buildAlbumCard(AlbumModel album) {
    return GestureDetector(
      onTap: () => _openAlbum(album),
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: QueryArtworkWidget(
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    artworkFit: BoxFit.cover,
                    artworkWidth: double.infinity,
                    artworkHeight: double.infinity,
                    nullArtworkWidget: Container(
                      color: appTheme.cardColor,
                      child: Icon(
                        Icons.album,
                        size: 50,
                        color: appTheme.textHintColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appTheme.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${album.numOfSongs} songs',
                    style: TextStyle(
                      color: appTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ARTISTS TAB ====================
  Widget _buildArtistsTab() {
    if (_artists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_outline,
        message: 'Artists will appear here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured Artists - Horizontal Scroll
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Featured Artists',
            style: TextStyle(
              color: appTheme.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: _artists.length > 10 ? 10 : _artists.length,
            itemBuilder: (context, index) {
              final artist = _artists[index];
              return _buildFeaturedArtistCard(artist);
            },
          ),
        ),
        const SizedBox(height: 16),
        // All Artists header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Artists',
                style: TextStyle(
                  color: appTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_artists.length} artists',
                style: TextStyle(
                  color: appTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Artists List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _artists.length,
            itemBuilder: (context, index) {
              final artist = _artists[index];
              return _buildArtistListTile(artist);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedArtistCard(ArtistModel artist) {
    return GestureDetector(
      onTap: () => _openArtist(artist),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.primaries[artist.artist.hashCode %
                        Colors.primaries.length],
                    Colors.primaries[(artist.artist.hashCode + 5) %
                        Colors.primaries.length],
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: QueryArtworkWidget(
                  id: artist.id,
                  type: ArtworkType.ARTIST,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Center(
                    child: Text(
                      artist.artist.isNotEmpty
                          ? artist.artist[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: appTheme.textPrimaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.artist,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: appTheme.textPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistListTile(ArtistModel artist) {
    return ListTile(
      onTap: () => _openArtist(artist),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.primaries[artist.artist.hashCode %
                  Colors.primaries.length],
              Colors.primaries[(artist.artist.hashCode + 5) %
                  Colors.primaries.length],
            ],
          ),
        ),
        child: Center(
          child: Text(
            artist.artist.isNotEmpty ? artist.artist[0].toUpperCase() : '?',
            style: TextStyle(
              color: appTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        artist.artist,
        style: TextStyle(
          color: appTheme.textPrimaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${artist.numberOfTracks} songs',
        style: TextStyle(color: appTheme.textSecondaryColor, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: appTheme.textHintColor,
        size: 24,
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: appTheme.textHintColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: appTheme.textSecondaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_currentSortOption) {
      case SortOption.titleAZ:
        return 'A-Z';
      case SortOption.titleZA:
        return 'Z-A';
      case SortOption.dateNewest:
        return 'Newest';
      case SortOption.dateOldest:
        return 'Oldest';
      case SortOption.mostPlayed:
        return 'Most Played';
    }
  }

  // ==================== DIALOGS ====================
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.surfaceColor,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort By',
                style: TextStyle(
                  color: appTheme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOption(
                SortOption.titleAZ,
                'Title (A-Z)',
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                SortOption.titleZA,
                'Title (Z-A)',
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                SortOption.dateNewest,
                'Newest First',
                Icons.schedule,
              ),
              _buildSortOption(
                SortOption.dateOldest,
                'Oldest First',
                Icons.history,
              ),
              _buildSortOption(
                SortOption.mostPlayed,
                'Most Played',
                Icons.trending_up,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(SortOption option, String label, IconData icon) {
    final isSelected = _currentSortOption == option;
    return ListTile(
      onTap: () {
        setState(() {
          _currentSortOption = option;
          _applySorting();
        });
        Navigator.pop(context);
      },
      leading: Icon(
        icon,
        color: isSelected ? appTheme.primaryColor : appTheme.textSecondaryColor,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? appTheme.primaryColor : appTheme.textPrimaryColor,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: appTheme.primaryColor, size: 22)
          : null,
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: appTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: appTheme.textHintColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  autofocus: true,
                  style: TextStyle(
                    color: appTheme.textPrimaryColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tracks, artists, albums...',
                    hintStyle: TextStyle(color: appTheme.textSecondaryColor),
                    prefixIcon: Icon(
                      Icons.search,
                      color: appTheme.textSecondaryColor,
                    ),
                    filled: true,
                    fillColor: appTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterTracks,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _filterTracks('');
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: appTheme.textSecondaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Done',
                        style: TextStyle(color: appTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog({Track? initialTrack}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Create Playlist',
          style: TextStyle(color: appTheme.textPrimaryColor),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: appTheme.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: appTheme.textSecondaryColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.textHintColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: appTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newPlaylist = PlaylistInfo(
                  name: controller.text.trim(),
                  trackIds: initialTrack != null ? [initialTrack.id] : [],
                  createdAt: DateTime.now(),
                );
                // Use immutable update for playlists
                final newPlaylists = List<PlaylistInfo>.from(_playlists);
                newPlaylists.add(newPlaylist);
                
                setState(() {
                  _playlists = newPlaylists;
                });
                
                // Save asynchronously to not block UI
                _savePlaylists();
                Navigator.pop(context);
                if (initialTrack != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to "${newPlaylist.name}"'),
                      backgroundColor: appTheme.surfaceColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Create',
              style: TextStyle(color: appTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.textHintColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to Playlist',
              style: TextStyle(
                color: appTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Create new playlist option
            ListTile(
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.redAccent, size: 24),
              ),
              title: const Text(
                'Create New Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(initialTrack: track);
              },
            ),
            if (_playlists.isNotEmpty) ...[
              Divider(
                color: appTheme.textHintColor.withValues(alpha: 0.3),
                height: 1,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final alreadyAdded = playlist.trackIds.contains(track.id);
                    return ListTile(
                      leading: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.primaries[playlist.name.hashCode %
                                  Colors.primaries.length],
                              Colors.primaries[(playlist.name.hashCode + 3) %
                                  Colors.primaries.length],
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: appTheme.textPrimaryColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          color: appTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.trackIds.length} songs',
                        style: TextStyle(
                          color: appTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      trailing: alreadyAdded
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 22,
                            )
                          : null,
                      onTap: () {
                        if (!alreadyAdded) {
                          // Create new playlist with updated trackIds
                          final updatedPlaylist = PlaylistInfo(
                            name: playlist.name,
                            trackIds: [...playlist.trackIds, track.id],
                            createdAt: playlist.createdAt,
                          );
                                                  
                          // Use immutable update for playlists
                          final newPlaylists = List<PlaylistInfo>.from(_playlists);
                          newPlaylists[index] = updatedPlaylist;
                                                  
                          setState(() {
                            _playlists = newPlaylists;
                          });
                                                  
                          // Save asynchronously to not block UI
                          _savePlaylists();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to "${playlist.name}"'),
                              backgroundColor: appTheme.surfaceColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Already in "${playlist.name}"'),
                              backgroundColor: appTheme.surfaceColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPlaylistOptions(PlaylistInfo playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.textHintColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: appTheme.iconColor),
              title: Text(
                'Rename',
                style: TextStyle(color: appTheme.textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRenamePlaylistDialog(playlist);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: appTheme.primaryColor),
              title: Text(
                'Delete',
                style: TextStyle(color: appTheme.primaryColor),
              ),
              onTap: () {
                // Use immutable update for playlists
                final newPlaylists = List<PlaylistInfo>.from(_playlists);
                newPlaylists.remove(playlist);
                            
                setState(() {
                  _playlists = newPlaylists;
                });
                            
                // Save asynchronously to not block UI
                _savePlaylists();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRenamePlaylistDialog(PlaylistInfo playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Playlist',
          style: TextStyle(color: appTheme.textPrimaryColor),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: appTheme.textPrimaryColor),
          decoration: InputDecoration(
            hintStyle: TextStyle(color: appTheme.textSecondaryColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.textHintColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: appTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final index = _playlists.indexOf(playlist);
                if (index != -1) {
                  // Create updated playlist
                  final updatedPlaylist = PlaylistInfo(
                    name: controller.text.trim(),
                    trackIds: playlist.trackIds,
                    createdAt: playlist.createdAt,
                  );
                  
                  // Use immutable update for playlists
                  final newPlaylists = List<PlaylistInfo>.from(_playlists);
                  newPlaylists[index] = updatedPlaylist;
                  
                  setState(() {
                    _playlists = newPlaylists;
                  });
                  
                  // Save asynchronously to not block UI
                  _savePlaylists();
                }
                Navigator.pop(context);
              }
            },
            child: Text(
              'Rename',
              style: TextStyle(color: appTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAVIGATION ====================
  void _openAlbum(AlbumModel album) async {
    final tracks = await _musicService.getTracksByAlbum(album.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: appTheme.surfaceColor,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: QueryArtworkWidget(
                          id: album.id,
                          type: ArtworkType.ALBUM,
                          nullArtworkWidget: Icon(
                            Icons.album,
                            size: 40,
                            color: appTheme.textHintColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.album,
                            style: TextStyle(
                              color: appTheme.textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${album.numOfSongs} songs',
                            style: TextStyle(
                              color: appTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.play_circle_fill,
                        color: appTheme.primaryColor,
                        size: 48,
                      ),
                      onPressed: () async {
                        if (tracks.isNotEmpty) {
                          await _audioPlayer.setPlaylist(tracks);
                          await _audioPlayer.play();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return TrackListItem(
                      track: track,
                      isPlaying: false,
                      onTap: () async {
                        await _audioPlayer.setPlaylist(tracks);
                        await _audioPlayer.playTrack(track);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openArtist(ArtistModel artist) async {
    // First try to get tracks from the service
    List<Track> tracks = await _musicService.getTracksByArtist(artist.id);

    // If empty, filter from local tracks by artist name
    if (tracks.isEmpty) {
      tracks = _tracks
          .where((t) => t.artist.toLowerCase() == artist.artist.toLowerCase())
          .toList();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.primaries[artist.artist.hashCode %
                                Colors.primaries.length],
                            Colors.primaries[(artist.artist.hashCode + 5) %
                                Colors.primaries.length],
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          artist.artist.isNotEmpty
                              ? artist.artist[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            artist.artist,
                            style: TextStyle(
                              color: appTheme.textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${artist.numberOfTracks} songs',
                            style: TextStyle(
                              color: appTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.play_circle_fill,
                        color: appTheme.primaryColor,
                        size: 48,
                      ),
                      onPressed: () async {
                        if (tracks.isNotEmpty) {
                          await _audioPlayer.setPlaylist(tracks);
                          await _audioPlayer.play();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return TrackListItem(
                      track: track,
                      isPlaying: false,
                      onTap: () async {
                        await _audioPlayer.setPlaylist(tracks);
                        await _audioPlayer.playTrack(track);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaylist(PlaylistInfo playlist) async {
    final playlistTracks = _tracks
        .where((t) => playlist.trackIds.contains(t.id))
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.primaries[playlist.name.hashCode %
                                Colors.primaries.length],
                            Colors.primaries[(playlist.name.hashCode + 3) %
                                Colors.primaries.length],
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: appTheme.textPrimaryColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            playlist.name,
                            style: TextStyle(
                              color: appTheme.textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${playlistTracks.length} songs',
                            style: TextStyle(
                              color: appTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (playlistTracks.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: appTheme.primaryColor,
                          size: 48,
                        ),
                        onPressed: () async {
                          await _audioPlayer.setPlaylist(playlistTracks);
                          await _audioPlayer.play();
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: playlistTracks.isEmpty
                    ? Center(
                        child: Text(
                          'No songs in this playlist',
                          style: TextStyle(color: appTheme.textSecondaryColor),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: playlistTracks.length,
                        itemBuilder: (context, index) {
                          final track = playlistTracks[index];
                          return TrackListItem(
                            track: track,
                            isPlaying: false,
                            onTap: () async {
                              await _audioPlayer.setPlaylist(playlistTracks);
                              await _audioPlayer.playTrack(track);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFavoritesPlaylist() {
    final favTracks = _tracks
        .where((t) => _favoriteIds.contains(t.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A1929),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: appTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: appTheme.primaryColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Favorites',
                            style: TextStyle(
                              color: appTheme.textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${favTracks.length} songs',
                            style: TextStyle(
                              color: appTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (favTracks.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: appTheme.primaryColor,
                          size: 48,
                        ),
                        onPressed: () async {
                          await _audioPlayer.setPlaylist(favTracks);
                          await _audioPlayer.play();
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: favTracks.isEmpty
                    ? Center(
                        child: Text(
                          'No favorite songs yet',
                          style: TextStyle(color: appTheme.textSecondaryColor),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: favTracks.length,
                        itemBuilder: (context, index) {
                          final track = favTracks[index];
                          return TrackListItem(
                            track: track,
                            isPlaying: false,
                            isFavorite: true,
                            onTap: () async {
                              await _audioPlayer.setPlaylist(favTracks);
                              await _audioPlayer.playTrack(track);
                            },
                            onFavoriteToggle: () {
                              // Use immutable update for favorites
                              final newFavoriteIds = Set<int>.from(_favoriteIds);
                              newFavoriteIds.remove(track.id);
                                                        
                              setState(() {
                                _favoriteIds = newFavoriteIds.toList();
                              });
                                                        
                              // Save asynchronously to not block UI
                              _saveFavorites();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecentlyPlayed() {
    final recentTracks = _recentlyPlayedIds
        .map(
          (id) => _tracks.firstWhere(
            (t) => t.id == id,
            orElse: () => _tracks.first,
          ),
        )
        .where((t) => _tracks.contains(t))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.textHintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: appTheme.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.history,
                        color: appTheme.accentColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Recently Played',
                            style: TextStyle(
                              color: appTheme.textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${recentTracks.length} songs',
                            style: TextStyle(
                              color: appTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recentTracks.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: appTheme.primaryColor,
                          size: 48,
                        ),
                        onPressed: () async {
                          await _audioPlayer.setPlaylist(recentTracks);
                          await _audioPlayer.play();
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: recentTracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 60,
                              color: appTheme.textHintColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No history yet',
                              style: TextStyle(
                                color: appTheme.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Songs you play will appear here',
                              style: TextStyle(
                                color: appTheme.textHintColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: recentTracks.length,
                        itemBuilder: (context, index) {
                          final track = recentTracks[index];
                          return TrackListItem(
                            track: track,
                            isPlaying: false,
                            onTap: () async {
                              await _audioPlayer.setPlaylist(recentTracks);
                              await _audioPlayer.playTrack(track);
                              _addToRecentlyPlayed(track.id);
                              _incrementPlayCount(track.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMostPlayed() {
    final sortedByPlayCount =
        _tracks.where((t) => (_playCountMap[t.id] ?? 0) > 0).toList()..sort(
          (a, b) =>
              (_playCountMap[b.id] ?? 0).compareTo(_playCountMap[a.id] ?? 0),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A1929),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Most Played',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${sortedByPlayCount.length} songs',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sortedByPlayCount.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        onPressed: () async {
                          await _audioPlayer.setPlaylist(sortedByPlayCount);
                          await _audioPlayer.play();
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: sortedByPlayCount.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 60,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No play history yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your top tracks will appear here',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: sortedByPlayCount.length,
                        itemBuilder: (context, index) {
                          final track = sortedByPlayCount[index];
                          final playCount = _playCountMap[track.id] ?? 0;
                          return ListTile(
                            onTap: () async {
                              await _audioPlayer.setPlaylist(sortedByPlayCount);
                              await _audioPlayer.playTrack(track);
                              _addToRecentlyPlayed(track.id);
                              _incrementPlayCount(track.id);
                            },
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: index < 3
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : const Color(0xFF1A2F42),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: index < 3
                                    ? Icon(
                                        Icons.emoji_events,
                                        color: index == 0
                                            ? Colors.amber
                                            : index == 1
                                            ? Colors.grey[400]
                                            : Colors.orange[300],
                                        size: 24,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${track.artist} • $playCount plays',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                _isFavorite(track.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite(track.id)
                                    ? Colors.red
                                    : Colors.grey[600],
                                size: 22,
                              ),
                              onPressed: () => _toggleFavorite(track.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PLAYBACK ====================
  Future<void> _playTrack(Track track) async {
    try {
      if (_audioPlayer.playlist.isEmpty ||
          _audioPlayer.playlist.first.id != _filteredTracks.first.id) {
        await _audioPlayer.setPlaylist(_filteredTracks);
      }
      await _audioPlayer.playTrack(track);

      // Track play history
      _addToRecentlyPlayed(track.id);
      _incrementPlayCount(track.id);
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  Future<void> _playAllTracks() async {
    if (_filteredTracks.isEmpty) return;
    try {
      await _audioPlayer.setPlaylist(_filteredTracks, initialIndex: 0);
      if (_isShuffleEnabled) {
        _audioPlayer.setShuffle(true);
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing all tracks: $e');
    }
  }
}

// ==================== ENUMS & MODELS ====================
enum SortOption { titleAZ, titleZA, dateNewest, dateOldest, mostPlayed }

class PlaylistInfo {
  final String name;
  final List<int> trackIds;
  final DateTime createdAt;

  PlaylistInfo({
    required this.name,
    required this.trackIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'trackIds': trackIds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) => PlaylistInfo(
    name: json['name'] ?? '',
    trackIds: List<int>.from(json['trackIds'] ?? []),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}
