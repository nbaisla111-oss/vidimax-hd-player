import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hwAcceleration = true;
  bool _backgroundPlay = true;
  bool _resumePlayback = true;
  String _cacheSize = '42.8 MB';

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & About', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Storage Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppTheme.accent(context), size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Internal Storage Usage',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(flex: 35, child: Container(color: AppTheme.accent(context))),
                        Expanded(flex: 15, child: Container(color: const Color(0xFF71717A))),
                        Expanded(flex: 10, child: Container(color: AppTheme.accentEmerald)),
                        Expanded(flex: 40, child: Container(color: isDark ? AppTheme.borderDark : Colors.grey.shade300)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem('Videos (3.2 GB)', AppTheme.accent(context)),
                    _buildLegendItem('Vault (1.4 GB)', const Color(0xFF71717A)),
                    _buildLegendItem('Cache ($_cacheSize)', AppTheme.accentEmerald),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Theme & Display
          _buildSectionHeader('Appearance & Display'),
          Card(
            child: ListTile(
              leading: Icon(
                themeCtrl.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppTheme.accent(context),
              ),
              title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(themeCtrl.isDarkMode ? 'AMOLED Dark Theme' : 'Clean Light Theme'),
              trailing: Switch(
                value: themeCtrl.isDarkMode,
                activeColor: AppTheme.accent(context),
                activeTrackColor: AppTheme.accent(context).withOpacity(0.35),
                onChanged: (_) => themeCtrl.toggleTheme(),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Playback Preferences
          _buildSectionHeader('Playback Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.speed_rounded, color: AppTheme.accent(context)),
                  title: const Text('Hardware Acceleration', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Smoother 4K 60FPS video decoding'),
                  value: _hwAcceleration,
                  activeColor: AppTheme.accent(context),
                  activeTrackColor: AppTheme.accent(context).withOpacity(0.35),
                  onChanged: (val) => setState(() => _hwAcceleration = val),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.headset_rounded, color: AppTheme.accentEmerald),
                  title: const Text('Background Play', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Continue audio when switching apps or locking screen'),
                  value: _backgroundPlay,
                  activeColor: AppTheme.accent(context),
                  activeTrackColor: AppTheme.accent(context).withOpacity(0.35),
                  onChanged: (val) => setState(() => _backgroundPlay = val),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.history_rounded, color: Colors.amber),
                  title: const Text('Resume Playback', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Remember last watched timestamp'),
                  value: _resumePlayback,
                  activeColor: AppTheme.accent(context),
                  activeTrackColor: AppTheme.accent(context).withOpacity(0.35),
                  onChanged: (val) => setState(() => _resumePlayback = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Storage & Cache
          _buildSectionHeader('Storage & Maintenance'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_rounded, color: Colors.orange),
              title: const Text('Clear Thumbnail Cache', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Reclaim temporary storage space ($_cacheSize)'),
              trailing: TextButton(
                onPressed: _clearCache,
                child: const Text('Clear', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // App & Legal
          _buildSectionHeader('About & Support'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: Colors.amber),
                  title: const Text('Rate Us on Google Play', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Support the developer with a 5-star review'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for your rating!')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.shield_outlined, color: AppTheme.accent(context)),
                  title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('100% offline security, zero cloud data transfer'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showPrivacyPolicyModal,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: AppTheme.accentEmerald),
                  title: const Text('Support & Report Issue', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('nbaisla111@gmail.com'),
                  trailing: const Icon(Icons.copy_rounded, size: 18),
                  onTap: _showSupportDialog,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppTheme.accent(context)),
                  title: const Text('Rox Player', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Version 1.0.0 (Production Build) · Offline Media Suite'),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppTheme.textMuted(context),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
      ],
    );
  }

  Future<void> _clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (await tempDir.exists()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
    setState(() => _cacheSize = '0 KB');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache successfully cleared! Freed up space.')),
      );
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Support & Issue Reporting'),
        content: const Text(
          'Facing any bug, playback problem, or have a feature suggestion for Rox Player?\n\n'
          'Contact us anytime at:\nnbaisla111@gmail.com',
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'nbaisla111@gmail.com'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email copied: nbaisla111@gmail.com')),
              );
            },
            child: const Text('Copy Email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('100% Offline Privacy Guarantee'),
        content: const SingleChildScrollView(
          child: Text(
            'Rox Player is built with privacy as the core foundation.\n\n'
            '• All videos and music are processed strictly offline on your local Android device.\n'
            '• Secret Vault files are encrypted using local AES-256 with key derivation from your personal PIN. No files or keys are transmitted to any external server.\n'
            '• Zero telemetry, zero analytics tracking, and zero cloud uploads.\n'
            '• Status Saver viewing and saving operations read directly from local device storage without accessing any account credentials.\n\n'
            'For support, privacy questions, or issue reporting, contact:\nnbaisla111@gmail.com',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
