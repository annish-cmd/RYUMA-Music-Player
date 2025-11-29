import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/track.dart';
import '../services/audio_handler.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  final AudioPlayerHandler audioPlayer;

  const MiniPlayer({super.key, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Track?>(
      stream: audioPlayer.currentTrackStream,
      initialData: audioPlayer.currentTrack,
      builder: (context, trackSnapshot) {
        final track = trackSnapshot.data ?? audioPlayer.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _openNowPlaying(context),
          child: Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1A2F42), const Color(0xFF0D1B2A)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress bar at top
                StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (context, posSnapshot) {
                    return StreamBuilder<Duration?>(
                      stream: audioPlayer.durationStream,
                      builder: (context, durSnapshot) {
                        final position = posSnapshot.data ?? Duration.zero;
                        final duration = durSnapshot.data ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[400]!,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Album Art
                        _buildAlbumArt(track),
                        const SizedBox(width: 12),
                        // Track Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Previous
                            IconButton(
                              onPressed: () => audioPlayer.skipToPrevious(),
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                color: Colors.grey[300],
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            // Play/Pause
                            StreamBuilder<bool>(
                              stream: audioPlayer.playingStream,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[400],
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () =>
                                        audioPlayer.togglePlayPause(),
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            // Next
                            IconButton(
                              onPressed: () => audioPlayer.skipToNext(),
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: Colors.grey[300],
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(Track track) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.albumId != null
            ? QueryArtworkWidget(
                id: track.albumId!,
                type: ArtworkType.ALBUM,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                nullArtworkWidget: _buildPlaceholder(),
                keepOldArtwork: true,
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[700]!, Colors.grey[900]!],
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.grey[500], size: 24),
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return NowPlayingScreen(audioPlayer: audioPlayer);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
