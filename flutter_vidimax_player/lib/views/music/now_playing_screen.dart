import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import '../../utils/app_theme.dart';

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

    if (song == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No song selected', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final posMs = musicCtrl.position.inMilliseconds.toDouble();
    final durMs = musicCtrl.duration.inMilliseconds.toDouble();
    final maxMs = durMs > 0 ? durMs : 1.0;
    final currentMs = posMs.clamp(0.0, maxMs);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E1035),
              AppTheme.backgroundDark,
              const Color(0xFF0F172A),
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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
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
                            color: AppTheme.primaryViolet.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.folder,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white70, size: 22),
                      onPressed: () {
                        if (!song.path.startsWith('http')) {
                          Share.shareXFiles([XFile(song.path)], text: 'Listening to ${song.title}');
                        }
                      },
                      tooltip: 'Share Track',
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
                              color: AppTheme.primaryViolet.withOpacity(0.35),
                              blurRadius: 50,
                              spreadRadius: 10,
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
                                Color(0xFF1E1B4B),
                                Color(0xFF0F172A),
                                Color(0xFF312E81),
                                Color(0xFF1E1B4B),
                              ],
                            ),
                            border: Border.all(color: Colors.white12, width: 3),
                          ),
                          child: Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryViolet, AppTheme.secondaryCyan],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 54),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMutedDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: song.isFavorite ? Colors.redAccent : Colors.white60,
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
                        activeTrackColor: AppTheme.primaryViolet,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        trackHeight: 4,
                        overlayColor: AppTheme.primaryViolet.withOpacity(0.2),
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
                            style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(musicCtrl.duration),
                            style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
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
                        color: musicCtrl.isShuffle ? AppTheme.primaryViolet : Colors.white38,
                        size: 24,
                      ),
                      onPressed: () => musicCtrl.toggleShuffle(),
                      tooltip: 'Shuffle',
                    ),

                    // Previous
                    IconButton(
                      iconSize: 38,
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
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
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryViolet, Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryViolet.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          musicCtrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    // Next
                    IconButton(
                      iconSize: 38,
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      onPressed: () => musicCtrl.playNext(),
                      tooltip: 'Next Track',
                    ),

                    // Repeat / Loop
                    IconButton(
                      icon: Icon(
                        musicCtrl.loopMode == MusicLoopMode.single
                            ? Icons.repeat_one_rounded
                            : (musicCtrl.loopMode == MusicLoopMode.all
                                ? Icons.repeat_rounded
                                : Icons.repeat_rounded),
                        color: musicCtrl.loopMode == MusicLoopMode.off
                            ? Colors.white38
                            : AppTheme.primaryViolet,
                        size: 24,
                      ),
                      onPressed: () => musicCtrl.toggleLoopMode(),
                      tooltip: 'Repeat Mode',
                    ),
                  ],
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
