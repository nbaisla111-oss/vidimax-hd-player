import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/video_model.dart';
import '../models/folder_model.dart';

class VideoScannerService {
  static final VideoScannerService _instance = VideoScannerService._internal();
  factory VideoScannerService() => _instance;
  VideoScannerService._internal();

  final List<String> supportedExtensions = [
    '.mp4', '.mkv', '.webm', '.avi', '.mov', '.flv', '.3gp', '.ts', '.m4v'
  ];

  /// Scan storage directories for video files instantly without heavy thumbnail lag
  Future<List<VideoModel>> scanDeviceVideos() async {
    final List<VideoModel> videos = [];

    final targetDirs = [
      Directory('/storage/emulated/0/DCIM'),
      Directory('/storage/emulated/0/Movies'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video'),
      Directory('/storage/emulated/0/Pictures'),
      Directory('/storage/emulated/0/Videos'),
    ];

    for (final dir in targetDirs) {
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (supportedExtensions.contains(ext)) {
                try {
                  final stat = await entity.stat();
                  final folderName = p.basename(p.dirname(entity.path));
                  final fileName = p.basename(entity.path);

                  // थंबनेल जनरेशन यहाँ से हटा दिया गया है ताकि स्कैनिंग में एक सेकंड भी न लगे!
                  // थंबनेल UI पर अपने आप डिफ़ॉल्ट या बाद में लोड हो जाएगा।

                  videos.add(
                    VideoModel(
                      id: entity.path.hashCode.toString(),
                      title: p.basenameWithoutExtension(fileName),
                      path: entity.path,
                      folderName: folderName.isEmpty ? 'Root' : folderName,
                      durationMs: 60000, 
                      sizeBytes: stat.size,
                      dateModified: stat.modified.millisecondsSinceEpoch,
                      thumbnailPath: null, // Fast loading optimization
                      resolution: '1080p FHD',
                    ),
                  );
                } catch (e) {
                  // Ignore inaccessible files
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    // Sort by most recently modified
    videos.sort((a, b) => b.dateModified.compareTo(a.dateModified));
    return videos;
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
