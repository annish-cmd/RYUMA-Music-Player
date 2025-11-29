# 🎵 Phoenix Music Player - Implementation Guide

## 📋 Overview

Phoenix Music Player is a fully functional music player application for Android that loads and plays music files directly from device storage. The app features a modern dark-themed UI and comprehensive audio playback capabilities.

## ✅ Implemented Features

### 1. **Device Music Loading**
- ✅ Scans and loads all audio files from device storage
- ✅ Reads music metadata (title, artist, album, duration)
- ✅ Displays album artwork from device
- ✅ Supports all common audio formats (MP3, WAV, AAC, FLAC, etc.)
- ✅ Real-time permission handling for storage access

### 2. **Music Playback**
- ✅ Full audio playback with just_audio player
- ✅ Play/Pause functionality
- ✅ Skip to next/previous track
- ✅ Seek to any position in track
- ✅ Volume control
- ✅ Background audio playback support
- ✅ Audio focus handling

### 3. **Playlist Management**
- ✅ Dynamic playlist creation
- ✅ Shuffle mode
- ✅ Repeat modes (Off, All, One)
- ✅ Queue management
- ✅ Add/remove tracks from playlist

### 4. **User Interface**
- ✅ Professional dark theme design
- ✅ Track list with album art
- ✅ Search functionality
- ✅ Pull-to-refresh for track list
- ✅ Track details dialog
- ✅ Options menu for each track
- ✅ Loading, empty, and error states
- ✅ Visual indication of currently playing track

### 5. **Permissions**
- ✅ Runtime permission requests
- ✅ Android 13+ (API 33) READ_MEDIA_AUDIO support
- ✅ Android 12 and below storage permission support
- ✅ Graceful permission denial handling
- ✅ Direct to settings option

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── track.dart                     # Track data model
├── services/
│   ├── music_service.dart             # Device music loading
│   └── audio_player_service.dart      # Audio playback management
├── screens/
│   └── tracks_screen.dart             # Main UI screen
└── widgets/
    └── track_list_item.dart           # Track list item widget
```

### Core Components

#### 1. **MusicService** (`lib/services/music_service.dart`)
Handles all music file operations:
- Requests storage permissions
- Scans device for audio files
- Loads track metadata
- Provides search functionality
- Manages album and artist data

**Key Methods:**
```dart
Future<bool> initialize()                    // Initialize service
Future<bool> requestPermissions()            // Request storage access
Future<List<Track>> loadAllTracks()          // Load all music files
List<Track> searchTracks(String query)       // Search tracks
Future<List<AlbumModel>> getAlbums()         // Get all albums
Future<List<ArtistModel>> getArtists()       // Get all artists
```

#### 2. **AudioPlayerService** (`lib/services/audio_player_service.dart`)
Manages audio playback:
- Audio player lifecycle
- Playlist management
- Playback controls
- State management with streams

**Key Methods:**
```dart
Future<void> initialize()                    // Initialize player
Future<void> setPlaylist(List<Track>)        // Set playlist
Future<void> play()                          // Play current track
Future<void> pause()                         // Pause playback
Future<void> skipToNext()                    // Next track
Future<void> skipToPrevious()                // Previous track
Future<void> seek(Duration position)         // Seek to position
Future<void> toggleShuffle()                 // Toggle shuffle mode
```

**Streams:**
```dart
Stream<Track?> currentTrackStream            // Current playing track
Stream<bool> isPlayingStream                 // Playing state
Stream<Duration> positionStream              // Current position
Stream<Duration?> durationStream             // Track duration
Stream<PlayerState> playerStateStream        // Player state
```

#### 3. **Track Model** (`lib/models/track.dart`)
Data model for music tracks:
```dart
class Track {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final int? albumId;
  final String? data;          // File path
  final int? duration;         // Milliseconds
  final String? displayName;
  final String? composer;
  final int? dateAdded;
  final int? size;
}
```

#### 4. **TracksScreen** (`lib/screens/tracks_screen.dart`)
Main UI screen with:
- Tab navigation (Tracks, Albums, Artists)
- Track list display
- Search functionality
- Playback controls
- Permission handling UI
- Loading and error states

## 🔧 Dependencies

### Core Dependencies
```yaml
# Audio playback
just_audio: ^0.9.46              # Audio player
audio_service: ^0.18.18          # Background audio

# Music file access
on_audio_query: ^2.9.0           # Query device music
permission_handler: ^11.4.0      # Runtime permissions

# State management
provider: ^6.1.5                 # State management
rxdart: ^0.28.0                  # Reactive streams

# UI
google_fonts: ^6.2.1             # Custom fonts
cached_network_image: ^3.3.1     # Image caching

