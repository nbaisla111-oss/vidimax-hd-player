import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/audio_artwork_widget.dart';

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
        final isDark = AppTheme.isDark(context);

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.54 : 0.18),
                blurRadius: 20,
                offset: const Offset(0, -6),
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
                    color: isDark ? Colors.white24 : AppTheme.borderLight,
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
                        color: AppTheme.accent(context).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.queue_music_rounded, color: AppTheme.accent(context), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Playing Queue',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${playlist.length} Songs in list • Tap to play directly',
                            style: TextStyle(
                              color: AppTheme.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary(context)),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Divider(color: AppTheme.border(context), height: 1),

              // Queue List
              Expanded(
                child: playlist.isEmpty
                    ? Center(
                        child: Text(
                          'No songs in playing queue',
                          style: TextStyle(color: AppTheme.textMuted(context)),
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
                                  ? AppTheme.accent(context).withOpacity(isDark ? 0.14 : 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: isCurrent
                                  ? Border.all(color: AppTheme.accent(context).withOpacity(0.6), width: 1.2)
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              leading: AudioArtworkWidget(
                                audioPath: song.path,
                                size: 42,
                                borderRadius: BorderRadius.circular(10),
                                isCurrent: isCurrent,
                                isPlaying: musicCtrl.isPlaying,
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${song.artist} • ${song.formattedDuration}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppTheme.textSecondary(context)
                                      : AppTheme.textMuted(context),
                                  fontSize: 11,
                                ),
                              ),
                              trailing: isCurrent
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent(context),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'PLAYING',
                                        style: TextStyle(
                                          color: AppTheme.onAccent(context),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.play_circle_outline_rounded,
                                        color: AppTheme.textMuted(context),
                                        size: 24,
                                      ),
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
