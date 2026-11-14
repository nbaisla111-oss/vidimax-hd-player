import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

class AudioArtworkWidget extends StatefulWidget {
  final String audioPath;
  final double size;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final bool isCurrent;
  final bool isPlaying;

  const AudioArtworkWidget({
    super.key,
    required this.audioPath,
    this.size = 44,
    this.borderRadius,
    this.isCircle = false,
    this.isCurrent = false,
    this.isPlaying = false,
  });

  static final Map<String, Uint8List> _cache = {};
  static final Set<String> _noArtCache = {};
  static final Map<String, Future<Uint8List?>> _pendingFutures = {};
  static const MethodChannel _channel = MethodChannel('com.vidimax.player/system_controls');

  @override
  State<AudioArtworkWidget> createState() => _AudioArtworkWidgetState();
}

class _AudioArtworkWidgetState extends State<AudioArtworkWidget> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant AudioArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _bytes = AudioArtworkWidget._cache[widget.audioPath];
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    final path = widget.audioPath;
    if (path.isEmpty || path.startsWith('http://') || path.startsWith('https://')) {
      return;
    }

    if (AudioArtworkWidget._cache.containsKey(path)) {
      if (mounted) {
        setState(() => _bytes = AudioArtworkWidget._cache[path]);
      }
      return;
    }

    if (AudioArtworkWidget._noArtCache.contains(path)) {
      return;
    }

    final future = AudioArtworkWidget._pendingFutures.putIfAbsent(
      path,
      () async {
        try {
          return await AudioArtworkWidget._channel.invokeMethod<Uint8List>(
            'getAudioArtwork',
            {'path': path},
          );
        } catch (_) {
          return null;
        }
      },
    );

    try {
      final data = await future;
      if (data != null && data.isNotEmpty) {
        AudioArtworkWidget._cache[path] = data;
        if (mounted && widget.audioPath == path) {
          setState(() => _bytes = data);
        }
      } else {
        AudioArtworkWidget._noArtCache.add(path);
      }
    } finally {
      AudioArtworkWidget._pendingFutures.remove(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    Widget inner;
    if (_bytes != null) {
      inner = Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _bytes!,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _buildFallback(context, isDark),
          ),
          if (widget.isCurrent)
            Container(
              color: Colors.black.withOpacity(0.42),
              child: Center(
                child: Icon(
                  widget.isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: (widget.size * 0.5).clamp(18.0, 44.0),
                ),
              ),
            ),
        ],
      );
    } else {
      inner = _buildFallback(context, isDark);
    }

    if (widget.isCircle) {
      return ClipOval(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: inner,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: inner,
      ),
    );
  }

  Widget _buildFallback(BuildContext context, bool isDark) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.isCurrent
            ? AppTheme.accent(context)
            : (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)),
      ),
      child: Icon(
        widget.isCurrent
            ? (widget.isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded)
            : Icons.music_note_rounded,
        color: widget.isCurrent ? AppTheme.onAccent(context) : AppTheme.textPrimary(context),
        size: (widget.size * 0.54).clamp(18.0, 54.0),
      ),
    );
  }
}
