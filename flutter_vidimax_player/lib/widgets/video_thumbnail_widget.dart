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
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B),
            AppTheme.cardDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white60,
            size: 24,
          ),
        ),
      ),
    );
  }
}
