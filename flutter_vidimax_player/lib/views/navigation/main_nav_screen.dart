import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
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

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      Provider.of<MusicController>(context, listen: false).refreshIfNeeded();
    }
  }

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
              color: isDark ? const Color(0xFF0B0B0E) : const Color(0xFFFFFFFF),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF232329) : const Color(0xFFE4E4E7),
                  width: 0.9,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.55)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.video_collection_rounded, Icons.video_collection_outlined, 'Videos'),
                    _buildNavItem(1, Icons.music_note_rounded, Icons.music_note_outlined, 'Music'),
                    _buildStatusNavItem(2, 'Status'),
                    _buildNavItem(3, Icons.handyman_rounded, Icons.handyman_outlined, 'Tools'),
                    _buildNavItem(4, Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = AppTheme.isDark(context);

    final activeColor = isDark ? Colors.white : const Color(0xFF09090B);
    final inactiveColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF52525B);
    final pillBg = isSelected
        ? (isDark ? Colors.white.withOpacity(0.16) : const Color(0xFF09090B).withOpacity(0.10))
        : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom WhatsApp-style Status Saver tab icon inside sleek unified nav item:
  /// Segmented Status ring + crisp downward save arrow (no boxy container border)
  Widget _buildStatusNavItem(int index, String label) {
    final isSelected = _currentIndex == index;
    final isDark = AppTheme.isDark(context);

    final activeColor = isDark ? Colors.white : const Color(0xFF09090B);
    final inactiveColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF52525B);
    final pillBg = isSelected
        ? (isDark ? Colors.white.withOpacity(0.16) : const Color(0xFF09090B).withOpacity(0.10))
        : Colors.transparent;

    final ringColor = isSelected
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669));
    final arrowColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(
                      painter: _StatusSaverRingPainter(
                        ringColor: ringColor,
                        arrowColor: arrowColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
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

class _StatusSaverRingPainter extends CustomPainter {
  final Color ringColor;
  final Color arrowColor;

  const _StatusSaverRingPainter({
    required this.ringColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 2.0;

    // 3 segmented status arcs like Status updates ring
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const segments = 3;
    const gapRadians = 0.42;
    final sweep = (2 * math.pi - (segments * gapRadians)) / segments;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < segments; i++) {
      final start = -math.pi / 2 + i * (sweep + gapRadians);
      canvas.drawArc(rect, start, sweep, false, ringPaint);
    }

    // Crisp downward download / save arrow inside the status ring
    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shaftTop = Offset(center.dx, center.dy - 4.2);
    final shaftBottom = Offset(center.dx, center.dy + 3.4);
    canvas.drawLine(shaftTop, shaftBottom, arrowPaint);

    final headPath = Path()
      ..moveTo(center.dx - 3.6, center.dy + 0.2)
      ..lineTo(center.dx, center.dy + 4.0)
      ..lineTo(center.dx + 3.6, center.dy + 0.2);
    canvas.drawPath(headPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _StatusSaverRingPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor || oldDelegate.arrowColor != arrowColor;
  }
}
