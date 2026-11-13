import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/status_item_model.dart';

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

  /// Scan status directory for photos and videos securely
  Future<List<StatusItemModel>> fetchStatuses({StatusAppSource? filterSource}) async {
    final List<StatusItemModel> list = [];
    final Set<String> uniquePaths = {};

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
              if (uniquePaths.contains(filePath)) continue;

              final fileName = p.basename(filePath);
              final lowerName = fileName.toLowerCase();

              // Skip internal hidden files, .nomedia, and .thumb cache stubs
              if (fileName.startsWith('.') ||
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

                uniquePaths.add(filePath);

                final savedDir = Directory('/storage/emulated/0/Pictures/RoxPlayer_Status');
                final savedFile = File(p.join(savedDir.path, fileName));
                final legacySavedFile = File(p.join('/storage/emulated/0/Pictures/VidiMax_Status', fileName));
                final isSaved = await savedFile.exists() || await legacySavedFile.exists();

                list.add(
                  StatusItemModel(
                    id: filePath.hashCode.toString(),
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

  /// Save status permanently to device gallery
  Future<File> saveStatusToGallery(StatusItemModel status) async {
    final targetDir = Directory('/storage/emulated/0/Pictures/RoxPlayer_Status');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final originalFile = File(status.path);
    final fileName = p.basename(status.path);
    final targetPath = p.join(targetDir.path, fileName);

    return await originalFile.copy(targetPath);
  }

  /// Share status to other apps
  Future<void> shareStatus(StatusItemModel status) async {
    await Share.shareXFiles(
      [XFile(status.path)],
      text: 'Shared via Rox Player',
    );
  }
}
