# 🚀 Phoenix Music App - Setup & Run Guide

This guide will help you set up and run the Phoenix Music Player on your device.

## 📋 Prerequisites

Before you begin, make sure you have the following installed:

### Required Software

1. **Flutter SDK** (Version 3.10.1 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter --version`

2. **Dart SDK** (Comes with Flutter)
   - Verify: `dart --version`

3. **Git** (for cloning the repository)
   - Download from: https://git-scm.com/downloads

4. **Android Studio** OR **VS Code**
   - Android Studio: https://developer.android.com/studio
   - VS Code: https://code.visualstudio.com/

### For Android Development

- **Android SDK** (API level 21 or higher)
- **Android Emulator** or **Physical Android Device** with USB debugging enabled

### For iOS Development (macOS only)

- **Xcode** (Latest version)
- **CocoaPods**: `sudo gem install cocoapods`
- **iOS Simulator** or **Physical iOS Device**

---

## 📥 Installation Steps

### Step 1: Clone or Navigate to the Project

```bash
cd "E:\Flutter Projects\ani_music"
```

If you're cloning from Git:
```bash
git clone <repository-url>
cd ani_music
```

### Step 2: Check Flutter Installation

```bash
flutter doctor
```

This command checks your environment and displays a report. Fix any issues marked with ❌.

### Step 3: Install Dependencies

```bash
flutter pub get
```

This will download all required packages listed in `pubspec.yaml`.

### Step 4: Verify Project Structure

Ensure your project has the following structure:

```
ani_music/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── track.dart
│   ├── screens/
│   │   └── tracks_screen.dart
│   └── widgets/
│       └── track_list_item.dart
├── assets/
│   └── images/
├── android/
├── ios/
└── pubspec.yaml
```

---

## 🏃 Running the App

### Option 1: Using Command Line

#### Run on Connected Device/Emulator

1. **List available devices:**
   ```bash
   flutter devices
   ```

2. **Run the app in debug mode:**
   ```bash
   flutter run
   ```

3. **Run in release mode (faster performance):**
   ```bash
   flutter run --release
   ```

4. **Run on specific device:**
   ```bash
   flutter run -d <device-id>
   ```

### Option 2: Using Android Studio

1. Open Android Studio
2. Click **File > Open** and select the `ani_music` folder
3. Wait for Gradle sync to complete
4. Select a device/emulator from the device dropdown
5. Click the **Run** button (green play icon) or press `Shift + F10`

### Option 3: Using VS Code

1. Open VS Code
2. Open the `ani_music` folder
3. Press `F5` or click **Run > Start Debugging**
4. Select your target device from the bottom status bar

---

## 📱 Building APK/IPA

### Build Android APK (Debug)

```bash
flutter build apk --debug
```

Location: `build/app/outputs/flutter-apk/app-debug.apk`

### Build Android APK (Release)

```bash
flutter build apk --release
```

Location: `build/app/outputs/flutter-apk/app-release.apk`

### Build Android App Bundle (For Play Store)

```bash
flutter build appbundle --release
```

Location: `build/app/outputs/bundle/release/app-release.aab`

### Build iOS (macOS only)

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and distribute.

---

## 🔧 Troubleshooting

### Issue: "Flutter command not found"

**Solution:**
- Add Flutter to your PATH:
  - Windows: Add `C:\flutter\bin` to system PATH
  - macOS/Linux: Add `export PATH="$PATH:[PATH_TO_FLUTTER]/flutter/bin"` to `.bashrc` or `.zshrc`

### Issue: "Gradle sync failed"

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Issue: "Unable to locate Android SDK"

**Solution:**
- Open Android Studio > Settings > Appearance & Behavior > System Settings > Android SDK
- Note the SDK location
- Set environment variable: `ANDROID_HOME=<sdk-location>`

### Issue: "No devices found"

**Solution:**
- **For Emulator:** 
  - Open Android Studio > Tools > AVD Manager > Create Virtual Device
- **For Physical Device:**
  - Enable USB Debugging in Developer Options
  - Connect via USB and authorize the computer

### Issue: "CocoaPods not installed" (iOS)

**Solution:**
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

### Issue: "Build failed with Gradle errors"

**Solution:**
```bash
flutter clean
cd android
./gradlew clean
./gradlew build --refresh-dependencies
cd ..
flutter pub get
flutter run
```

### Issue: "Hot reload not working"

**Solution:**
- Try `r` for hot reload in terminal
- Try `R` for hot restart
- Stop the app and run again with `flutter run`

---

## 🎮 Development Tips

### Hot Reload

While the app is running, make changes to the code and:
- Press `r` in the terminal for hot reload
- Press `R` for full restart
- Press `q` to quit

### Debug Mode Features

- Press `p` - Toggle performance overlay
- Press `o` - Toggle widget inspector
- Press `z` - Toggle debug paint
- Press `w` - Dump widget hierarchy

### Logging

Add debug prints in your code:
```dart
print('Debug message: $variable');
debugPrint('Debug message');
```

View logs:
```bash
flutter logs
```

---

## 📊 Performance Optimization

### Analyze App Size

```bash
flutter build apk --analyze-size
```

### Check for Performance Issues

```bash
flutter run --profile
```

### Run Tests

```bash
flutter test
```

---

## 🔄 Updating Dependencies

### Check for outdated packages

```bash
flutter pub outdated
```

### Upgrade all packages

```bash
flutter pub upgrade
```

### Upgrade Flutter SDK

```bash
flutter upgrade
```

---

## 🌐 Running on Physical Device

### Android

1. Enable **Developer Options** on your device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times

2. Enable **USB Debugging**:
   - Go to Settings > Developer Options
   - Enable "USB Debugging"

3. Connect device via USB

4. Authorize the computer on your device

5. Run: `flutter devices` to verify connection

6. Run: `flutter run`

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode

2. Select your device from the device dropdown

3. Set your development team in Signing & Capabilities

4. Build and run from Xcode or use:
   ```bash
   flutter run
   ```

---

## 📝 Common Commands Cheat Sheet

| Command | Description |
|---------|-------------|
| `flutter doctor` | Check Flutter installation |
| `flutter pub get` | Install dependencies |
| `flutter clean` | Clean build files |
| `flutter run` | Run app in debug mode |
| `flutter run --release` | Run in release mode |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS app |
| `flutter devices` | List connected devices |
| `flutter logs` | View app logs |
| `flutter analyze` | Analyze code for issues |
| `flutter test` | Run tests |

---

## 🎯 Next Steps

After successfully running the app:

1. **Explore the Code**
   - Check `lib/main.dart` for app entry point
   - Review `lib/screens/tracks_screen.dart` for UI implementation
   - Understand `lib/models/track.dart` for data structure

2. **Customize**
   - Change colors in `main.dart`
   - Add more tracks in `tracks_screen.dart`
   - Modify UI in widgets

3. **Add Features**
   - Implement audio playback
   - Add search functionality
   - Create playlist management

---

## 📞 Need Help?

- **Flutter Documentation:** https://flutter.dev/docs
- **Flutter Community:** https://flutter.dev/community
- **Stack Overflow:** Tag questions with `flutter`
- **GitHub Issues:** Report bugs in the repository

---

## ✅ Quick Start Checklist

- [ ] Flutter SDK installed and in PATH
- [ ] Android Studio/Xcode installed
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] Device/emulator connected and detected
- [ ] App runs successfully (`flutter run`)
- [ ] Can see Phoenix Music UI with track list

---

**Happy Coding! 🎵**