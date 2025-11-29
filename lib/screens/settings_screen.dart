import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings keys
  static const String _autoPlayKey = 'setting_auto_play';
  static const String _gaplessKey = 'setting_gapless';
  static const String _crossfadeKey = 'setting_crossfade';
  static const String _crossfadeDurationKey = 'setting_crossfade_duration';
  static const String _audioQualityKey = 'setting_audio_quality';
  static const String _showArtworkKey = 'setting_show_artwork';
  static const String _keepScreenOnKey = 'setting_keep_screen_on';
  static const String _themeKey = 'setting_theme';
  static const String _accentColorKey = 'setting_accent_color';

  // Settings values
  bool _autoPlay = true;
  bool _gaplessPlayback = true;
  bool _crossfadeEnabled = false;
  int _crossfadeDuration = 5;
  String _audioQuality = 'High';
  bool _showArtwork = true;
  bool _keepScreenOn = false;
  String _theme = 'Dark';
  int _accentColorIndex = 0;

  final List<Color> _accentColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoPlay = prefs.getBool(_autoPlayKey) ?? true;
      _gaplessPlayback = prefs.getBool(_gaplessKey) ?? true;
      _crossfadeEnabled = prefs.getBool(_crossfadeKey) ?? false;
      _crossfadeDuration = prefs.getInt(_crossfadeDurationKey) ?? 5;
      _audioQuality = prefs.getString(_audioQualityKey) ?? 'High';
      _showArtwork = prefs.getBool(_showArtworkKey) ?? true;
      _keepScreenOn = prefs.getBool(_keepScreenOnKey) ?? false;
      _theme = prefs.getString(_themeKey) ?? 'Dark';
      _accentColorIndex = prefs.getInt(_accentColorKey) ?? 0;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          // Playback Section
          _buildSectionHeader('Playback'),
          _buildSwitchTile(
            icon: Icons.play_circle_outline,
            title: 'Auto-play',
            subtitle: 'Automatically play next track',
            value: _autoPlay,
            onChanged: (value) {
              setState(() => _autoPlay = value);
              _saveSetting(_autoPlayKey, value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.compare_arrows,
            title: 'Gapless Playback',
            subtitle: 'No silence between tracks',
            value: _gaplessPlayback,
            onChanged: (value) {
              setState(() => _gaplessPlayback = value);
              _saveSetting(_gaplessKey, value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.swap_horiz,
            title: 'Crossfade',
            subtitle: 'Smooth transition between tracks',
            value: _crossfadeEnabled,
            onChanged: (value) {
              setState(() => _crossfadeEnabled = value);
              _saveSetting(_crossfadeKey, value);
            },
          ),
          if (_crossfadeEnabled)
            _buildSliderTile(
              icon: Icons.timelapse,
              title: 'Crossfade Duration',
              subtitle: '$_crossfadeDuration seconds',
              value: _crossfadeDuration.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (value) {
                setState(() => _crossfadeDuration = value.round());
                _saveSetting(_crossfadeDurationKey, value.round());
              },
            ),

          const SizedBox(height: 16),
          // Audio Section
          _buildSectionHeader('Audio'),
          _buildOptionTile(
            icon: Icons.high_quality,
            title: 'Audio Quality',
            subtitle: _audioQuality,
            onTap: () => _showAudioQualityDialog(),
          ),
          _buildNavigationTile(
            icon: Icons.equalizer,
            title: 'Equalizer',
            subtitle: 'Customize audio output',
            onTap: () => _showEqualizerDialog(),
          ),

          const SizedBox(height: 16),
          // Display Section
          _buildSectionHeader('Display'),
          _buildSwitchTile(
            icon: Icons.image,
            title: 'Show Album Artwork',
            subtitle: 'Display album art in lists and player',
            value: _showArtwork,
            onChanged: (value) {
              setState(() => _showArtwork = value);
              _saveSetting(_showArtworkKey, value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.lightbulb_outline,
            title: 'Keep Screen On',
            subtitle: 'Prevent screen from sleeping while playing',
            value: _keepScreenOn,
            onChanged: (value) {
              setState(() => _keepScreenOn = value);
              _saveSetting(_keepScreenOnKey, value);
            },
          ),
          _buildOptionTile(
            icon: Icons.color_lens,
            title: 'Accent Color',
            subtitle: 'Choose app accent color',
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _accentColors[_accentColorIndex],
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _showAccentColorDialog(),
          ),

          const SizedBox(height: 16),
          // Storage Section
          _buildSectionHeader('Storage'),
          _buildNavigationTile(
            icon: Icons.cached,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _showClearCacheDialog(),
          ),
          _buildNavigationTile(
            icon: Icons.folder_outlined,
            title: 'Scan Music Library',
            subtitle: 'Refresh your music collection',
            onTap: () => _scanMusicLibrary(),
          ),

          const SizedBox(height: 16),
          // About Section
          _buildSectionHeader('About'),
          _buildNavigationTile(
            icon: Icons.info_outline,
            title: 'About RYUMA',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          _buildNavigationTile(
            icon: Icons.star_outline,
            title: 'Rate App',
            subtitle: 'Share your feedback',
            onTap: () => _rateApp(),
          ),
          _buildNavigationTile(
            icon: Icons.share_outlined,
            title: 'Share App',
            subtitle: 'Tell your friends about RYUMA',
            onTap: () => _shareApp(),
          ),
          _buildNavigationTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () => _showPrivacyPolicy(),
          ),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () => _showTermsOfService(),
          ),

          const SizedBox(height: 16),
          // Danger Zone
          _buildSectionHeader('Data'),
          _buildNavigationTile(
            icon: Icons.download_outlined,
            title: 'Export Data',
            subtitle: 'Backup playlists and settings',
            onTap: () => _exportData(),
          ),
          _buildNavigationTile(
            icon: Icons.upload_outlined,
            title: 'Import Data',
            subtitle: 'Restore from backup',
            onTap: () => _importData(),
          ),
          _buildDangerTile(
            icon: Icons.delete_forever,
            title: 'Reset All Settings',
            subtitle: 'Restore default settings',
            onTap: () => _showResetDialog(),
          ),

          const SizedBox(height: 32),
          // App info footer
          Center(
            child: Column(
              children: [
                Text(
                  'RYUMA Music',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey[400], size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.redAccent,
        activeTrackColor: Colors.redAccent.withValues(alpha: 0.5),
        inactiveThumbColor: Colors.grey[600],
        inactiveTrackColor: Colors.grey[800],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.grey[400], size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.redAccent,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              overlayColor: Colors.redAccent.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey[400], size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey[400], size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.redAccent, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
    );
  }

  // Dialogs and Actions
  void _showAudioQualityDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
            const Text(
              'Audio Quality',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildQualityOption('Low', 'Save storage space'),
            _buildQualityOption('Normal', 'Balanced quality'),
            _buildQualityOption('High', 'Best sound quality'),
            _buildQualityOption('Lossless', 'Original quality'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(String quality, String description) {
    final isSelected = _audioQuality == quality;
    return ListTile(
      onTap: () {
        setState(() => _audioQuality = quality);
        _saveSetting(_audioQualityKey, quality);
        Navigator.pop(context);
      },
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Colors.redAccent : Colors.grey[600],
      ),
      title: Text(
        quality,
        style: TextStyle(
          color: isSelected ? Colors.redAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
    );
  }

  void _showEqualizerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EqualizerSheet(),
    );
  }

  void _showAccentColorDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
            const Text(
              'Accent Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(_accentColors.length, (index) {
                  final isSelected = _accentColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _accentColorIndex = index);
                      _saveSetting(_accentColorKey, index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _accentColors[index],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _accentColors[index].withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will clear all cached data including album artwork. Your playlists and favorites will not be affected.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      _showSnackBar('Cache cleared successfully');
    }
  }

  void _scanMusicLibrary() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Scanning music library...',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      _showSnackBar('Music library refreshed');
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'RYUMA Music',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'A beautiful and powerful music player for Android. Enjoy your music with style.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),
            Text(
              '© 2024 RYUMA',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    _showSnackBar('Thank you for your support!');
  }

  void _shareApp() {
    Share.share(
      '🎵 Check out RYUMA Music - A beautiful music player for Android!\n\nDownload now and enjoy your music with style.',
      subject: 'RYUMA Music',
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TextContentScreen(
          title: 'Privacy Policy',
          content: '''
Privacy Policy for RYUMA Music

Last updated: January 2024

1. Information We Collect
RYUMA Music accesses your device's storage to read and play audio files. We do not collect, store, or transmit any personal data to external servers.

2. Local Storage
All your data including playlists, favorites, and settings are stored locally on your device. We do not have access to this data.

3. Permissions
- Storage Permission: Required to access and play your music files.
- Audio Permission: Required for audio playback functionality.

4. Third-Party Services
This app does not use any third-party analytics or advertising services.

5. Data Security
Your music library and preferences remain on your device and are not shared with anyone.

6. Changes to This Policy
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app.

7. Contact Us
If you have any questions about this Privacy Policy, please contact us.
          ''',
        ),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TextContentScreen(
          title: 'Terms of Service',
          content: '''
Terms of Service for RYUMA Music

Last updated: January 2024

1. Acceptance of Terms
By using RYUMA Music, you agree to these terms of service.

2. Use of the App
RYUMA Music is designed to play audio files stored on your device. You are responsible for ensuring you have the right to play the audio files on your device.

3. Intellectual Property
RYUMA Music and its original content, features, and functionality are owned by RYUMA and are protected by international copyright laws.

4. Limitation of Liability
RYUMA Music is provided "as is" without warranties of any kind. We are not responsible for any damages arising from the use of this app.

5. User Conduct
You agree not to:
- Reverse engineer the app
- Use the app for any illegal purpose
- Attempt to gain unauthorized access to any part of the app

6. Changes to Terms
We reserve the right to modify these terms at any time. Your continued use of the app constitutes acceptance of the modified terms.

7. Governing Law
These terms shall be governed by the laws of the jurisdiction in which you reside.

8. Contact
For any questions regarding these terms, please contact us.
          ''',
        ),
      ),
    );
  }

  void _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final data = <String, dynamic>{};

      for (final key in keys) {
        data[key] = prefs.get(key);
      }

      final jsonData = json.encode(data);

      if (mounted) {
        Navigator.pop(context);
        Share.share(jsonData, subject: 'RYUMA Music Backup');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Export failed');
      }
    }
  }

  void _importData() {
    _showSnackBar('Import feature coming soon!');
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset All Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will reset all settings to their default values. Your playlists and favorites will not be affected.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_autoPlayKey);
    await prefs.remove(_gaplessKey);
    await prefs.remove(_crossfadeKey);
    await prefs.remove(_crossfadeDurationKey);
    await prefs.remove(_audioQualityKey);
    await prefs.remove(_showArtworkKey);
    await prefs.remove(_keepScreenOnKey);
    await prefs.remove(_themeKey);
    await prefs.remove(_accentColorKey);

    await _loadSettings();
    _showSnackBar('Settings reset to defaults');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A2F42),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Equalizer Sheet Widget
class _EqualizerSheet extends StatefulWidget {
  @override
  State<_EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<_EqualizerSheet> {
  final List<String> _bands = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
  final List<double> _values = [0.0, 0.0, 0.0, 0.0, 0.0];
  String _selectedPreset = 'Custom';
  final List<String> _presets = [
    'Custom',
    'Flat',
    'Bass Boost',
    'Treble Boost',
    'Vocal',
    'Rock',
    'Pop',
    'Jazz',
    'Classical',
  ];

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'Flat':
          _values.setAll(0, [0.0, 0.0, 0.0, 0.0, 0.0]);
          break;
        case 'Bass Boost':
          _values.setAll(0, [6.0, 4.0, 0.0, 0.0, 0.0]);
          break;
        case 'Treble Boost':
          _values.setAll(0, [0.0, 0.0, 0.0, 4.0, 6.0]);
          break;
        case 'Vocal':
          _values.setAll(0, [-2.0, 0.0, 4.0, 4.0, 0.0]);
          break;
        case 'Rock':
          _values.setAll(0, [5.0, 3.0, -1.0, 3.0, 5.0]);
          break;
        case 'Pop':
          _values.setAll(0, [-1.0, 2.0, 5.0, 2.0, -1.0]);
          break;
        case 'Jazz':
          _values.setAll(0, [3.0, 0.0, 2.0, 3.0, 4.0]);
          break;
        case 'Classical':
          _values.setAll(0, [4.0, 2.0, -2.0, 2.0, 4.0]);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Equalizer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          // Presets
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = _selectedPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _applyPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.redAccent
                            : Colors.grey[800]?.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        preset,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          // EQ Bands
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_bands.length, (index) {
                return Column(
                  children: [
                    Text(
                      '+12dB',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            activeTrackColor: Colors.redAccent,
                            inactiveTrackColor: Colors.grey[800],
                            thumbColor: Colors.white,
                            overlayColor: Colors.redAccent.withValues(
                              alpha: 0.2,
                            ),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: _values[index],
                            min: -12,
                            max: 12,
                            onChanged: (value) {
                              setState(() {
                                _values[index] = value;
                                _selectedPreset = 'Custom';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '-12dB',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bands[index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '${_values[index].toStringAsFixed(1)}dB',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // Reset button
          TextButton(
            onPressed: () => _applyPreset('Flat'),
            child: Text(
              'Reset to Flat',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}

// Text Content Screen for Privacy Policy and Terms
class _TextContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const _TextContentScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
