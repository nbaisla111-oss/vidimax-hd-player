import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/video_thumbnail_widget.dart';

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

class _CustomVideoPlayerScreenState extends State<CustomVideoPlayerScreen> with WidgetsBindingObserver {
  static const MethodChannel _systemChannel = MethodChannel('com.vidimax.player/system_controls');

  VideoPlayerController? _controller;
  late int _currentIndex;
  late VideoModel _currentVideo;
  late List<VideoModel> _playlist;

  bool _isInitialized = false;
  bool _isTransitioning = false;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isLandscape = false;
  bool _autoPlayNext = true;
  bool _isLooping = false;
  bool _isMuted = false;
  bool _is2xActive = false;
  bool _isInPipMode = false;
  bool _lastPipPlaying = false;

  double _volume = 1.0;
  double _brightness = 0.5;
  double _playbackSpeed = 1.0;

  bool _isExiting = false;
  bool _hasCustomBrightness = false;
  bool _isDraggingVolume = false;
  bool _volumeSyncedForDrag = false;
  double _pendingVolumeDelta = 0.0;
  int _lastSentVolumePercent = -1;

  double? _nativeAspectRatio;
  int? _nativeDisplayWidth;
  int? _nativeDisplayHeight;
  int _fitMode = 0; // 0: Original Fit, 1: Fill / Crop, 2: Stretch

  Timer? _hideControlsTimer;
  Timer? _indicatorTimer;
  Timer? _seekRippleTimer;
  Timer? _toastTimer;

  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  bool _showSeekRipple = false;
  bool _seekRippleForward = true;
  String _toastMessage = '';
  bool _showToast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentVideo = widget.video;
    _playlist = widget.playlist ?? [widget.video];
    _currentIndex = widget.initialIndex;

