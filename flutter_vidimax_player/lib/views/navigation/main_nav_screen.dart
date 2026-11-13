import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';
import '../music/music_screen.dart';
import '../music/mini_music_player.dart';
import '../status/status_saver_screen.dart';
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
    StatusSaverScreen(),
    ToolsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

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
              color: AppTheme.surface(context),
              border: Border(
                top: BorderSide(
                  color: AppTheme.border(context),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.45)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.video_collection_rounded, 'Videos', AppTheme.primaryViolet),
                    _buildNavItem(1, Icons.music_note_rounded, 'Music', AppTheme.primaryViolet),
                    _buildNavItem(2, Icons.chat_bubble_rounded, 'Status', AppTheme.accentEmerald),
                    _buildNavItem(3, Icons.handyman_rounded, 'Tools', AppTheme.secondaryCyan),
                    _buildNavItem(4, Icons.settings_rounded, 'Settings', AppTheme.primaryViolet),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeAccent) {
    final isSelected = _currentIndex == index;
    final isDark = AppTheme.isDark(context);
    final inactiveColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeAccent.withOpacity(isDark ? 0.22 : 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeAccent.withOpacity(0.55)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSelected ? 25 : 23,
                color: isSelected ? activeAccent : inactiveColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeAccent : inactiveColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
