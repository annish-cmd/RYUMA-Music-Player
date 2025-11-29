import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing available theme options
enum AppThemeType { red, blue, green, yellow, orange, navyBlue, white }

/// Model class representing a gradient theme
class GradientTheme {
  final String name;
  final List<Color> primaryGradient;
  final List<Color> accentGradient;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color progressColor;
  final Color buttonColor;
  final Color shadowColor;
  final Brightness brightness;

  const GradientTheme({
    required this.name,
    required this.primaryGradient,
    required this.accentGradient,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.progressColor,
    required this.buttonColor,
    required this.shadowColor,
    this.brightness = Brightness.dark,
  });
}

/// Service for managing app theme with gradient colors
class AppThemeService extends ChangeNotifier {
  static final AppThemeService _instance = AppThemeService._internal();
  factory AppThemeService() => _instance;
  AppThemeService._internal();

  static const String _themeKey = 'app_theme_type';

  AppThemeType _currentThemeType = AppThemeType.red;
  bool _isInitialized = false;

  /// Available themes
  static final Map<AppThemeType, GradientTheme> themes = {
    AppThemeType.red: const GradientTheme(
      name: 'Red',
      primaryGradient: [Color(0xFFFF5252), Color(0xFFFF1744)],
      accentGradient: [Color(0xFFFF1744), Color(0xFFD50000)],
      primaryColor: Color(0xFFFF5252),
      accentColor: Color(0xFFFF1744),
      backgroundColor: Color(0xFF0A1929),
      surfaceColor: Color(0xFF1A2F42),
      cardColor: Color(0xFF0D1B2A),
      progressColor: Color(0xFFFF5252),
      buttonColor: Color(0xFFFF1744),
      shadowColor: Color(0x66FF5252),
    ),
    AppThemeType.blue: const GradientTheme(
      name: 'Blue',
      primaryGradient: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
      accentGradient: [Color(0xFF1E88E5), Color(0xFF1565C0)],
      primaryColor: Color(0xFF42A5F5),
      accentColor: Color(0xFF1E88E5),
      backgroundColor: Color(0xFF0A1929),
      surfaceColor: Color(0xFF1A2F42),
      cardColor: Color(0xFF0D1B2A),
      progressColor: Color(0xFF42A5F5),
      buttonColor: Color(0xFF1E88E5),
      shadowColor: Color(0x6642A5F5),
    ),
    AppThemeType.green: const GradientTheme(
      name: 'Green',
      primaryGradient: [Color(0xFF66BB6A), Color(0xFF43A047)],
      accentGradient: [Color(0xFF43A047), Color(0xFF2E7D32)],
      primaryColor: Color(0xFF66BB6A),
      accentColor: Color(0xFF43A047),
      backgroundColor: Color(0xFF0A1F1A),
      surfaceColor: Color(0xFF1A3F32),
      cardColor: Color(0xFF0D2A1F),
      progressColor: Color(0xFF66BB6A),
      buttonColor: Color(0xFF43A047),
      shadowColor: Color(0x6666BB6A),
    ),
    AppThemeType.yellow: const GradientTheme(
      name: 'Yellow',
      primaryGradient: [Color(0xFFFFCA28), Color(0xFFFFB300)],
      accentGradient: [Color(0xFFFFB300), Color(0xFFFFA000)],
      primaryColor: Color(0xFFFFCA28),
      accentColor: Color(0xFFFFB300),
      backgroundColor: Color(0xFF1A1A0A),
      surfaceColor: Color(0xFF2F2F1A),
      cardColor: Color(0xFF1F1F0D),
      progressColor: Color(0xFFFFCA28),
      buttonColor: Color(0xFFFFB300),
      shadowColor: Color(0x66FFCA28),
    ),
    AppThemeType.orange: const GradientTheme(
      name: 'Orange',
      primaryGradient: [Color(0xFFFF9800), Color(0xFFF57C00)],
      accentGradient: [Color(0xFFF57C00), Color(0xFFE65100)],
      primaryColor: Color(0xFFFF9800),
      accentColor: Color(0xFFF57C00),
      backgroundColor: Color(0xFF1A120A),
      surfaceColor: Color(0xFF2F2518),
      cardColor: Color(0xFF1F180D),
      progressColor: Color(0xFFFF9800),
      buttonColor: Color(0xFFF57C00),
      shadowColor: Color(0x66FF9800),
    ),
    AppThemeType.navyBlue: const GradientTheme(
      name: 'Navy Blue',
      primaryGradient: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
      accentGradient: [Color(0xFF3949AB), Color(0xFF283593)],
      primaryColor: Color(0xFF5C6BC0),
      accentColor: Color(0xFF3949AB),
      backgroundColor: Color(0xFF0A0A1F),
      surfaceColor: Color(0xFF1A1A3F),
      cardColor: Color(0xFF0D0D2A),
      progressColor: Color(0xFF5C6BC0),
      buttonColor: Color(0xFF3949AB),
      shadowColor: Color(0x665C6BC0),
    ),
    AppThemeType.white: const GradientTheme(
      name: 'White',
      primaryGradient: [Color(0xFF607D8B), Color(0xFF455A64)],
      accentGradient: [Color(0xFF455A64), Color(0xFF37474F)],
      primaryColor: Color(0xFF607D8B),
      accentColor: Color(0xFF455A64),
      backgroundColor: Color(0xFFF5F5F5),
      surfaceColor: Color(0xFFFFFFFF),
      cardColor: Color(0xFFEEEEEE),
      progressColor: Color(0xFF607D8B),
      buttonColor: Color(0xFF455A64),
      shadowColor: Color(0x33000000),
      brightness: Brightness.light,
    ),
  };

