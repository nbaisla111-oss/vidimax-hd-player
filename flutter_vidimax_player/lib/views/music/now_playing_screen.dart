import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/audio_artwork_widget.dart';
import 'music_queue_bottom_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    final musicCtrl = Provider.of<MusicController>(context, listen: false);
    if (musicCtrl.isPlaying) {
      _rotationCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicCtrl = Provider.of<MusicController>(context);
    final song = musicCtrl.currentSong;

    if (musicCtrl.isPlaying) {
      if (!_rotationCtrl.isAnimating) {
        _rotationCtrl.repeat();
      }
    } else {
      if (_rotationCtrl.isAnimating) {
        _rotationCtrl.stop();
      }
    }

    final isDark = AppTheme.isDark(context);

    if (song == null) {
      return Scaffold(
        backgroundColor: AppTheme.bg(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('No song selected', style: TextStyle(color: AppTheme.textSecondary(context))),
        ),
      );
    }

    final posMs = musicCtrl.position.inMilliseconds.toDouble();
    final durMs = musicCtrl.duration.inMilliseconds.toDouble();
    final maxMs = durMs > 0 ? durMs : 1.0;
    final currentMs = posMs.clamp(0.0, maxMs);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF18181B),
                    AppTheme.backgroundDark,
                    const Color(0xFF000000),
                  ]
                : [
                    const Color(0xFFE4E4E7),
                    AppTheme.backgroundLight,
                    const Color(0xFFFFFFFF),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                // Top App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary(context), size: 32),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Collapse Player',
                    ),
                    Column(
                      children: [
                        Text(
                          'PLAYING FROM PLAYLIST',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.folder,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.queue_music_rounded, color: AppTheme.accent(context), size: 24),
                          onPressed: () => MusicQueueBottomSheet.show(context),
                          tooltip: 'Playing Queue',
                        ),
                        IconButton(
                          icon: Icon(Icons.share_rounded, color: AppTheme.textSecondary(context), size: 22),
                          onPressed: () {
                            if (!song.path.startsWith('http')) {
                              Share.shareXFiles([XFile(song.path)], text: 'Listening to ${song.title}');
                            }
                          },
                          tooltip: 'Share Track',
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(flex: 1),

                // Center Animated Vinyl / Album Art
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Glow
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.14 : 0.18),
                              blurRadius: 48,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      // Rotating Vinyl Disk
                      AnimatedBuilder(
                        animation: _rotationCtrl,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationCtrl.value * 2 * math.pi,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFF27272A),
                                Color(0xFF09090B),
                                Color(0xFF3F3F46),
                                Color(0xFF09090B),
                              ],
                            ),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black26,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 196,
                              height: 196,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.black26,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: AudioArtworkWidget(
                                audioPath: song.path,
                                size: 192,
                                isCircle: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),

                // Title & Favorite Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: song.isFavorite ? Colors.redAccent : AppTheme.textMuted(context),
                        size: 28,
                      ),
                      onPressed: () => musicCtrl.toggleFavorite(song),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Scrubber / Progress Slider
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.accent(context),
                        inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                        thumbColor: AppTheme.accent(context),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        trackHeight: 4,
                        overlayColor: AppTheme.accent(context).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: currentMs,
                        min: 0.0,
                        max: maxMs,
                        onChanged: (val) {
                          musicCtrl.seekTo(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(musicCtrl.position),
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                          ),
                          Text(
                            _formatDuration(musicCtrl.duration),
                            style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Player Controls (Shuffle, Prev, Play/Pause, Next, Loop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: musicCtrl.isShuffle ? AppTheme.accent(context) : AppTheme.textMuted(context),
                        size: 24,
                      ),
                      onPressed: () => musicCtrl.toggleShuffle(),
                      tooltip: 'Shuffle',
                    ),

                    // Previous
                    IconButton(
                      iconSize: 38,
                      icon: Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary(context)),
                      onPressed: () => musicCtrl.playPrevious(),
                      tooltip: 'Previous Track',
                    ),

                    // Play / Pause Big Button
                    GestureDetector(
                      onTap: () => musicCtrl.togglePlayPause(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.accent(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          musicCtrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppTheme.onAccent(context),
                          size: 40,
                        ),
                      ),
                    ),

                    // Next
                    IconButton(
                      iconSize: 38,
                      icon: Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary(context)),
                      onPressed: () => musicCtrl.playNext(),
                      tooltip: 'Next Track',
                    ),

                    // Repeat / Loop
                    IconButton(
                      icon: Icon(
                        musicCtrl.loopMode == MusicLoopMode.single
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: musicCtrl.loopMode == MusicLoopMode.off
                            ? AppTheme.textMuted(context)
                            : AppTheme.accent(context),
                        size: 24,
                      ),
                      onPressed: () => musicCtrl.toggleLoopMode(),
                      tooltip: 'Repeat Mode',
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick Queue Opener Pill Button
                InkWell(
                  onTap: () => MusicQueueBottomSheet.show(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.queue_music_rounded, size: 18, color: AppTheme.accent(context)),
                        const SizedBox(width: 8),
                        Text(
                          'Queue (${musicCtrl.playlist.length} Songs)',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppTheme.accent(context)),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
