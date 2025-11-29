import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/track.dart';
import '../services/audio_handler.dart';
import '../services/theme_service.dart';

class NowPlayingScreen extends StatefulWidget {
  final AudioPlayerHandler audioPlayer;

  const NowPlayingScreen({super.key, required this.audioPlayer});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isDragging = false;
  double _dragValue = 0;

  // Favorites
  List<int> _favoriteIds = [];
  static const String _favoritesKey = 'favorites_track_ids';

  // Playlists
  List<PlaylistInfo> _playlists = [];
  static const String _playlistsKey = 'user_playlists';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    // Start rotation if playing
    widget.audioPlayer.playingStream.listen((isPlaying) {
      if (mounted) {
        if (isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });

    // Check initial state
    if (widget.audioPlayer.isPlaying) {
      _rotationController.repeat();
    }

    _loadFavorites();
    _loadPlaylists();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_favoritesKey);
      if (data != null) {
        final List<dynamic> ids = json.decode(data);
        if (mounted) {
          setState(() {
            _favoriteIds = ids.cast<int>();
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

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_playlistsKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        if (mounted) {
          setState(() {
            _playlists = jsonList.map((e) => PlaylistInfo.fromJson(e)).toList();
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
      await prefs.setString(_playlistsKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  bool _isFavorite(int trackId) => _favoriteIds.contains(trackId);

  void _toggleFavorite(int trackId) {
    setState(() {
      if (_favoriteIds.contains(trackId)) {
        _favoriteIds.remove(trackId);
        _showSnackBar('Removed from Favorites');
      } else {
        _favoriteIds.add(trackId);
        _showSnackBar('Added to Favorites');
      }
    });
    _saveFavorites();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A2F42),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: appTheme.screenGradient,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: StreamBuilder<Track?>(
              stream: widget.audioPlayer.currentTrackStream,
              initialData: widget.audioPlayer.currentTrack,
              builder: (context, snapshot) {
                final track = snapshot.data ?? widget.audioPlayer.currentTrack;
                if (track == null) {
                  return Center(
                    child: Text(
                      'No track playing',
                      style: TextStyle(color: appTheme.textPrimaryColor),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildHeader(context, track),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildAlbumArt(track),
                              const SizedBox(height: 32),
                              _buildTrackInfo(track),
                              const SizedBox(height: 24),
                              _buildProgressBar(),
                              const SizedBox(height: 24),
                              _buildMainControls(),
                              const SizedBox(height: 24),
                              _buildSecondaryControls(track),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: appTheme.iconColor,
          ),
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: appTheme.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                track.album ?? 'Unknown Album',
                style: TextStyle(
                  color: appTheme.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showOptionsMenu(context, track),
            icon: const Icon(Icons.more_vert_rounded, size: 24),
            color: appTheme.iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Track track) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: appTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [appTheme.cardColor, appTheme.surfaceColor],
                ),
              ),
            ),
            // Album art
            Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: track.albumId != null
                    ? QueryArtworkWidget(
                        id: track.albumId!,
                        type: ArtworkType.ALBUM,
                        artworkFit: BoxFit.cover,
                        artworkBorder: BorderRadius.zero,
                        nullArtworkWidget: _buildArtPlaceholder(),
                        keepOldArtwork: true,
                      )
                    : _buildArtPlaceholder(),
              ),
            ),
            // Center hole
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appTheme.backgroundColor,
                border: Border.all(color: appTheme.textHintColor, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [appTheme.surfaceColor, appTheme.cardColor],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note, color: appTheme.textHintColor, size: 80),
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return Column(
      children: [
        Text(
          track.title,
          style: TextStyle(
            color: appTheme.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          track.artist,
          style: TextStyle(
            color: appTheme.textSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: widget.audioPlayer.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: widget.audioPlayer.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? (_isDragging ? _dragValue : position.inMilliseconds) /
                      duration.inMilliseconds
                : 0.0;

            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: appTheme.progressColor,
                    inactiveTrackColor: appTheme.textHintColor,
                    thumbColor: Colors.white,
                    overlayColor: appTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = value * duration.inMilliseconds;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _isDragging = false;
                      });
                      widget.audioPlayer.seek(
                        Duration(
                          milliseconds: (value * duration.inMilliseconds)
                              .round(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(
                          _isDragging
                              ? Duration(milliseconds: _dragValue.round())
                              : position,
                        ),
                        style: TextStyle(
                          color: appTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: appTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        StreamBuilder<bool>(
          stream: widget.audioPlayer.isShuffleStream,
          builder: (context, snapshot) {
            final isShuffling = snapshot.data ?? false;
            return IconButton(
              onPressed: () => widget.audioPlayer.toggleShuffle(),
              icon: Icon(
                Icons.shuffle_rounded,
                color: isShuffling
                    ? appTheme.primaryColor
                    : appTheme.textHintColor,
                size: 24,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        // Previous
        IconButton(
          onPressed: () => widget.audioPlayer.skipToPrevious(),
          icon: Icon(
            Icons.skip_previous_rounded,
            color: appTheme.iconColor,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        // Play/Pause
        StreamBuilder<bool>(
          stream: widget.audioPlayer.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return GestureDetector(
              onTap: () => widget.audioPlayer.togglePlayPause(),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: appTheme.primaryGradient),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        // Next
        IconButton(
          onPressed: () => widget.audioPlayer.skipToNext(),
          icon: Icon(
            Icons.skip_next_rounded,
            color: appTheme.iconColor,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        // Repeat
        StreamBuilder<LoopMode>(
          stream: widget.audioPlayer.loopModeStream,
          builder: (context, snapshot) {
            final loopMode = snapshot.data ?? LoopMode.off;
            IconData icon;
            Color color;
            switch (loopMode) {
              case LoopMode.off:
                icon = Icons.repeat_rounded;
                color = appTheme.textHintColor;
                break;
              case LoopMode.all:
                icon = Icons.repeat_rounded;
                color = appTheme.primaryColor;
                break;
              case LoopMode.one:
                icon = Icons.repeat_one_rounded;
                color = appTheme.primaryColor;
                break;
            }
            return IconButton(
              onPressed: () => widget.audioPlayer.toggleRepeatMode(),
              icon: Icon(icon, color: color, size: 24),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(Track track) {
    final isFav = _isFavorite(track.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: appTheme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSecondaryButton(
            icon: isFav
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: isFav ? 'Liked' : 'Like',
            isActive: isFav,
            onTap: () => _toggleFavorite(track.id),
          ),
          _buildSecondaryButton(
            icon: Icons.playlist_add_rounded,
            label: 'Add to',
            onTap: () => _showAddToPlaylistDialog(track),
          ),
          _buildSecondaryButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () => _shareTrack(track),
          ),
          _buildSecondaryButton(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: () => _showQueue(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? appTheme.primaryColor
                : appTheme.iconSecondaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? appTheme.primaryColor
                  : appTheme.textSecondaryColor,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
  }

  void _shareTrack(Track track) {
    final shareText = '🎵 Now listening to:\n${track.title} by ${track.artist}';
    Share.share(shareText, subject: 'Check out this song!');
  }

  void _showAddToPlaylistDialog(Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add to Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Create new playlist
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
                _showCreatePlaylistDialog(track);
              },
            ),
            if (_playlists.isNotEmpty) ...[
              Divider(color: Colors.grey[800], height: 1),
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
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.trackIds.length} songs',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                          setState(() {
                            _playlists[index] = PlaylistInfo(
                              name: playlist.name,
                              trackIds: [...playlist.trackIds, track.id],
                              createdAt: playlist.createdAt,
                            );
                          });
                          _savePlaylists();
                          Navigator.pop(context);
                          _showSnackBar('Added to "${playlist.name}"');
                        } else {
                          Navigator.pop(context);
                          _showSnackBar('Already in "${playlist.name}"');
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

  void _showCreatePlaylistDialog(Track track) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Create Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newPlaylist = PlaylistInfo(
                  name: controller.text.trim(),
                  trackIds: [track.id],
                  createdAt: DateTime.now(),
                );
                setState(() {
                  _playlists.add(newPlaylist);
                });
                _savePlaylists();
                Navigator.pop(context);
                _showSnackBar('Added to "${newPlaylist.name}"');
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.grey[300]),
                title: const Text(
                  'Track Info',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTrackInfo(context, track);
                },
              ),
              ListTile(
                leading: Icon(Icons.timer_outlined, color: Colors.grey[300]),
                title: const Text(
                  'Sleep Timer',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.equalizer, color: Colors.grey[300]),
                title: const Text(
                  'Equalizer',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Equalizer coming soon!');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sleep Timer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimerOption('15 minutes', 15),
            _buildTimerOption('30 minutes', 30),
            _buildTimerOption('45 minutes', 45),
            _buildTimerOption('1 hour', 60),
            _buildTimerOption('End of track', -1),
            ListTile(
              leading: Icon(Icons.close, color: Colors.grey[400]),
              title: Text(
                'Cancel timer',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Sleep timer cancelled');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerOption(String label, int minutes) {
    return ListTile(
      leading: Icon(Icons.timer, color: Colors.grey[300]),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _showSnackBar('Sleep timer set for $label');
        // TODO: Implement actual sleep timer functionality
      },
    );
  }

  void _showTrackInfo(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2F42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Track Information',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Title', track.title),
                _buildInfoRow('Artist', track.artist),
                if (track.album != null) _buildInfoRow('Album', track.album!),
                _buildInfoRow('Duration', track.durationText),
                if (track.size != null) _buildInfoRow('Size', track.sizeText),
                if (track.displayName != null)
                  _buildInfoRow('File', track.displayName!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
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
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Queue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.audioPlayer.playlist.length} tracks',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey[800], height: 1),
                Expanded(
                  child: widget.audioPlayer.playlist.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.queue_music,
                                size: 60,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Queue is empty',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: widget.audioPlayer.playlist.length,
                          itemBuilder: (context, index) {
                            final track = widget.audioPlayer.playlist[index];
                            final isCurrentTrack =
                                index == widget.audioPlayer.currentIndex;
                            return ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: isCurrentTrack
                                      ? Colors.redAccent.withValues(alpha: 0.2)
                                      : const Color(0xFF0D1F30),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: track.albumId != null
                                      ? QueryArtworkWidget(
                                          id: track.albumId!,
                                          type: ArtworkType.ALBUM,
                                          artworkFit: BoxFit.cover,
                                          artworkBorder: BorderRadius.zero,
                                          nullArtworkWidget: Icon(
                                            Icons.music_note,
                                            color: Colors.grey[600],
                                          ),
                                        )
                                      : Icon(
                                          Icons.music_note,
                                          color: Colors.grey[600],
                                        ),
                                ),
                              ),
                              title: Text(
                                track.title,
                                style: TextStyle(
                                  color: isCurrentTrack
                                      ? Colors.redAccent
                                      : Colors.white,
                                  fontWeight: isCurrentTrack
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artist,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isCurrentTrack
                                  ? const Icon(
                                      Icons.graphic_eq,
                                      color: Colors.redAccent,
                                      size: 20,
                                    )
                                  : Text(
                                      track.durationText,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                              onTap: () {
                                widget.audioPlayer.playTrackAt(index);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// PlaylistInfo model for playlist management
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
