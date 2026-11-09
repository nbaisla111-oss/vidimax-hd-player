import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';

class CustomVideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final bool isVaultPlayback;

  const CustomVideoPlayerScreen({
    super.key,
    required this.video,
    this.isVaultPlayback = false,
  });

  @override
  State<CustomVideoPlayerScreen> createState() => _CustomVideoPlayerScreenState();
}

class _CustomVideoPlayerScreenState extends State<CustomVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLocked = false;
  double _volume = 1.0;
  double _brightness = 0.5;
  double _playbackSpeed = 1.0;
  BoxFit _aspectRatioFit = BoxFit.contain;
  String _aspectRatioLabel = 'Fit';
  Timer? _hideControlsTimer;

  // Gesture indicators
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.video.path.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.path));
    } else {
      _controller = VideoPlayerController.file(File(widget.video.path));
    }

    try {
      await _controller.initialize();
      _controller.addListener(_videoListener);
      setState(() => _isInitialized = true);
      _controller.play();
      _startHideTimer();
    } catch (e) {
      debugPrint("Error initializing player: $e");
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying && !_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _skip10Seconds(bool forward) {
    if (!_isInitialized) return;
    final current = _controller.value.position;
    final target = forward
        ? current + const Duration(seconds: 10)
        : current - const Duration(seconds: 10);
    _controller.seekTo(target);
    _startHideTimer();
  }

  void _toggleAspectRatio() {
    setState(() {
      if (_aspectRatioFit == BoxFit.contain) {
        _aspectRatioFit = BoxFit.cover;
        _aspectRatioLabel = 'Fill';
      } else if (_aspectRatioFit == BoxFit.cover) {
        _aspectRatioFit = BoxFit.fill;
        _aspectRatioLabel = 'Stretch';
      } else {
        _aspectRatioFit = BoxFit.contain;
        _aspectRatioLabel = 'Fit';
      }
    });
  }

  void _changePlaybackSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _indicatorTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 2) {
              _skip10Seconds(false);
            } else {
              _skip10Seconds(true);
            }
          },
          onVerticalDragUpdate: (details) {
            if (_isLocked) return;
            final screenWidth = MediaQuery.of(context).size.width;
            final delta = -details.primaryDelta! / 200;

            if (details.globalPosition.dx < screenWidth / 2) {
              // Left half: Brightness
              setState(() {
                _brightness = (_brightness + delta).clamp(0.0, 1.0);
                _showBrightnessIndicator = true;
              });
              _resetIndicatorTimer();
            } else {
              // Right half: Volume
              setState(() {
                _volume = (_volume + delta).clamp(0.0, 1.0);
                _controller.setVolume(_volume);
                _showVolumeIndicator = true;
              });
              _resetIndicatorTimer();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Surface
              Center(
                child: _isInitialized
                    ? FittedBox(
                        fit: _aspectRatioFit,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const CircularProgressIndicator(color: AppTheme.primaryViolet),
              ),

              // Brightness / Volume on-screen indicators
              if (_showBrightnessIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.brightness_medium_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          '${(_brightness * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_showVolumeIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: AppTheme.secondaryCyan,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(_volume * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // Screen Lock Overlay (always visible if locked)
              if (_isLocked)
                Positioned(
                  top: 24,
                  left: 24,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    onPressed: () {
                      setState(() {
                        _isLocked = false;
                        _showControls = true;
                      });
                      _startHideTimer();
                    },
                    child: const Icon(Icons.lock_rounded, color: AppTheme.primaryViolet),
                  ),
                ),

              // Full Video Controls (When not locked and visible)
              if (_showControls && !_isLocked)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTopBar(),
                        _buildCenterPlayControls(),
                        _buildBottomControls(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetIndicatorTimer() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showBrightnessIndicator = false;
          _showVolumeIndicator = false;
        });
      }
    });
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          // Aspect Ratio Button
          TextButton(
            onPressed: _toggleAspectRatio,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _aspectRatioLabel,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          // Speed Button
          TextButton(
            onPressed: _changePlaybackSpeed,
            child: Text(
              '${_playbackSpeed}x',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          // Lock Button
          IconButton(
            icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLocked = true;
                _showControls = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 44,
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
          onPressed: () => _skip10Seconds(false),
        ),
        const SizedBox(width: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryViolet.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: IconButton(
            iconSize: 36,
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
              _startHideTimer();
            },
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          iconSize: 44,
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
          onPressed: () => _skip10Seconds(true),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryViolet,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryViolet,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (val) {
                      _controller.seekTo(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
