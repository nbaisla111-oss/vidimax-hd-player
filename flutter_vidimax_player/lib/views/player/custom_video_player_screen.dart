import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';

class CustomVideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel>? playlist;
  final int initialIndex;
  final bool isVaultPlayback;

  const CustomVideoPlayerScreen({
    super.key,
    required this.video,
    this.playlist,
    this.initialIndex = 0,
    this.isVaultPlayback = false,
  });

  @override
  State<CustomVideoPlayerScreen> createState() => _CustomVideoPlayerScreenState();
}

class _CustomVideoPlayerScreenState extends State<CustomVideoPlayerScreen> {
  static const MethodChannel _systemChannel = MethodChannel('com.vidimax.player/system_controls');

  late VideoPlayerController _controller;
  late int _currentIndex;
  late VideoModel _currentVideo;
  late List<VideoModel> _playlist;

  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isLandscape = false;
  bool _autoPlayNext = true;
  bool _is2xActive = false;

  double _volume = 1.0;
  double _brightness = 0.65; // Initial screen brightness (65%)
  double _playbackSpeed = 1.0;

  Timer? _hideControlsTimer;
  Timer? _indicatorTimer;
  Timer? _seekRippleTimer;

  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  bool _showSeekRipple = false;
  bool _seekRippleForward = true;
  String _toastMessage = '';
  bool _showToast = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _playlist = widget.playlist ?? [widget.video];
    _currentIndex = widget.initialIndex;

