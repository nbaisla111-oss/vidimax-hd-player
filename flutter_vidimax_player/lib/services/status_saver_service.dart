import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/status_item_model.dart';
import 'system_controls_service.dart';

class StatusSaverService {
  static final StatusSaverService _instance = StatusSaverService._internal();
  factory StatusSaverService() => _instance;
  StatusSaverService._internal();

  // WhatsApp & WA Business Status directories (Android 9 through Android 14+ & Dual Messenger)
  final List<String> statusDirectories = [
    // Standard Android 11, 12, 13, 14 Scoped Storage paths
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/Statuses',

    // Legacy Android 9, 10 paths
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/WhatsApp/Media/Statuses',
    '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/0/WhatsApp Business/Media/Statuses',

    // Samsung Dual Messenger / Multi-User paths
    '/storage/emulated/999/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/999/WhatsApp/Media/.Statuses',
    '/storage/emulated/999/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/999/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/10/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/10/WhatsApp/Media/.Statuses',

    // Alternative builds
    '/storage/emulated/0/Android/media/com.gbwhatsapp/GBWhatsApp/Media/.Statuses',
    '/storage/emulated/0/GBWhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp.plus/WhatsApp Plus/Media/.Statuses',

    // Video subfolder caches
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Video/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video/.Statuses',
  ];

  Future<bool> _isStatusAlreadySaved(String fileName, bool isVideo) async {
    final candidates = <String>[
      if (isVideo) '/storage/emulated/0/Movies/RoxPlayer_Status/$fileName',
      '/storage/emulated/0/Pictures/RoxPlayer_Status/$fileName',
      '/storage/emulated/0/DCIM/RoxPlayer_Status/$fileName',
      '/storage/emulated/0/Pictures/VidiMax_Status/$fileName',
    ];
    for (final path in candidates) {
      try {
        if (await File(path).exists()) return true;
      } catch (_) {}
    }
    return false;
  }

  String _canonicalPathKey(String rawPath) {
    String resolved = rawPath;
    try {
      resolved = File(rawPath).resolveSymbolicLinksSync();
    } catch (_) {}
    return p.normalize(resolved).replaceAll('\\', '/').toLowerCase();
  }

  /// Scan status directory for photos and videos securely
  Future<List<StatusItemModel>> fetchStatuses({StatusAppSource? filterSource}) async {
    final List<StatusItemModel> list = [];
    final Set<String> seenCanonicalPaths = {};
    final Set<String> seenSignatures = {};

    for (final dirPath in statusDirectories) {
      final dir = Directory(dirPath);
      try {
        if (await dir.exists()) {
          final isBusiness = dirPath.contains('w4b') || dirPath.contains('WhatsApp Business');
          final source = isBusiness ? StatusAppSource.whatsappBusiness : StatusAppSource.whatsapp;

          if (filterSource != null && filterSource != source) continue;

          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity is File) {
              final filePath = entity.path;
              final canonicalKey = _canonicalPathKey(filePath);
              if (seenCanonicalPaths.contains(canonicalKey)) continue;

              final fileName = p.basename(filePath);
              final lowerName = fileName.toLowerCase();

              // Skip internal hidden files, .nomedia, and .thumb cache stubs
              if (fileName.startsWith('.') ||
                  fileName.startsWith('.trashed-') ||
                  lowerName.contains('.thumb') ||
                  lowerName.endsWith('.nomedia')) {
                continue;
              }

              final ext = p.extension(filePath).toLowerCase();
              final isVideo = ['.mp4', '.3gp', '.mkv'].contains(ext);
              final isImage = ['.jpg', '.jpeg', '.png'].contains(ext);

              if (isVideo || isImage) {
                final stat = entity.statSync();

                // Filter out low-resolution thumbnail blur cache files
                if (isImage && stat.size < 15 * 1024) {
                  continue;
                }
                if (isVideo && stat.size < 50 * 1024) {
                  continue;
                }

                // Prevent duplicate statuses when legacy /WhatsApp/ and Scoped /Android/media/ mirror or symlink
                final sig = '${source.name}_${lowerName}_${stat.size}';
                if (seenSignatures.contains(sig)) continue;

                seenCanonicalPaths.add(canonicalKey);
                seenSignatures.add(sig);

                final isSaved = await _isStatusAlreadySaved(fileName, isVideo);

                list.add(
                  StatusItemModel(
                    id: canonicalKey.hashCode.toString(),
                    title: fileName,
                    path: filePath,
                    file: entity,
                    mediaType: isVideo ? StatusMediaType.video : StatusMediaType.image,
                    source: source,
                    size: stat.size,
                    modifiedDate: stat.modified,
                    isSaved: isSaved,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        // Ignore directory permission errors and continue scanning other folders
      }
    }

    list.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return list;
  }

  /// Save status permanently to device gallery via Android MediaStore & MediaScanner
  Future<File> saveStatusToGallery(StatusItemModel status) async {
    final fileName = p.basename(status.path);
    final isVideo = status.mediaType == StatusMediaType.video;

    if (Platform.isAndroid) {
      final result = await SystemControlsService().saveMediaToGallery(
        sourcePath: status.path,
        fileName: fileName,
        isVideo: isVideo,
      );
      if (result['success'] == true) {
        final savedPath = result['savedPath'] as String?;
        if (savedPath != null && savedPath.isNotEmpty) {
          return File(savedPath);
        }
      }
    }

    // Fallback: save to public directory and invoke MediaScanner directly
    final targetDir = Directory(
      isVideo
          ? '/storage/emulated/0/Movies/RoxPlayer_Status'
          : '/storage/emulated/0/Pictures/RoxPlayer_Status',
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final originalFile = File(status.path);
    final targetPath = p.join(targetDir.path, fileName);
    final copied = await originalFile.copy(targetPath);

    if (Platform.isAndroid) {
      await SystemControlsService().scanMediaFile(copied.path);
    }
    return copied;
  }

  /// Share status to other apps
  Future<void> shareStatus(StatusItemModel status) async {
    await Share.shareXFiles(
      [XFile(status.path)],
      text: 'Shared via Rox Player',
    );
  }
}
