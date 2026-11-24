import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';
import '../models/folder_model.dart';
import 'system_controls_service.dart';

class VideoScannerService {
  static final VideoScannerService _instance = VideoScannerService._internal();
  factory VideoScannerService() => _instance;
  VideoScannerService._internal();

  final List<String> supportedExtensions = [
    '.mp4', '.mkv', '.webm', '.avi', '.mov', '.flv', '.3gp', '.ts', '.m4v'
  ];

  static const String _cacheKey = 'vidimax_cached_videos_v3';

  String _canonicalPathKey(String rawPath) {
    String resolved = rawPath;
    try {
      resolved = File(rawPath).resolveSymbolicLinksSync();
    } catch (_) {}
    String normalized = p.normalize(resolved).replaceAll('\\', '/').trim();
    final lower = normalized.toLowerCase();
    const prefixes = [
      '/sdcard/',
      '/mnt/sdcard/',
      '/storage/self/primary/',
      '/mnt/user/0/primary/',
    ];
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        normalized = '/storage/emulated/0/${normalized.substring(prefix.length)}';
        break;
      }
    }
    return normalized.toLowerCase();
  }

  /// Load cached videos from SharedPreferences for instant 0ms app launch
  Future<List<VideoModel>> getCachedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final seenCanonical = <String>{};
        final seenSigs = <String>{};
        final list = <VideoModel>[];
        for (final item in decoded) {
          final path = item['path'] as String? ?? '';
          final base = p.basename(path);
          if (path.isEmpty || base.startsWith('.') || base.startsWith('.trashed-')) continue;
          if (!File(path).existsSync()) continue;
          final canonical = _canonicalPathKey(path);
          if (!seenCanonical.add(canonical)) continue;
          final sizeBytes = item['sizeBytes'] ?? 0;
          final sig = '${base.toLowerCase()}_$sizeBytes';
          if (!seenSigs.add(sig)) continue;
          list.add(
            VideoModel(
              id: item['id'] ?? canonical.hashCode.toString(),
              title: item['title'] ?? '',
              path: path,
              folderName: item['folderName'] ?? 'Videos',
              durationMs: item['durationMs'] ?? 0,
              sizeBytes: sizeBytes,
              dateModified: item['dateModified'] ?? 0,
              thumbnailPath: item['thumbnailPath'],
              resolution: item['resolution'] ?? 'HD',
            ),
          );
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Save scanned videos to cache
  Future<void> _saveVideosToCache(List<VideoModel> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = videos.map((v) => {
        'id': v.id,
        'title': v.title,
        'path': v.path,
        'folderName': v.folderName,
        'durationMs': v.durationMs,
        'sizeBytes': v.sizeBytes,
        'dateModified': v.dateModified,
        'thumbnailPath': v.thumbnailPath,
        'resolution': v.resolution,
      }).toList();
      await prefs.setString(_cacheKey, jsonEncode(mapped));
    } catch (_) {}
  }

  /// Scan storage directories for video files fast without blocking UI
  Future<List<VideoModel>> scanDeviceVideos() async {
    final List<VideoModel> videos = [];
    final Set<String> seenCanonicalPaths = {};
    final Set<String> seenSignatures = {};

    // Specific direct directories where videos are located on Android devices
    final directDirs = [
      Directory('/storage/emulated/0/DCIM/Camera'),
      Directory('/storage/emulated/0/DCIM/Screenshots'),
      Directory('/storage/emulated/0/DCIM/ScreenRecorder'),
      Directory('/storage/emulated/0/DCIM'),
      Directory('/storage/emulated/0/Movies'),
      Directory('/storage/emulated/0/Movies/Instagram'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Pictures'),
      Directory('/storage/emulated/0/Videos'),
      Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Telegram/Telegram Video'),
      Directory('/storage/emulated/0/Snaptube/download'),
      Directory('/storage/emulated/0/Vidmate/download'),
      Directory('/storage/emulated/0/ScreenRecorder'),
    ];

    for (final dir in directDirs) {
      if (await dir.exists()) {
        try {
          if (File(p.join(dir.path, '.nomedia')).existsSync()) continue;
          final entries = dir.listSync(recursive: false, followLinks: false);
          for (final entity in entries) {
            if (entity is File) {
              _processFile(entity, seenCanonicalPaths, seenSignatures, videos);
            } else if (entity is Directory) {
              final subName = p.basename(entity.path);
              // Skip hidden folders (.Statuses, .thumbnails, .trashed) and .nomedia dirs (WhatsApp Sent/Private)
              if (subName.startsWith('.')) continue;
              if (File(p.join(entity.path, '.nomedia')).existsSync()) continue;
              try {
                final subEntries = entity.listSync(recursive: false, followLinks: false);
                for (final sub in subEntries) {
                  if (sub is File) {
                    _processFile(sub, seenCanonicalPaths, seenSignatures, videos);
                  }
                }
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint("Folder scan skipped: ${dir.path} ($e)");
        }
      }
    }

    // Hydrate real durations and resolutions in one native batch call
    if (videos.isNotEmpty) {
      final mediaInfoMap = await SystemControlsService().getVideosMediaInfo(
        videos.map((v) => v.path).toList(),
      );
      if (mediaInfoMap.isNotEmpty) {
        for (int i = 0; i < videos.length; i++) {
          final v = videos[i];
          final info = mediaInfoMap[v.path];
          if (info != null) {
            final durMs = (info['durationMs'] as num?)?.toInt() ?? 0;
            final res = info['resolution'] as String?;
            videos[i] = v.copyWith(
              durationMs: durMs > 0 ? durMs : v.durationMs,
              resolution: (res != null && res.isNotEmpty) ? res : v.resolution,
            );
          }
        }
      }
    }

    // Sort by most recently modified
    videos.sort((a, b) => b.dateModified.compareTo(a.dateModified));

    // Save to cache for instant future launches
    if (videos.isNotEmpty) {
      await _saveVideosToCache(videos);
    }

    return videos;
  }

  void _processFile(
    File file,
    Set<String> seenCanonicalPaths,
    Set<String> seenSignatures,
    List<VideoModel> videos,
  ) {
    final fileName = p.basename(file.path);
    if (fileName.startsWith('.') || fileName.startsWith('.trashed-')) return;

    final ext = p.extension(file.path).toLowerCase();
    if (!supportedExtensions.contains(ext)) return;

    final canonicalKey = _canonicalPathKey(file.path);
    if (seenCanonicalPaths.contains(canonicalKey)) return;

    try {
      final stat = file.statSync();
      if (stat.size <= 0) return;

      final sig = '${fileName.toLowerCase()}_${stat.size}';
      if (seenSignatures.contains(sig)) return;

      seenCanonicalPaths.add(canonicalKey);
      seenSignatures.add(sig);

      final folderName = p.basename(p.dirname(file.path));

      videos.add(
        VideoModel(
          id: canonicalKey.hashCode.toString(),
          title: p.basenameWithoutExtension(fileName),
          path: file.path,
          folderName: folderName.isEmpty ? 'Root' : folderName,
          durationMs: 0,
          sizeBytes: stat.size,
          dateModified: stat.modified.millisecondsSinceEpoch,
          thumbnailPath: null,
          resolution: 'HD',
        ),
      );
    } catch (_) {}
  }

  /// Group video list into folders
  Map<String, FolderModel> groupVideosByFolder(List<VideoModel> videos) {
    final Map<String, List<VideoModel>> folderMap = {};

    for (final video in videos) {
      folderMap.putIfAbsent(video.folderName, () => []).add(video);
    }

    final Map<String, FolderModel> folders = {};
    folderMap.forEach((name, list) {
      folders[name] = FolderModel(
        name: name,
        path: list.isNotEmpty ? p.dirname(list.first.path) : '',
        videos: list,
      );
    });

    return folders;
  }
}
