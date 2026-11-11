import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import '../../utils/app_theme.dart';

class MusicQueueBottomSheet extends StatelessWidget {
  const MusicQueueBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MusicQueueBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicCtrl = Provider.of<MusicController>(context);
    final playlist = musicCtrl.playlist;
    final currentSong = musicCtrl.currentSong;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131127),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.queue_music_rounded, color: AppTheme.secondaryCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Playing Queue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${playlist.length} Songs in list • Tap to play directly',
                            style: const TextStyle(
                              color: AppTheme.textMutedDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Queue List
              Expanded(
                child: playlist.isEmpty
                    ? const Center(
                        child: Text(
                          'No songs in playing queue',
                          style: TextStyle(color: AppTheme.textMutedDark),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: playlist.length,
                        itemBuilder: (context, index) {
                          final song = playlist[index];
                          final isCurrent = currentSong?.id == song.id;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.primaryViolet.withOpacity(0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: isCurrent
                                  ? Border.all(color: AppTheme.primaryViolet.withOpacity(0.5), width: 1.2)
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              leading: SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: isCurrent
                                      ? Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryViolet,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryViolet.withOpacity(0.5),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            musicCtrl.isPlaying
                                                ? Icons.graphic_eq_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: AppTheme.textMutedDark,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.secondaryCyan : Colors.white,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${song.artist} • ${song.formattedDuration}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? Colors.white70 : AppTheme.textMutedDark,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: isCurrent
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryCyan.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PLAYING',
                                        style: TextStyle(
                                          color: AppTheme.secondaryCyan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.play_circle_outline_rounded,
                                          color: Colors.white38, size: 24),
                                      onPressed: () => musicCtrl.playSong(song, queue: playlist),
                                    ),
                              onTap: () {
                                musicCtrl.playSong(song, queue: playlist);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
