import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/tracks_screen.dart';
import 'services/audio_handler.dart';
import 'services/theme_service.dart';

// Global audio handler instance
late AudioPlayerHandler audioHandler;

// Flag to track if audio service is properly initialized
bool isAudioServiceInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('=== RYUMA Music Starting ===');

  // Initialize theme service
  await appTheme.initialize();
  debugPrint('Theme service initialized');

  // Set system UI style based on theme
  _updateSystemUI();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Request notification permission for Android 13+
  await _requestNotificationPermission();

  // Initialize audio handler with audio service for lock screen notification
  await _initAudioService();

  runApp(const RyumaMusicApp());
}

/// Request notification permission for Android 13+
Future<void> _requestNotificationPermission() async {
  debugPrint('Checking notification permission...');

  // Check if notification permission is needed (Android 13+)
  final status = await Permission.notification.status;
  debugPrint('Notification permission status: $status');

  if (status.isDenied) {
    debugPrint('Requesting notification permission...');
    final result = await Permission.notification.request();
    debugPrint('Notification permission result: $result');

    if (result.isGranted) {
      debugPrint('Notification permission GRANTED');
    } else if (result.isPermanentlyDenied) {
      debugPrint(
        'Notification permission permanently denied. User needs to enable in settings.',
      );
    } else {
      debugPrint('Notification permission DENIED');
    }
  } else if (status.isGranted) {
    debugPrint('Notification permission already GRANTED');
  }
}

/// Initialize AudioService for background playback and lock screen notification
Future<void> _initAudioService() async {
  debugPrint('Initializing AudioService...');

  try {
    audioHandler = await AudioService.init(
      builder: () {
        debugPrint('AudioPlayerHandler builder called');
        return AudioPlayerHandler();
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.ani_music.audio',
        androidNotificationChannelName: 'RYUMA Music',
        androidNotificationChannelDescription:
            'Music playback controls for RYUMA',
        androidNotificationIcon: 'drawable/ic_notification',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF0A1929),
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );

    isAudioServiceInitialized = true;
    debugPrint('=== AudioService initialized SUCCESSFULLY! ===');
    debugPrint('audioHandler type: ${audioHandler.runtimeType}');
  } catch (e, stackTrace) {
    debugPrint('=== ERROR: AudioService.init FAILED! ===');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint(
      'Creating fallback AudioPlayerHandler without notification support...',
    );

    // Fallback: create audio handler without audio service
    audioHandler = AudioPlayerHandler();
    isAudioServiceInitialized = false;
  }
}

void _updateSystemUI() {
  final theme = appTheme.currentTheme;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: theme.backgroundColor,
      systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
}

class RyumaMusicApp extends StatelessWidget {
  const RyumaMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appTheme,
      builder: (context, child) {
        // Update system UI when theme changes
        _updateSystemUI();

        return MaterialApp(
          title: 'RYUMA Music',
          debugShowCheckedModeBanner: false,
          theme: appTheme.getThemeData(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
          home: const TracksScreen(),
        );
      },
    );
  }
}
