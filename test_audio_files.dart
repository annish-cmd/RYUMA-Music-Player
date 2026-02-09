import 'package:on_audio_query/on_audio_query.dart';

void main() async {
  print('Testing audio file query...');
  
  final OnAudioQuery audioQuery = OnAudioQuery();
  
  try {
    // Check if we have permission
    final bool hasPermission = await audioQuery.permissionsStatus();
    print('Permission status: $hasPermission');
    
    if (!hasPermission) {
      print('Requesting permission...');
      final bool permissionGranted = await audioQuery.permissionsRequest();
      print('Permission granted: $permissionGranted');
      if (!permissionGranted) {
        print('Permission denied. Cannot proceed.');
        return;
      }
    }
    
    print('Querying songs...');
    final List<SongModel> songs = await audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    
    print('Found ${songs.length} total audio files');
    
    // Filter and analyze durations
    final validDurations = songs
        .where((song) => song.duration != null)
        .map((song) => song.duration!)
        .toList();
    
    if (validDurations.isNotEmpty) {
      final minDuration = validDurations.reduce((a, b) => a < b ? a : b);
      final maxDuration = validDurations.reduce((a, b) => a > b ? a : b);
      final avgDuration = validDurations.reduce((a, b) => a + b) ~/ validDurations.length;
      
      print('Duration stats:');
      print('  Min: ${minDuration}ms (${(minDuration / 1000 / 60).toStringAsFixed(2)} minutes)');
      print('  Max: ${maxDuration}ms (${(maxDuration / 1000 / 60).toStringAsFixed(2)} minutes)');
      print('  Avg: ${avgDuration}ms (${(avgDuration / 1000 / 60).toStringAsFixed(2)} minutes)');
      
      // Count files by duration ranges
      final shortFiles = validDurations.where((d) => d < 30000).length; // < 30 seconds
      final mediumFiles = validDurations.where((d) => d >= 30000 && d < 3600000).length; // 30 sec to 1 hour
      final longFiles = validDurations.where((d) => d >= 3600000).length; // >= 1 hour
      
      print('File counts by duration:');
      print('  Short (< 30 sec): $shortFiles');
      print('  Medium (30 sec - 1 hour): $mediumFiles');
      print('  Long (>= 1 hour): $longFiles');
      
      // Show some long files
      if (longFiles > 0) {
        print('\nLong files (>= 1 hour):');
        final longSongs = songs
            .where((song) => song.duration != null && song.duration! >= 3600000)
            .toList();
        
        for (var i = 0; i < longSongs.length && i < 10; i++) {
          final song = longSongs[i];
          final durationMin = (song.duration! / 1000 / 60).toStringAsFixed(1);
          print('  ${i + 1}. ${song.title} - ${song.artist} (${durationMin} minutes)');
        }
      }
    }
    
    // Check for files with null duration
    final nullDurationCount = songs.where((song) => song.duration == null).length;
    print('Files with null duration: $nullDurationCount');
    
    if (nullDurationCount > 0) {
      print('Some files with null duration:');
      final nullDurationSongs = songs.where((song) => song.duration == null).take(5).toList();
      for (var song in nullDurationSongs) {
        print('  - ${song.title} - ${song.artist}');
      }
    }
    
  } catch (e) {
    print('Error: $e');
  }
}