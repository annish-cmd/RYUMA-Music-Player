# 🎵 RYUMA Music Player

A professional, modern music player application built with Flutter, featuring a sleek dark theme UI inspired by premium music streaming services.

![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

<img width="3464" height="1949" alt="RYUMA" src="https://github.com/user-attachments/assets/e32da859-cd1c-4285-a22b-1c88a9d0bb1b" />






## ✨ Features

- **Beautiful UI Design**: Dark-themed interface with gradient backgrounds and smooth animations
- **Track Management**: Browse and organize your music library with ease
- **Album & Artist Views**: Navigate through your music by albums and artists (Tabs available)
- **Shuffle Mode**: Randomize your listening experience
- **Search Functionality**: Quickly find your favorite tracks
- **Settings**: Customize your music experience
- **Responsive Design**: Optimized for all screen sizes
- **Clean Architecture**: Well-structured codebase following Flutter best practices

## 🎨 Design Features

- **Custom App Bar**: Clean navigation with RYUMA branding
- **Tab Navigation**: Switch between Tracks, Albums, and Artists
- **Track List Items**: Each track displays with album art, title, and artist
- **Control Bar**: Quick access to shuffle and play functions
- **Gradient Backgrounds**: Smooth color transitions for visual appeal
- **Material Design Icons**: Consistent iconography throughout

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.1 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android Device or Emulator (for Android testing)
- Xcode (for iOS development on macOS)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/ani_music.git
   cd ani_music
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   ```bash
   # For debug mode
   flutter run

   # For release mode
   flutter run --release
   ```

4. **Build APK (Android)**

   ```bash
   flutter build apk --release
   ```

5. **Build iOS**
   ```bash
   flutter build ios --release
   ```

## 📁 Project Structure

```
ani_music/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── track.dart           # Track data model
│   ├── screens/
│   │   └── tracks_screen.dart   # Main tracks screen
│   └── widgets/
│       └── track_list_item.dart # Track list item widget
├── assets/
│   └── images/                  # Album art and images
├── android/                     # Android-specific files
├── ios/                         # iOS-specific files
└── pubspec.yaml                 # Project dependencies

```

## 🛠️ Technologies Used

- **Flutter**: UI framework for building natively compiled applications
- **Dart**: Programming language optimized for building mobile apps
- **Material Design**: Google's design system for consistent UI
- **Google Fonts**: Custom typography (optional)

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

## 🎯 Usage

### Adding Tracks

Currently, the app displays sample tracks. To integrate with actual music files:

1. Add music file scanning functionality
2. Use plugins like `on_audio_query` to fetch device music
3. Update the Track model with file paths
4. Implement audio playback with `just_audio` or `audioplayers`

### Customization

**Change Theme Colors:**

```dart
// In main.dart
theme: ThemeData(
  primarySwatch: Colors.blue, // Change to your preferred color
  scaffoldBackgroundColor: const Color(0xFF0A1929), // Background color
  brightness: Brightness.dark,
)
```

**Add More Tracks:**

```dart
// In tracks_screen.dart
final List<Track> _tracks = [
  Track(id: '1', title: 'Your Song', artist: 'Artist Name'),
  // Add more tracks...
];
```

## 🔧 Configuration

### Android

Minimum SDK version is set to 21 (Android 5.0). Update in `android/app/build.gradle` if needed:

```gradle
minSdkVersion 21
targetSdkVersion 34
```



## 🎨 Color Palette

| Color          | Hex Code  | Usage                |
| -------------- | --------- | -------------------- |
| Primary Dark   | `#0A1929` | Background           |
| Secondary Dark | `#1A2F42` | Gradient accent      |
| Text Primary   | `#FFFFFF` | Main text            |
| Text Secondary | `#9E9E9E` | Subtitle text        |
| Accent         | `#2196F3` | Interactive elements |

## 🔮 Future Enhancements

- [ ] Audio playback functionality
- [ ] Playlist creation and management
- [ ] Music file import from device storage
- [ ] Equalizer settings
- [ ] Sleep timer
- [ ] Lyrics display
- [ ] Cross-fade between tracks
- [ ] Mini player (bottom sheet)
- [ ] Favorite/Like songs
- [ ] Recently played section
- [ ] Search with filters
- [ ] Dark/Light theme toggle
- [ ] Queue management
- [ ] Share tracks
- [ ] Cloud sync

## 🐛 Known Issues

- Album art currently shows placeholder images
- Audio playback not yet implemented
- Track duration not displayed

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name**

- GitHub: [@annish-cmd](https://github.com/annish-cmd)