    _initializeVideo();
    _applyHardwareBrightness(_brightness);
  }

  Future<void> _initializeVideo() async {
    _isInitialized = false;
    setState(() {});

    final videoOptions = VideoPlayerOptions(
      mixWithOthers: false,
      allowBackgroundPlayback: false,
    );

    try {
      if (_currentVideo.path.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(_currentVideo.path),
          videoPlayerOptions: videoOptions,
        );
      } else {
        _controller = VideoPlayerController.file(
          File(_currentVideo.path),
          videoPlayerOptions: videoOptions,
        );
      }

      await _controller.initialize();
      _controller.addListener(_videoListener);
      _controller.setVolume(_volume);
      _controller.setPlaybackSpeed(_playbackSpeed);

      if (mounted) {
        setState(() => _isInitialized = true);
        await _controller.play();
        _startHideTimer();
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      try {
        _controller = _currentVideo.path.startsWith('http')
            ? VideoPlayerController.networkUrl(Uri.parse(_currentVideo.path))
            : VideoPlayerController.file(File(_currentVideo.path));
        await _controller.initialize();
        _controller.addListener(_videoListener);
        if (mounted) {
          setState(() => _isInitialized = true);
          await _controller.play();
          _startHideTimer();
        }
      } catch (retryErr) {
        debugPrint("Retry video load error: $retryErr");
      }
    }
  }

  void _videoListener() {
    if (!mounted || !_isInitialized) return;

    // Check Auto-play next video when playback ends
    if (_controller.value.position >= _controller.value.duration &&
        _controller.value.duration > const Duration(seconds: 1)) {
      if (_autoPlayNext && _hasAvailableNext()) {
        _playNextVideo();
      }
    }

    setState(() {});
  }

  bool _hasAvailableNext() => _currentIndex < _playlist.length - 1;
  bool _hasAvailablePrevious() => _currentIndex > 0;

  void _playNextVideo() {
    if (!_hasAvailableNext()) return;
    _changeVideoTo(_currentIndex + 1);
  }

  void _playPreviousVideo() {
    if (!_hasAvailablePrevious()) return;
    _changeVideoTo(_currentIndex - 1);
  }

  Future<void> _changeVideoTo(int newIndex) async {
    if (newIndex < 0 || newIndex >= _playlist.length) return;
    _hideControlsTimer?.cancel();
    _controller.removeListener(_videoListener);
    await _controller.pause();
    await _controller.dispose();

    setState(() {
      _currentIndex = newIndex;
      _currentVideo = _playlist[_currentIndex];
    });

    await _initializeVideo();
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

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _skipSeconds(bool forward) {
    if (!_isInitialized) return;
    final current = _controller.value.position;
    final target = forward
        ? current + const Duration(seconds: 10)
        : current - const Duration(seconds: 10);
    _controller.seekTo(target);

    setState(() {
      _showSeekRipple = true;
      _seekRippleForward = forward;
    });

    _seekRippleTimer?.cancel();
    _seekRippleTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showSeekRipple = false);
    });

    _startHideTimer();
  }

  void _showToastNotification(String message) {
    setState(() {
      _toastMessage = message;
      _showToast = true;
    });

    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  Future<void> _applyHardwareBrightness(double brightness) async {
    try {
      await _systemChannel.invokeMethod('setScreenBrightness', {
        'brightness': brightness.clamp(0.02, 1.0),
      });
    } catch (_) {}
  }

  Future<void> _resetHardwareBrightness() async {
    try {
      await _systemChannel.invokeMethod('resetScreenBrightness');
    } catch (_) {}
  }

  void _onVerticalDrag(DragUpdateDetails details) {
    if (_isLocked) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final delta = -details.primaryDelta! / 250;

    if (details.globalPosition.dx < screenWidth / 2) {
      // Left side: Screen Brightness
      setState(() {
        _brightness = (_brightness + delta).clamp(0.02, 1.0);
        _showBrightnessIndicator = true;
      });
      _applyHardwareBrightness(_brightness);
      _resetIndicatorTimer();
    } else {
      // Right side: Audio Volume
      setState(() {
        _volume = (_volume + delta).clamp(0.0, 1.0);
        _controller.setVolume(_volume);
        _showVolumeIndicator = true;
      });
      _resetIndicatorTimer();
    }
  }

  void _resetIndicatorTimer() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showBrightnessIndicator = false;
          _showVolumeIndicator = false;
        });
      }
    });
  }

  void _enable2xSpeed() {
    if (!_isInitialized || _isLocked) return;
    HapticFeedback.mediumImpact();
    setState(() => _is2xActive = true);
    _controller.setPlaybackSpeed(2.0);
  }

  void _restoreNormalSpeed() {
    if (!_isInitialized || _isLocked) return;
    setState(() => _is2xActive = false);
    _controller.setPlaybackSpeed(_playbackSpeed);
  }

  void _openSpeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...speeds.map((s) {
                final isSelected = _playbackSpeed == s;
                return ListTile(
                  title: Text(
                    s == 1.0 ? '1.0x (Normal)' : '${s}x',
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryViolet : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primaryViolet) : null,
                  onTap: () {
                    setState(() {
                      _playbackSpeed = s;
                      _controller.setPlaybackSpeed(_playbackSpeed);
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _indicatorTimer?.cancel();
    _seekRippleTimer?.cancel();
    _toastTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _resetHardwareBrightness();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_isLandscape,
        bottom: !_isLandscape,
        child: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 2) {
              _skipSeconds(false);
            } else {
              _skipSeconds(true);
            }
          },
          onLongPressStart: (_) => _enable2xSpeed(),
          onLongPressEnd: (_) => _restoreNormalSpeed(),
          onVerticalDragUpdate: _onVerticalDrag,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Surface Playing in Authentic Natural Aspect Ratio
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.5,
                panEnabled: true,
                scaleEnabled: true,
                child: _buildVideoSurface(screenSize),
              ),

              // 2. Hardware/Software Integrated Brightness Dimmer Overlay
              IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity((1.0 - _brightness).clamp(0.0, 0.85) * 0.7),
                ),
              ),

              // 3. 2X Speed YouTube-Style Glowing Badge
              if (_is2xActive)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.secondaryCyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryCyan.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_forward_rounded, color: AppTheme.secondaryCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '2X SPEED ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. HUD Toast Notification (Auto-Play Toggle, Statuses)
              if (_showToast)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryViolet, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryViolet.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        _toastMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),

              // 5. Brightness HUD Indicator
              if (_showBrightnessIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.brightness_6_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brightness ${(_brightness * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 100,
                              height: 4,
                              child: LinearProgressIndicator(
                                value: _brightness,
                                color: Colors.amber,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 6. Volume HUD Indicator
              if (_showVolumeIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.secondaryCyan.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: AppTheme.secondaryCyan,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volume ${(_volume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 100,
                              height: 4,
                              child: LinearProgressIndicator(
                                value: _volume,
                                color: AppTheme.secondaryCyan,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 7. Double-Tap Seek Ripple Animation
              if (_showSeekRipple)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: _seekRippleForward ? null : 0,
                  right: _seekRippleForward ? 0 : null,
                  width: screenSize.width * 0.4,
                  child: Container(
                    color: Colors.white.withOpacity(0.08),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _seekRippleForward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _seekRippleForward ? '+10s' : '-10s',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 8. Lock Button when Screen is Locked
              if (_isLocked)
                Positioned(
                  top: 24,
                  left: 24,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.black.withOpacity(0.7),
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

              // 9. Full On-Screen Controls Overlay
              if (_showControls && !_isLocked)
                Container(
                  color: Colors.black.withOpacity(0.48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopBar(),
                      _buildCenterPlayControls(),
                      _buildBottomControls(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSurface(Size screenSize) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet));
    }

    final videoSize = _controller.value.size;
    final bool hasValidDimensions = videoSize.width > 0 && videoSize.height > 0;
    final double rawAspect = (hasValidDimensions && _controller.value.aspectRatio > 0)
        ? _controller.value.aspectRatio
        : (16 / 9);

    // Natural authentic video aspect ratio without any unwanted cropping, stretching or zoom
    return Center(
      child: AspectRatio(
        aspectRatio: rawAspect,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentVideo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (_playlist.length > 1)
                  Text(
                    '${_currentIndex + 1} of ${_playlist.length} videos',
                    style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
                  ),
              ],
            ),
          ),

          // Auto-Play Next Toggle Button (Tap once -> ON, Tap again -> OFF)
          InkWell(
            onTap: () {
              setState(() => _autoPlayNext = !_autoPlayNext);
              _showToastNotification(
                _autoPlayNext ? 'Auto-play Next: ON' : 'Auto-play Next: OFF',
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _autoPlayNext
                    ? AppTheme.accentEmerald.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _autoPlayNext ? AppTheme.accentEmerald : Colors.white24,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _autoPlayNext ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: _autoPlayNext ? AppTheme.accentEmerald : Colors.white60,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _autoPlayNext ? 'Auto Next: ON' : 'Auto Next: OFF',
                    style: TextStyle(
                      color: _autoPlayNext ? AppTheme.accentEmerald : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Playback Speed Button
          InkWell(
            onTap: _openSpeedSelector,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Screen Orientation Rotate Button
          IconButton(
            icon: Icon(
              _isLandscape ? Icons.screen_lock_rotation_rounded : Icons.screen_rotation_rounded,
              color: Colors.white,
            ),
            tooltip: 'Rotate Screen',
            onPressed: _toggleOrientation,
          ),

          // Lock Gesture Button
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
            tooltip: 'Lock Screen Controls',
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
        // Previous Video Button
        IconButton(
          iconSize: 34,
          icon: Icon(
            Icons.skip_previous_rounded,
            color: _hasAvailablePrevious() ? Colors.white : Colors.white24,
          ),
          onPressed: _hasAvailablePrevious() ? _playPreviousVideo : null,
        ),
        const SizedBox(width: 16),

        // Rewind 10 Seconds
        IconButton(
          iconSize: 42,
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
          onPressed: () => _skipSeconds(false),
        ),
        const SizedBox(width: 20),

        // Main Play / Pause Button
        Container(
          width: 68,
          height: 68,
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
              ),
            ],
          ),
          child: IconButton(
            iconSize: 38,
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
        const SizedBox(width: 20),

        // Fast Forward 10 Seconds
        IconButton(
          iconSize: 42,
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
          onPressed: () => _skipSeconds(true),
        ),
        const SizedBox(width: 16),

        // Next Video Button
        IconButton(
          iconSize: 34,
          icon: Icon(
            Icons.skip_next_rounded,
            color: _hasAvailableNext() ? Colors.white : Colors.white24,
          ),
          onPressed: _hasAvailableNext() ? _playNextVideo : null,
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryViolet,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (val) {
                      _controller.seekTo(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
              ),
              const SizedBox(width: 8),

              // Fullscreen Rotate Toggle
              IconButton(
                icon: Icon(
                  _isLandscape ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                tooltip: 'Fullscreen Toggle',
                onPressed: _toggleOrientation,
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
