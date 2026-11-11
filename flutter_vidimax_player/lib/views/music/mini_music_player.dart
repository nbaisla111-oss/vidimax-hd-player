import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../utils/app_theme.dart';
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
            color: const Color(0xFF1E1B4B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
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
                    // Album badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryViolet, AppTheme.secondaryCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMutedDark,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Previous Button
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 24),
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
                        color: AppTheme.primaryViolet,
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
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 24),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Next Track',
                      onPressed: () => musicCtrl.playNext(),
                    ),
                    const SizedBox(width: 6),

                    // Queue List Button
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded, color: AppTheme.secondaryCyan, size: 22),
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
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