    _systemChannel.setMethodCallHandler(_handleNativeCallback);
    _unlockOrientationToAutoRotate();
    _loadInitialHardwareState();
    _initializeVideo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isNowLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      if (isNowLandscape != _isLandscape) {
        setState(() => _isLandscape = isNowLandscape);
        SystemChrome.setEnabledSystemUIMode(
          isNowLandscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        );
      }
    });
  }

  Future<void> _unlockOrientationToAutoRotate() async {
    try {
      await SystemChrome.setPreferredOrientations([]);
    } catch (_) {}
    try {
      await _systemChannel.invokeMethod('setOrientationMode', {'mode': 'auto'});
    } catch (_) {}
  }

  Future<void> _loadInitialHardwareState() async {
    try {
      final sysBrightness = await _systemChannel.invokeMethod<double>('getScreenBrightness');
      final sysVolume = await _systemChannel.invokeMethod<double>('getMediaVolume');
      if (!mounted) return;
      setState(() {
        if (sysBrightness != null && !_hasCustomBrightness) {
          _brightness = sysBrightness.clamp(0.02, 1.0);
        }
        if (sysVolume != null && !_isDraggingVolume) {
          _volume = sysVolume.clamp(0.0, 1.0);
          _isMuted = _volume == 0.0;
        }
      });
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isInPipMode && mounted) {
        setState(() => _isInPipMode = false);
        _syncPipPlayerState();
      }
      _loadInitialHardwareState();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isInPipMode) return;
      final isNowLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      if (isNowLandscape != _isLandscape) {
        setState(() => _isLandscape = isNowLandscape);
        SystemChrome.setEnabledSystemUIMode(
          isNowLandscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        );
      }
    });
  }

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'onPipModeChanged') {
      final isPip = call.arguments as bool? ?? false;
      setState(() {
        _isInPipMode = isPip;
        if (!isPip) {
          _showControls = true;
        }
      });
      if (!isPip) {
        _startHideTimer();
      }
    } else if (call.method == 'onPipAction') {
      final action = call.arguments as String? ?? '';
      if (action == 'prev') {
        _playPreviousVideo();
      } else if (action == 'next') {
        _playNextVideo();
      } else if (action == 'toggle') {
        _togglePlayPause();
      }
    } else if (call.method == 'onPlayerBackgrounded') {
      if (_controller?.value.isPlaying ?? false) {
        _controller?.pause();
        setState(() {});
        _syncPipPlayerState(active: true);
      }
    }
  }

  Future<void> _syncPipPlayerState({bool active = true}) async {
    try {
      final playing = _controller?.value.isPlaying ?? false;
      _lastPipPlaying = playing;
      final size = _controller?.value.size;
      final w = (_nativeDisplayWidth != null && _nativeDisplayWidth! > 0)
          ? _nativeDisplayWidth!
          : ((size != null && size.width > 0) ? size.width.round() : 16);
      final h = (_nativeDisplayHeight != null && _nativeDisplayHeight! > 0)
          ? _nativeDisplayHeight!
          : ((size != null && size.height > 0) ? size.height.round() : 9);
      await _systemChannel.invokeMethod('setPipPlayerState', {
        'active': active,
        'playing': playing,
        'width': w,
        'height': h,
      });
    } catch (_) {}
  }

  Future<void> _enterPipMode() async {
    if (!_isInitialized || _controller == null) return;
    try {
      final size = _controller!.value.size;
      final w = (_nativeDisplayWidth != null && _nativeDisplayWidth! > 0)
          ? _nativeDisplayWidth!
          : (size.width > 0 ? size.width.round() : 16);
      final h = (_nativeDisplayHeight != null && _nativeDisplayHeight! > 0)
          ? _nativeDisplayHeight!
          : (size.height > 0 ? size.height.round() : 9);
      final entered = await _systemChannel.invokeMethod<bool>('enterPipMode', {
        'playing': _controller!.value.isPlaying,
        'width': w,
        'height': h,
      });
      if (entered != true && mounted) {
        _showToastNotification('Pop-up Play requires Android 8.0+ PiP support');
      }
    } catch (_) {
      if (mounted) {
        _showToastNotification('Pop-up Play is not available on this device');
      }
    }
  }

  Future<void> _fetchNativeVideoMetadata(String path) async {
    if (path.isEmpty || path.startsWith('http://') || path.startsWith('https://')) {
      return;
    }
    try {
      final meta = await _systemChannel.invokeMapMethod<String, dynamic>(
        'getVideoMetadata',
        {'path': path},
      );
      if (!mounted || meta == null) return;
      final w = (meta['width'] as num?)?.toInt() ?? 0;
      final h = (meta['height'] as num?)?.toInt() ?? 0;
      if (w > 0 && h > 0) {
        setState(() {
          _nativeDisplayWidth = w;
          _nativeDisplayHeight = h;
          _nativeAspectRatio = w / h;
        });
      }
    } catch (_) {}
  }

  Future<void> _initializeVideo() async {
    _isInitialized = false;
    _isTransitioning = false;
    _nativeAspectRatio = null;
    _nativeDisplayWidth = null;
    _nativeDisplayHeight = null;
    if (mounted) setState(() {});

    final videoOptions = VideoPlayerOptions(
      mixWithOthers: false,
      allowBackgroundPlayback: false,
    );

    try {
      final ctrl = _currentVideo.path.startsWith('http')
          ? VideoPlayerController.networkUrl(
              Uri.parse(_currentVideo.path),
              videoPlayerOptions: videoOptions,
            )
          : VideoPlayerController.file(
              File(_currentVideo.path),
              videoPlayerOptions: videoOptions,
            );

      _controller = ctrl;
      await Future.wait([
        ctrl.initialize(),
        _fetchNativeVideoMetadata(_currentVideo.path),
      ]);
      ctrl.addListener(_videoListener);
      await ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      await ctrl.setPlaybackSpeed(_playbackSpeed);
      await ctrl.setLooping(_isLooping);

      if (mounted) {
        setState(() => _isInitialized = true);
        await ctrl.play();
        await _syncPipPlayerState(active: true);
        _startHideTimer();
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      try {
        final fallbackCtrl = _currentVideo.path.startsWith('http')
            ? VideoPlayerController.networkUrl(Uri.parse(_currentVideo.path))
            : VideoPlayerController.file(File(_currentVideo.path));
        _controller = fallbackCtrl;
        await fallbackCtrl.initialize();
        fallbackCtrl.addListener(_videoListener);
        await fallbackCtrl.setVolume(_isMuted ? 0.0 : 1.0);
        await fallbackCtrl.setPlaybackSpeed(_playbackSpeed);
        await fallbackCtrl.setLooping(_isLooping);
        if (mounted) {
          setState(() => _isInitialized = true);
          await fallbackCtrl.play();
          await _syncPipPlayerState(active: true);
          _startHideTimer();
        }
      } catch (retryErr) {
        debugPrint("Retry video load error: $retryErr");
      }
    }
  }

  void _videoListener() {
    if (!mounted || !_isInitialized || _controller == null) return;
    final val = _controller!.value;

    if (!_isLooping &&
        !_isTransitioning &&
        val.duration > const Duration(seconds: 1) &&
        val.position >= val.duration - const Duration(milliseconds: 250)) {
      if (_autoPlayNext && _hasAvailableNext()) {
        _isTransitioning = true;
        _playNextVideo();
        return;
      }
    }

    if (val.isPlaying != _lastPipPlaying) {
      _syncPipPlayerState(active: true);
    }

    setState(() {});
  }

  bool _hasAvailableNext() => _currentIndex < _playlist.length - 1;
  bool _hasAvailablePrevious() => _currentIndex > 0;

  void _playNextVideo() {
    if (!_hasAvailableNext()) {
      _showToastNotification('Last video in playlist');
      return;
    }
    _changeVideoTo(_currentIndex + 1);
  }

  void _playPreviousVideo() {
    if (!_hasAvailablePrevious()) {
      _showToastNotification('First video in playlist');
      return;
    }
    _changeVideoTo(_currentIndex - 1);
  }

  Future<void> _changeVideoTo(int newIndex) async {
    if (newIndex < 0 || newIndex >= _playlist.length) return;
    _hideControlsTimer?.cancel();
    _isTransitioning = true;

    final oldCtrl = _controller;
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _controller = null;
        _currentIndex = newIndex;
        _currentVideo = _playlist[_currentIndex];
      });
    } else {
      _controller = null;
    }

    if (oldCtrl != null) {
      oldCtrl.removeListener(_videoListener);
      await oldCtrl.pause();
      await oldCtrl.dispose();
    }

    await _initializeVideo();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false) && !_isLocked && !_isInPipMode) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLocked || _isInPipMode) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null || !_isInitialized) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() {});
    _syncPipPlayerState(active: true);
    _startHideTimer();
  }

  void _toggleMute() {
    final ctrl = _controller;
    if (ctrl == null || !_isInitialized) return;
    setState(() {
      if (_isMuted) {
        _isMuted = false;
        ctrl.setVolume(1.0);
        if (_volume <= 0.01) {
          _volume = 0.5;
          _applyHardwareVolume(_volume);
        }
      } else {
        _isMuted = true;
        ctrl.setVolume(0.0);
      }
    });
    _showToastNotification(_isMuted ? 'Audio Muted' : 'Audio Unmuted');
    _startHideTimer();
  }

  void _toggleLoop() {
    final ctrl = _controller;
    if (ctrl == null || !_isInitialized) return;
    setState(() => _isLooping = !_isLooping);
    ctrl.setLooping(_isLooping);
    _showToastNotification(_isLooping ? 'Repeat current video: ON' : 'Repeat: OFF');
    _startHideTimer();
  }

  Future<void> _toggleOrientation() async {
    final targetLandscape = !_isLandscape;
    setState(() {
      _isLandscape = targetLandscape;
    });

    if (targetLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      try {
        await _systemChannel.invokeMethod('setOrientationMode', {'mode': 'landscape'});
      } catch (_) {}
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      try {
        await _systemChannel.invokeMethod('setOrientationMode', {'mode': 'portrait'});
      } catch (_) {}
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _startHideTimer();
  }

  void _cycleFitMode() {
    setState(() {
      _fitMode = (_fitMode + 1) % 3;
    });
    const labels = ['Original Fit', 'Crop / Fill Screen', 'Stretch Full'];
    _showToastNotification('Aspect: ${labels[_fitMode]}');
    _startHideTimer();
  }

  void _skipSeconds(bool forward) {
    if (_isLocked || _isInPipMode) return;
    final ctrl = _controller;
    if (ctrl == null || !_isInitialized) return;
    final current = ctrl.value.position;
    final dur = ctrl.value.duration;
    var target = forward
        ? current + const Duration(seconds: 10)
        : current - const Duration(seconds: 10);
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;

    ctrl.seekTo(target);

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

  Future<void> _applyHardwareVolume(double volume) async {
    final percent = (volume.clamp(0.0, 1.0) * 100).round();
    if (percent == _lastSentVolumePercent) return;
    _lastSentVolumePercent = percent;
    try {
      await _systemChannel.invokeMethod('setMediaVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (_) {}
  }

  Future<void> _syncVolumeBeforeDrag() async {
    try {
      final hwVol = await _systemChannel.invokeMethod<double>('getMediaVolume');
      if (hwVol != null && mounted && _isDraggingVolume) {
        setState(() {
          _volume = (hwVol + _pendingVolumeDelta).clamp(0.0, 1.0);
          _isMuted = _volume == 0.0;
          _volumeSyncedForDrag = true;
        });
        _controller?.setVolume(_isMuted ? 0.0 : 1.0);
        _applyHardwareVolume(_volume);
      }
    } catch (_) {
      _volumeSyncedForDrag = true;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isLocked || _isInPipMode) return;
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx >= screenWidth / 2) {
      _isDraggingVolume = true;
      _volumeSyncedForDrag = false;
      _pendingVolumeDelta = 0.0;
      _lastSentVolumePercent = -1;
      _syncVolumeBeforeDrag();
    }
  }

  void _onVerticalDrag(DragUpdateDetails details) {
    if (_isLocked || _isInPipMode) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final delta = -(details.primaryDelta ?? 0) / 250;

    if (details.globalPosition.dx < screenWidth / 2) {
      _hasCustomBrightness = true;
      setState(() {
        _brightness = (_brightness + delta).clamp(0.02, 1.0);
        _showBrightnessIndicator = true;
      });
      _applyHardwareBrightness(_brightness);
      _resetIndicatorTimer();
    } else {
      if (!_volumeSyncedForDrag) {
        _pendingVolumeDelta += delta;
      }
      setState(() {
        _volume = (_volume + delta).clamp(0.0, 1.0);
        _isMuted = _volume == 0.0;
        _controller?.setVolume(_isMuted ? 0.0 : 1.0);
        _showVolumeIndicator = true;
      });
      if (_volumeSyncedForDrag) {
        _applyHardwareVolume(_volume);
      }
      _resetIndicatorTimer();
    }
  }

  void _onVerticalDragEnd() {
    _isDraggingVolume = false;
    _volumeSyncedForDrag = false;
    _pendingVolumeDelta = 0.0;
  }

  Future<void> _exitPlayer() async {
    if (_isExiting) return;
    _isExiting = true;
    _hideControlsTimer?.cancel();
    if (_hasCustomBrightness) {
      await _resetHardwareBrightness();
    }
    await _syncPipPlayerState(active: false);
    if (mounted) {
      Navigator.of(context).pop();
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
    if (!_isInitialized || _isLocked || _isInPipMode) return;
    HapticFeedback.mediumImpact();
    setState(() => _is2xActive = true);
    _controller?.setPlaybackSpeed(2.0);
  }

  void _restoreNormalSpeed() {
    if (!_isInitialized || _isLocked) return;
    setState(() => _is2xActive = false);
    _controller?.setPlaybackSpeed(_playbackSpeed);
  }

  void _openSpeedSelector() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Playback Speed',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ...speeds.map((s) {
                  final isSelected = _playbackSpeed == s;
                  return ListTile(
                    title: Text(
                      s == 1.0 ? '1.0x (Normal)' : '${s}x',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                    onTap: () {
                      setState(() {
                        _playbackSpeed = s;
                        _controller?.setPlaybackSpeed(_playbackSpeed);
                      });
                      Navigator.pop(ctx);
                      _startHideTimer();
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ).whenComplete(_startHideTimer);
  }

  void _openPlaylistDrawer() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Up Next Playlist (${_playlist.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _playlist.length,
                    itemBuilder: (context, idx) {
                      final item = _playlist[idx];
                      final isCurrent = idx == _currentIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.white.withOpacity(0.14) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrent
                              ? Border.all(color: Colors.white54)
                              : null,
                        ),
                        child: ListTile(
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoThumbnailWidget(
                                videoPath: item.path,
                                width: 68,
                                height: 44,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              if (isCurrent)
                                Container(
                                  width: 68,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 22),
                                ),
                            ],
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white70,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            '${item.formattedDuration} · ${item.formattedSize}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            if (!isCurrent) {
                              _changeVideoTo(idx);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(_startHideTimer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _indicatorTimer?.cancel();
    _seekRippleTimer?.cancel();
    _toastTimer?.cancel();
    _syncPipPlayerState(active: false);
    _systemChannel.setMethodCallHandler(null);
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    if (_hasCustomBrightness) {
      _resetHardwareBrightness();
    }
    SystemChrome.setPreferredOrientations([]);
    _systemChannel.invokeMethod('setOrientationMode', {'mode': 'auto'}).catchError((_) {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isCompactPip = _isInPipMode || screenSize.width < 320 || screenSize.height < 220;

    // Inside Android Picture-in-Picture floating window: render pure unobstructed video surface
    if (isCompactPip) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: _buildVideoSurface(screenSize)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _exitPlayer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: !_isLandscape,
          bottom: !_isLandscape,
          child: GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: (details) {
              if (_isLocked || _isInPipMode) return;
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth / 2) {
                _skipSeconds(false);
              } else {
                _skipSeconds(true);
              }
            },
            onLongPressStart: (_) => _enable2xSpeed(),
            onLongPressEnd: (_) => _restoreNormalSpeed(),
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDrag,
            onVerticalDragEnd: (_) => _onVerticalDragEnd(),
            onVerticalDragCancel: _onVerticalDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Video Surface Playing in Authentic Natural Aspect Ratio
                InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  panEnabled: !_isLocked && !_isInPipMode,
                  scaleEnabled: !_isLocked && !_isInPipMode,
                  child: _buildVideoSurface(screenSize),
                ),

              // 3. YouTube-Style Clean 2X Speed Badge
              if (_is2xActive)
                Positioned(
                  top: 22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '2x',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.fast_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Clean Toast Notification
              if (_showToast)
                Positioned(
                  top: 66,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.84),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _toastMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
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
                      border: Border.all(color: Colors.amber.withOpacity(0.45)),
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
                      color: Colors.black.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
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
                                color: Colors.white,
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
                    backgroundColor: Colors.black.withOpacity(0.75),
                    onPressed: () {
                      setState(() {
                        _isLocked = false;
                        _showControls = true;
                      });
                      _startHideTimer();
                    },
                    child: const Icon(Icons.lock_rounded, color: Colors.white),
                  ),
                ),

              // 9. Cinema-Grade Player Controls Overlay
              if (_showControls && !_isLocked)
                Container(
                  color: Colors.black.withOpacity(0.38),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopBar(),
                      _buildBottomDock(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSurface(Size screenSize) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final videoSize = _controller!.value.size;
    final bool hasValidDimensions = videoSize.width > 0 && videoSize.height > 0;
    final double fallbackAspect = (hasValidDimensions && _controller!.value.aspectRatio > 0)
        ? _controller!.value.aspectRatio
        : (16 / 9);
    final double effectiveAspect = (_nativeAspectRatio != null && _nativeAspectRatio! > 0)
        ? _nativeAspectRatio!
        : fallbackAspect;

    if (_fitMode == 2) {
      return SizedBox.expand(
        child: VideoPlayer(_controller!),
      );
    }

    if (_fitMode == 1) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 1000 * effectiveAspect,
            height: 1000,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: effectiveAspect,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 16),
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
            tooltip: 'Back',
            onPressed: _exitPlayer,
          ),
          if (_playlist.length > 1)
            IconButton(
              icon: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 26),
              tooltip: 'Playlist',
              onPressed: _openPlaylistDrawer,
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentVideo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                if (_playlist.length > 1)
                  Text(
                    '${_currentIndex + 1} / ${_playlist.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
              ],
            ),
          ),

          // YouTube-Style Clean Auto-Play Toggle Switch (No green pill)
          Tooltip(
            message: _autoPlayNext ? 'Auto-play is on' : 'Auto-play is off',
            child: GestureDetector(
              onTap: () {
                setState(() => _autoPlayNext = !_autoPlayNext);
                _showToastNotification(
                  _autoPlayNext ? 'Auto-play next is on' : 'Auto-play next is off',
                );
                _startHideTimer();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _autoPlayNext
                      ? Colors.white.withOpacity(0.42)
                      : Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _autoPlayNext ? Colors.white60 : Colors.white24,
                    width: 1,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: _autoPlayNext ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: _autoPlayNext ? Colors.white : Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _autoPlayNext ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 12,
                      color: Color(0xFF09090B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Mute / Unmute Button
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: _isMuted ? 'Unmute' : 'Mute',
            onPressed: _toggleMute,
          ),

          // Share Video Button (only for non-vault local files)
          if (!widget.isVaultPlayback && !_currentVideo.path.startsWith('http'))
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 21),
              tooltip: 'Share Video',
              onPressed: () {
                if (_controller?.value.isPlaying ?? false) {
                  _controller?.pause();
                  _syncPipPlayerState(active: true);
                  setState(() {});
                }
                _startHideTimer();
                Share.shareXFiles([XFile(_currentVideo.path)], text: _currentVideo.title);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomDock() {
    final value = _controller?.value;
    final position = value?.position ?? Duration.zero;
    final duration = value?.duration ?? Duration.zero;
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final posMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.92)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Feature Strip Above Seekbar (Speed, Repeat, Playlist, Pop-up PiP)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Playback Speed Selector Pill
                InkWell(
                  onTap: _openSpeedSelector,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _playbackSpeed != 1.0
                          ? Colors.white
                          : Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _playbackSpeed != 1.0 ? Colors.white : Colors.white24,
                      ),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: TextStyle(
                        color: _playbackSpeed != 1.0 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Aspect Ratio / Screen Fit Mode
                _buildMiniActionIcon(
                  icon: Icons.aspect_ratio_rounded,
                  isActive: _fitMode != 0,
                  tooltip: 'Aspect Ratio / Fit Mode',
                  onTap: _cycleFitMode,
                ),
                const SizedBox(width: 8),

                // Repeat / Loop Single Video Button
                _buildMiniActionIcon(
                  icon: _isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  isActive: _isLooping,
                  tooltip: 'Repeat Video',
                  onTap: _toggleLoop,
                ),
                const SizedBox(width: 8),

                // Rotate Orientation Button
                _buildMiniActionIcon(
                  icon: Icons.screen_rotation_rounded,
                  isActive: _isLandscape,
                  tooltip: 'Rotate Screen',
                  onTap: _toggleOrientation,
                ),
                const SizedBox(width: 8),

                // Pop-up Play (Floating Picture-in-Picture Window)
                _buildMiniActionIcon(
                  icon: Icons.picture_in_picture_alt_rounded,
                  isActive: false,
                  tooltip: 'Pop-up Play (Floating Window)',
                  onTap: _enterPipMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Progress Seekbar + Timestamps
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: posMs,
                    min: 0.0,
                    max: maxMs,
                    onChanged: (val) {
                      _controller?.seekTo(Duration(milliseconds: val.toInt()));
                      _startHideTimer();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Bottom Action Bar BELOW Seekbar (Lock, -10s, Prev, Play/Pause, Next, +10s, Fullscreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                tooltip: 'Lock Controls',
                onPressed: () {
                  setState(() {
                    _isLocked = true;
                    _showControls = false;
                  });
                },
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 25),
                tooltip: 'Rewind 10s',
                onPressed: () => _skipSeconds(false),
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: _hasAvailablePrevious() ? Colors.white : Colors.white30,
                  size: 29,
                ),
                tooltip: 'Previous Video',
                onPressed: _hasAvailablePrevious() ? _playPreviousVideo : null,
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 1.2),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    (value?.isPlaying ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                  tooltip: (value?.isPlaying ?? false) ? 'Pause' : 'Play',
                  onPressed: _togglePlayPause,
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: _hasAvailableNext() ? Colors.white : Colors.white30,
                  size: 29,
                ),
                tooltip: 'Next Video',
                onPressed: _hasAvailableNext() ? _playNextVideo : null,
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 25),
                tooltip: 'Forward 10s',
                onPressed: () => _skipSeconds(true),
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isLandscape ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 25,
                ),
                tooltip: 'Fullscreen / Rotate',
                onPressed: _toggleOrientation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionIcon({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white24,
            ),
          ),
          child: Icon(icon, color: isActive ? Colors.black : Colors.white, size: 18),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mins:$secs';
    }
    return '$mins:$secs';
  }
}
