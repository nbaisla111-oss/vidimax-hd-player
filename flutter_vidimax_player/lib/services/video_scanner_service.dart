import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';
import '../models/folder_model.dart';

class VideoScannerService {
  static final VideoScannerService _instance = VideoScannerService._internal();
  factory VideoScannerService() => _instance;
  VideoScannerService._internal();

  final List<String> supportedExtensions = [
    '.mp4', '.mkv', '.webm', '.avi', '.mov', '.flv', '.3gp', '.ts', '.m4v'
  ];

  static const String _cacheKey = 'vidimax_cached_videos_v1';

  /// Load cached videos from SharedPreferences for instant 0ms app launch
  Future<List<VideoModel>> getCachedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded.map((item) {
          return VideoModel(
            id: item['id'] ?? '',
            title: item['title'] ?? '',
            path: item['path'] ?? '',
            folderName: item['folderName'] ?? 'Videos',
            durationMs: item['durationMs'] ?? 60000,
            sizeBytes: item['sizeBytes'] ?? 0,
            dateModified: item['dateModified'] ?? 0,
            thumbnailPath: item['thumbnailPath'],
            resolution: item['resolution'] ?? 'HD',
          );
        }).where((v) => File(v.path).existsSync()).toList();
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
    final Set<String> seenPaths = {};

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
      Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Telegram/Telegram Video'),
      Directory('/storage/emulated/0/Snaptube/download'),
      Directory('/storage/emulated/0/Vidmate/download'),
      Directory('/storage/emulated/0/ScreenRecorder'),
    ];

    for (final dir in directDirs) {
      if (await dir.exists()) {
        try {
          final entries = dir.listSync(recursive: false, followLinks: false);
          for (final entity in entries) {
            if (entity is File) {
              _processFile(entity, seenPaths, videos);
            } else if (entity is Directory) {
              // Shallow scan 1 level deeper for subfolders (e.g. Movies/Instagram, DCIM/100MEDIA)
              try {
                final subEntries = entity.listSync(recursive: false, followLinks: false);
                for (final sub in subEntries) {
                  if (sub is File) {
                    _processFile(sub, seenPaths, videos);
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

    // Sort by most recently modified
    videos.sort((a, b) => b.dateModified.compareTo(a.dateModified));

    // Save to cache for instant future launches
    if (videos.isNotEmpty) {
      await _saveVideosToCache(videos);
    }

    return videos;
  }

  void _processFile(File file, Set<String> seenPaths, List<VideoModel> videos) {
    final ext = p.extension(file.path).toLowerCase();
    if (!supportedExtensions.contains(ext)) return;
    if (seenPaths.contains(file.path)) return;

    try {
      seenPaths.add(file.path);
      final stat = file.statSync();
      final folderName = p.basename(p.dirname(file.path));
      final fileName = p.basename(file.path);

      videos.add(
        VideoModel(
          id: file.path.hashCode.toString(),
          title: p.basenameWithoutExtension(fileName),
          path: file.path,
          folderName: folderName.isEmpty ? 'Root' : folderName,
          durationMs: 60000,
          sizeBytes: stat.size,
          dateModified: stat.modified.millisecondsSinceEpoch,
          thumbnailPath: null,
          resolution: '1080p FHD',
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