# Storage
path_provider: ^2.1.5            # File paths
```

## 📱 Permissions

### Android Manifest Configuration
The app requests the following permissions:

**For Android 13+ (API 33+):**
```xml
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

**For Android 12 and below:**
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```

**Audio playback:**
```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

## 🚀 Usage

### Basic Usage Flow

1. **App Launch:**
   - App initializes services
   - Requests storage permissions
   - Scans device for music files
   - Displays track list

2. **Playing Music:**
   ```dart
   // Play a specific track
   await audioPlayer.playTrack(track);
   
   // Play all tracks
   await audioPlayer.setPlaylist(tracks);
   await audioPlayer.play();
   
   // Control playback
   await audioPlayer.pause();
   await audioPlayer.skipToNext();
   await audioPlayer.skipToPrevious();
   ```

3. **Search Functionality:**
   ```dart
   // Search tracks
   final results = musicService.searchTracks("song name");
   ```

4. **Shuffle and Repeat:**
   ```dart
   // Enable shuffle
   await audioPlayer.setShuffle(true);
   
   // Set repeat mode
   await audioPlayer.setLoopMode(LoopMode.all);
   ```

## 🔍 Key Features Explained

### 1. Album Artwork Display
Uses `QueryArtworkWidget` from `on_audio_query`:
```dart
QueryArtworkWidget(
  id: track.albumId!,
  type: ArtworkType.ALBUM,
  artworkFit: BoxFit.cover,
  nullArtworkWidget: placeholderWidget,
)
```

### 2. Real-time Track Updates
Uses streams to update UI:
```dart
StreamBuilder<Track?>(
  stream: audioPlayer.currentTrackStream,
  builder: (context, snapshot) {
    final isPlaying = snapshot.data?.id == track.id;
    return TrackListItem(
      track: track,
      isPlaying: isPlaying,
    );
  },
)
```

### 3. Permission Handling
Automatic permission detection:
```dart
// Check Android version and request appropriate permission
if (await Permission.audio.isGranted) {
  // Android 13+
  return true;
}
if (await Permission.storage.isGranted) {
  // Android 12 and below
  return true;
}
```

### 4. Background Playback
Configured via `audio_service` in AndroidManifest.xml:
```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback">
</service>
```

## 🎨 UI Components

### Track List Item
- Album artwork (56x56)
- Track title
- Artist name
- Duration
- Playing indicator
- Options menu button

### Empty States
- **No Permission:** Shows permission request button
- **No Music:** Shows empty state with refresh button
- **Loading:** Shows loading spinner

### Controls
- **Shuffle Button:** Toggle shuffle mode
- **Play All Button:** Play entire playlist
- **Search Button:** Open search dialog
- **Filter Button:** Show track count

## 🐛 Troubleshooting

### Common Issues

#### 1. **Gradle Build Errors**
**Issue:** `on_audio_query_android` namespace error

**Solution:**
The plugin has a Gradle compatibility issue with newer Android Gradle Plugin versions. To fix:

**Option A: Manual Plugin Fix**
Navigate to the plugin folder:
```
C:\Users\[USER]\AppData\Local\Pub\Cache\hosted\pub.dev\on_audio_query_android-1.1.0\android\
```

Edit `build.gradle` and add:
```gradle
android {
    namespace 'com.lucasjosino.on_audio_query'
    // ... rest of config
}
```

**Option B: Use Different Plugin**
Replace `on_audio_query` with `flutter_audio_query` or implement custom file scanning.

#### 2. **Permissions Not Granted**
**Issue:** App can't access music files

**Solutions:**
- Ensure permissions are declared in AndroidManifest.xml
- For Android 13+, use `READ_MEDIA_AUDIO` permission
- Check device settings manually
- Use `openAppSettings()` to direct users to settings

#### 3. **No Music Found**
**Issue:** Device has music but app shows empty

**Solutions:**
- Check if audio files are in external storage
- Verify file formats are supported
- Ensure files are indexed by MediaStore
- Try refreshing the track list

#### 4. **Playback Issues**
**Issue:** Audio doesn't play or stutters

**Solutions:**
- Check audio file integrity
- Ensure sufficient storage space
- Verify audio codec support
- Check for conflicting audio apps

## 📊 Performance Considerations

### Optimization Tips

1. **Lazy Loading:**
   - Load tracks in batches for large libraries
   - Use pagination in track list
   - Cache album artwork

2. **Memory Management:**
   - Release player resources when not needed
   - Clear unused artwork cache
   - Dispose streams properly

3. **Battery Optimization:**
   - Use `WAKE_LOCK` judiciously
   - Pause playback when headphones disconnected
   - Implement proper lifecycle management

## 🔐 Security & Privacy

