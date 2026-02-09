import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import 'tracks_screen.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() onInitializationComplete;
  
  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _initializationComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations and initialization
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Start animations
    await _animationController.forward();
    
    // Add a small delay for visual effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Run initialization
    try {
      await widget.onInitializationComplete();
      
      // Add another small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Navigate to main screen
      if (mounted) {
        setState(() {
          _initializationComplete = true;
        });
        
        // Navigate after a brief moment to show the completed state
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TracksScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      // Even if initialization fails, we should still proceed to avoid infinite splash
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TracksScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = appTheme.currentTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 60,
                    color: theme.backgroundColor,
                  ),
                ),
                const SizedBox(height: 30),
                
                // App Name
                Text(
                  'RYUMA',
                  style: TextStyle(
                    fontFamily: 'NightMachine',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: appTheme.textPrimaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Loading indicator or check mark
                SizedBox(
                  width: 24,
                  height: 24,
                  child: _initializationComplete
                      ? Icon(
                          Icons.check,
                          color: theme.primaryColor,
                          size: 24,
                        )
                      : CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.primaryColor,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                
                // Status text
                Text(
                  _initializationComplete
                      ? 'Ready to play!'
                      : 'Loading your music...',
                  style: TextStyle(
                    fontSize: 16,
                    color: appTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}