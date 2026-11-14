import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/audio_artwork_widget.dart';
import 'music_queue_bottom_sheet.dart';
import 'now_playing_screen.dart';

class MiniMusicPlayer extends StatelessWidget {
  const MiniMusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final musicCtrl = Provider.of<MusicController>(context);
    final song = musicCtrl.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final posMs = musicCtrl.position.inMilliseconds.toDouble();
    final durMs = musicCtrl.duration.inMilliseconds.toDouble();
    final progress = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.isDark(context)
                ? const Color(0xFF16161A)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border(context),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppTheme.isDark(context) ? 0.5 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Album artwork badge
                    AudioArtworkWidget(
                      audioPath: song.path,
                      size: 42,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 12),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textMuted(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Previous Button
                    IconButton(
                      icon: Icon(Icons.skip_previous_rounded, color: AppTheme.textSecondary(context), size: 24),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Previous Track',
                      onPressed: () => musicCtrl.playPrevious(),
                    ),
                    const SizedBox(width: 4),

                    // Play/Pause Button
                    IconButton(
                      icon: Icon(
                        musicCtrl.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: AppTheme.accent(context),
                        size: 34,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: musicCtrl.isPlaying ? 'Pause' : 'Play',
                      onPressed: () => musicCtrl.togglePlayPause(),
                    ),
                    const SizedBox(width: 4),

                    // Next Button
                    IconButton(
                      icon: Icon(Icons.skip_next_rounded, color: AppTheme.textSecondary(context), size: 24),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Next Track',
                      onPressed: () => musicCtrl.playNext(),
                    ),
                    const SizedBox(width: 6),

                    // Queue List Button
                    IconButton(
                      icon: Icon(Icons.queue_music_rounded, color: AppTheme.accent(context), size: 22),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Current Playlist Queue',
                      onPressed: () => MusicQueueBottomSheet.show(context),
                    ),
                  ],
                ),
              ),

              // Thin Bottom Progress Bar
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: AppTheme.isDark(context)
                      ? Colors.white12
                      : AppTheme.borderLight.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
