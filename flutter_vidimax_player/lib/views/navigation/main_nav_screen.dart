import 'dart:math' as math;
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
              color: isDark ? const Color(0xFF0E0E11) : const Color(0xFFFFFFFF),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFCBD5E1),
                  width: 1.4,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.65)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: 18,
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
                    _buildNavItem(0, Icons.video_collection_rounded, 'Videos'),
                    _buildNavItem(1, Icons.music_note_rounded, 'Music'),
                    _buildStatusNavItem(2, 'Status'),
                    _buildNavItem(3, Icons.handyman_rounded, 'Tools'),
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
    final isDark = AppTheme.isDark(context);

    // Rich, bold high-contrast colors ("gadha") so tabs never look faded
    final selectedBg = isDark ? Colors.white : const Color(0xFF09090B);
    final selectedFg = isDark ? const Color(0xFF09090B) : Colors.white;
    final unselectedFg = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF09090B);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? selectedBg
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSelected ? 24 : 23,
                color: isSelected ? selectedFg : unselectedFg,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? selectedFg : unselectedFg,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom WhatsApp-style Status Saver tab icon:
  /// Segmented Status ring + bold downward save arrow (no trademark/copyright copy)
  Widget _buildStatusNavItem(int index, String label) {
    final isSelected = _currentIndex == index;
    final isDark = AppTheme.isDark(context);

    final selectedBg = isDark ? Colors.white : const Color(0xFF09090B);
    final selectedFg = isDark ? const Color(0xFF09090B) : Colors.white;
    final unselectedFg = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF09090B);

    // Distinct Status ring accent (crisp emerald green on status ring so users spot Status Saver immediately)
    final ringColor = isSelected
        ? (isDark ? const Color(0xFF059669) : const Color(0xFF25D366))
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));
    final arrowColor = isSelected ? selectedFg : unselectedFg;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? selectedBg
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(
                  painter: _StatusSaverRingPainter(
                    ringColor: ringColor,
                    arrowColor: arrowColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? selectedFg : unselectedFg,
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