  /// Getters
  AppThemeType get currentThemeType => _currentThemeType;
  GradientTheme get currentTheme => themes[_currentThemeType]!;
  bool get isInitialized => _isInitialized;

  /// Convenience getters for current theme properties
  List<Color> get primaryGradient => currentTheme.primaryGradient;
  List<Color> get accentGradient => currentTheme.accentGradient;
  Color get primaryColor => currentTheme.primaryColor;
  Color get accentColor => currentTheme.accentColor;
  Color get backgroundColor => currentTheme.backgroundColor;
  Color get surfaceColor => currentTheme.surfaceColor;
  Color get cardColor => currentTheme.cardColor;
  Color get progressColor => currentTheme.progressColor;
  Color get buttonColor => currentTheme.buttonColor;
  Color get shadowColor => currentTheme.shadowColor;
  Brightness get brightness => currentTheme.brightness;

  /// Text colors based on brightness
  Color get textPrimaryColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black87;
  Color get textSecondaryColor =>
      brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get textHintColor =>
      brightness == Brightness.dark ? Colors.grey[600]! : Colors.grey[400]!;

  /// Icon colors
  Color get iconColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black87;
  Color get iconSecondaryColor =>
      brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;

  /// Screen background gradient
  List<Color> get screenGradient => [
    surfaceColor,
    backgroundColor,
    brightness == Brightness.dark
        ? backgroundColor.withValues(alpha: 0.9)
        : backgroundColor,
  ];

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _currentThemeType = AppThemeType.values.firstWhere(
        (t) => t.name == savedTheme,
        orElse: () => AppThemeType.red,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Set the theme
  Future<void> setTheme(AppThemeType themeType) async {
    if (_currentThemeType == themeType) return;

    _currentThemeType = themeType;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeType.name);

    notifyListeners();
  }

  /// Get gradient decoration for containers
  BoxDecoration getGradientDecoration({
    BorderRadius? borderRadius,
    bool useAccent = false,
    double opacity = 1.0,
  }) {
    final colors = useAccent ? accentGradient : primaryGradient;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: opacity < 1.0
            ? colors.map((c) => c.withValues(alpha: opacity)).toList()
            : colors,
      ),
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Get card decoration
  BoxDecoration getCardDecoration({
    BorderRadius? borderRadius,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surfaceColor, cardColor],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Get play button decoration
  BoxDecoration getPlayButtonDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: primaryGradient),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Get MaterialApp theme data
  ThemeData getThemeData() {
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimaryColor),
        bodyMedium: TextStyle(color: textPrimaryColor),
        bodySmall: TextStyle(color: textSecondaryColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(color: iconColor),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: textHintColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: progressColor,
        linearTrackColor: textHintColor,
      ),
    );
  }

  /// Get gradient shader for text
  Shader getTextGradientShader(Rect bounds) {
    return LinearGradient(
      colors: [...primaryGradient, Colors.white],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(bounds);
  }
}

/// Global instance for easy access
final appTheme = AppThemeService();
