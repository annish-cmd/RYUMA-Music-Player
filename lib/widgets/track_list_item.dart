import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/track.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final Function(Track)? onAddToPlaylist;
  final VoidCallback? onAddToQueue;

  const TrackListItem({
    super.key,
    required this.track,
    this.onTap,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onAddToPlaylist,
    this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () => _showOptionsMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Album Art
            _buildAlbumArt(),
            const SizedBox(width: 14),
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isPlaying ? const Color(0xFFBB86FC) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_box_outline_blank,
                        color: Colors.grey[600],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${track.artist} | ${track.album ?? "Unknown album"}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // More options button only
            GestureDetector(
              onTap: () => _showOptionsMenu(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_vert, color: Colors.grey[600], size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: track.albumId != null
            ? QueryArtworkWidget(
                id: track.albumId!,
                type: ArtworkType.ALBUM,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                nullArtworkWidget: _buildPlaceholder(),
                keepOldArtwork: true,
                artworkQuality: FilterQuality.low,
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[800]!, Colors.grey[900]!],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note, color: Colors.grey[600], size: 24),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
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
              // Track header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildAlbumArt(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[800], height: 1),
              // Options
              _buildOption(context, Icons.play_arrow_rounded, 'Play', () {
                Navigator.pop(context);
                onTap?.call();
              }),
              _buildOption(
                context,
                isFavorite ? Icons.favorite : Icons.favorite_border,
                isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                () {
                  Navigator.pop(context);
                  onFavoriteToggle?.call();
                },
                iconColor: isFavorite ? Colors.red : null,
              ),
              _buildOption(context, Icons.playlist_add, 'Add to Playlist', () {
                Navigator.pop(context);
                onAddToPlaylist?.call(track);
              }),
              if (onAddToQueue != null)
                _buildOption(context, Icons.queue_music, 'Add to Queue', () {
                  Navigator.pop(context);
                  onAddToQueue?.call();
                }),
              _buildOption(context, Icons.info_outline, 'Track Info', () {
                Navigator.pop(context);
                _showTrackInfo(context);
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.grey[300], size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackInfo(BuildContext context) {
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
                if (track.duration != null)
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
                style: TextStyle(color: Color(0xFFBB86FC)),
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
}