- **No Internet Required:** All music stays on device
- **No Data Collection:** App doesn't send data externally
- **Permission Transparency:** Clear permission explanations
- **Local Storage Only:** Music files never leave device

## 📈 Future Enhancements

### Planned Features
- [ ] Mini player (bottom sheet)
- [ ] Playlist creation and management
- [ ] Equalizer integration
- [ ] Sleep timer
- [ ] Lyrics display (if available)
- [ ] Album and Artist views
- [ ] Genre filtering
- [ ] Recently played section
- [ ] Favorites/Like system
- [ ] Widget support
- [ ] Android Auto integration
- [ ] Wear OS support

### Advanced Features
- [ ] Audio effects (Bass boost, Virtualizer)
- [ ] Crossfade between tracks
- [ ] Gapless playback
- [ ] ReplayGain support
- [ ] Smart playlists
- [ ] Music library stats
- [ ] Export/Import playlists
- [ ] Cloud sync (optional)

## 🧪 Testing

### Manual Testing Checklist
- [ ] App requests permissions on first launch
- [ ] Music files load from device
- [ ] Album artwork displays correctly
- [ ] Playback works (play/pause/skip)
- [ ] Shuffle mode functions
- [ ] Repeat modes work
- [ ] Search finds tracks
- [ ] Pull-to-refresh updates list
- [ ] App handles no music gracefully
- [ ] Background playback works
- [ ] Notification controls work

### Test Scenarios
1. **First Launch:**
   - Fresh install → Permission request → Music loads

2. **Permission Denied:**
   - Deny permission → Show permission screen → Can retry

3. **Large Library:**
   - 1000+ tracks → Smooth scrolling → Fast search

4. **Playback:**
   - Play track → Pause → Resume → Skip → Seek

5. **Edge Cases:**
   - No music files → Empty state
   - Corrupted file → Skip to next
   - Low storage → Handle gracefully

## 📝 Code Examples

### Play Music on Track Tap
```dart
Future<void> _playTrack(Track track) async {
  try {
    await _audioPlayer.setPlaylist(_filteredTracks);
    await _audioPlayer.playTrack(track);
    _showSnackBar('Playing: ${track.title}');
  } catch (e) {
    _showSnackBar('Failed to play track');
  }
}
```

### Monitor Playback State
```dart
StreamBuilder<bool>(
  stream: _audioPlayer.isPlayingStream,
  builder: (context, snapshot) {
    final isPlaying = snapshot.data ?? false;
    return IconButton(
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: () => _audioPlayer.togglePlayPause(),
    );
  },
)
```

### Format Duration
```dart
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  
  if (hours > 0) {
    return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  return '$minutes:${twoDigits(seconds)}';
}
```

## 🎯 Best Practices

1. **Always dispose streams and controllers:**
   ```dart
   @override
   void dispose() {
     _audioPlayer.dispose();
     _tabController.dispose();
     super.dispose();
   }
   ```

2. **Handle async operations safely:**
   ```dart
   Future<void> loadMusic() async {
     if (!mounted) return;
     setState(() => _isLoading = true);
     
     try {
       final tracks = await _musicService.loadAllTracks();
       if (!mounted) return;
       setState(() {
         _tracks = tracks;
         _isLoading = false;
       });
     } catch (e) {
       if (!mounted) return;
       setState(() => _isLoading = false);
     }
   }
   ```

3. **Use const constructors:**
   ```dart
   const Icon(Icons.play_arrow)  // ✅ Good
   Icon(Icons.play_arrow)        // ❌ Avoid
   ```

4. **Provide fallbacks:**
   ```dart
   track.title ?? 'Unknown Track'
   track.artist ?? '<unknown>'
   ```

## 📞 Support & Resources

### Documentation
- [just_audio](https://pub.dev/packages/just_audio)
- [on_audio_query](https://pub.dev/packages/on_audio_query)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [Flutter Docs](https://flutter.dev/docs)

### Common Links
- [Android Media Guide](https://developer.android.com/guide/topics/media)
- [Audio Focus](https://developer.android.com/guide/topics/media-apps/audio-focus)
- [Background Services](https://developer.android.com/guide/components/services)

## ✅ Final Checklist

Before deploying:
- [ ] Test on multiple Android versions (API 21+)
- [ ] Test with various audio formats
- [ ] Test with large music libraries (1000+ tracks)
- [ ] Verify permissions on Android 13+
- [ ] Test background playback
- [ ] Check memory usage
- [ ] Test on different screen sizes
- [ ] Verify all UI states (loading, empty, error)
- [ ] Test search functionality
- [ ] Verify shuffle and repeat modes
- [ ] Check notification controls
- [ ] Test with headphones (connect/disconnect)

---

**Built with ❤️ using Flutter**

*Last Updated: 2024*