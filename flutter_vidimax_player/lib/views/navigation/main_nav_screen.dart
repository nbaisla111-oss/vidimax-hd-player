import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';
import '../music/music_screen.dart';
import '../music/mini_music_player.dart';
import '../vault/vault_screen.dart';
import '../tools/tools_screen.dart';
import '../settings/settings_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MusicScreen(),
    VaultScreen(),
    ToolsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Global Mini Music Player when on non-music tabs
          if (_currentIndex != 1) const MiniMusicPlayer(),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.surfaceDark
                  : AppTheme.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.borderDark
                      : AppTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.video_collection_rounded, 'Videos'),
                    _buildNavItem(1, Icons.music_note_rounded, 'Music'),
                    _buildNavItem(2, Icons.lock_person_rounded, 'Vault'),
                    _buildNavItem(3, Icons.build_circle_rounded, 'Tools'),
                    _buildNavItem(4, Icons.settings_rounded, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryViolet
                  : (isDark ? AppTheme.textMutedDark : AppTheme.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryViolet
                    : (isDark ? AppTheme.textMutedDark : AppTheme.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
