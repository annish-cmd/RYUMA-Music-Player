import 'package:on_audio_query/on_audio_query.dart';

class Track {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final int? albumId;
  final String? data; // File path
  final int? duration; // Duration in milliseconds
  final String? displayName;
  final String? composer;
  final int? dateAdded;
  final int? size;

  Track({
    required this.id,
    required this.title,
    this.artist = '<unknown>',
    this.album,
    this.albumId,
    this.data,
    this.duration,
    this.displayName,
    this.composer,
    this.dateAdded,
    this.size,
  });

  // Create Track from on_audio_query's SongModel
  factory Track.fromSongModel(SongModel song) {
    return Track(
      id: song.id,
      title: song.title,
      artist: song.artist ?? '<unknown>',
      album: song.album,
      albumId: song.albumId,
      data: song.data,
      duration: song.duration,
      displayName: song.displayNameWOExt,
      composer: song.composer,
      dateAdded: song.dateAdded,
      size: song.size,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumId': albumId,
      'data': data,
      'duration': duration,
      'displayName': displayName,
      'composer': composer,
      'dateAdded': dateAdded,
      'size': size,
    };
  }

  // Alias for JSON serialization
  Map<String, dynamic> toJson() => toMap();

  // Create Track from map
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] ?? 0,
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? '<unknown>',
      album: map['album'],
      albumId: map['albumId'],
      data: map['data'],
      duration: map['duration'],
      displayName: map['displayName'],
      composer: map['composer'],
      dateAdded: map['dateAdded'],
      size: map['size'],
    );
  }

  // Alias for JSON deserialization
  factory Track.fromJson(Map<String, dynamic> json) => Track.fromMap(json);

  // Format duration to readable string (e.g., "3:45")
  String get durationText {
    if (duration == null) return '--:--';
    final minutes = (duration! / 60000).floor();
    final seconds = ((duration! % 60000) / 1000).floor();
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get file size in readable format
  String get sizeText {
    if (size == null) return 'Unknown';
    final kb = size! / 1024;
    final mb = kb / 1024;
    if (mb >= 1) {
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      return '${kb.toStringAsFixed(2)} KB';
    }
  }

  @override
  String toString() {
    return 'Track(id: $id, title: $title, artist: $artist, album: $album)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
