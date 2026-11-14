import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../utils/app_theme.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const VideoThumbnailWidget({
    super.key,
    required this.videoPath,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  // Global static memory cache so thumbnails load instantly on scroll and across screens
  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List?>> _pendingFutures = {};

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (VideoThumbnailWidget._cache.containsKey(widget.videoPath)) {
      if (mounted) {
        setState(() {
          _bytes = VideoThumbnailWidget._cache[widget.videoPath];
        });
      }
      return;
    }

    // Reuse in-flight future if already requested
    final future = VideoThumbnailWidget._pendingFutures.putIfAbsent(
      widget.videoPath,
      () => VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 360,
        quality: 85,
      ),
    );

    try {
      final data = await future;
      if (data != null) {
        VideoThumbnailWidget._cache[widget.videoPath] = data;
        if (mounted) {
          setState(() {
            _bytes = data;
          });
        }
      }
    } catch (_) {
      // Fallback on decoder error
    } finally {
      VideoThumbnailWidget._pendingFutures.remove(widget.videoPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    Widget content;
    if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      content = _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: radius,
      child: content,
    );
  }

  Widget _buildPlaceholder() {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1C1C21), const Color(0xFF09090B)]
              : [const Color(0xFFF4F4F5), const Color(0xFFE4E4E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white30 : Colors.black26,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }
}
