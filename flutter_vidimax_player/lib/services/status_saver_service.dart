import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/status_item_model.dart';

class StatusSaverService {
  static final StatusSaverService _instance = StatusSaverService._internal();
  factory StatusSaverService() => _instance;
  StatusSaverService._internal();

  final List<String> statusDirectories = [
    // Android 11+ WhatsApp path
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    // Legacy WhatsApp path
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    // Android 11+ WhatsApp Business path
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
    // Legacy WhatsApp Business path
    '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
  ];

  /// Scan WhatsApp status directory for photos and videos
  Future<List<StatusItemModel>> fetchStatuses({StatusAppSource? filterSource}) async {
    final List<StatusItemModel> list = [];

    for (final dirPath in statusDirectories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final isBusiness = dirPath.contains('w4b') || dirPath.contains('WhatsApp Business');
        final source = isBusiness ? StatusAppSource.whatsappBusiness : StatusAppSource.whatsapp;

        if (filterSource != null && filterSource != source) continue;

        try {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              final isVideo = ['.mp4', '.3gp', '.mkv'].contains(ext);
              final isImage = ['.jpg', '.jpeg', '.png'].contains(ext);

              if (isVideo || isImage) {
                final stat = entity.statSync();
                // Check if already saved in VidiMax gallery
                final savedDir = Directory('/storage/emulated/0/Pictures/VidiMax_Status');
                final savedFile = File(p.join(savedDir.path, p.basename(entity.path)));
                final isSaved = await savedFile.exists();

                list.add(
                  StatusItemModel(
                    id: entity.path.hashCode.toString(),
                    title: p.basename(entity.path),
                    path: entity.path,
                    file: entity,
                    mediaType: isVideo ? StatusMediaType.video : StatusMediaType.image,
                    source: source,
                    size: stat.size, // Fixed: sizeBytes changed to size
                    modifiedDate: stat.modified, // Passed as DateTime object as per model
                    isSaved: isSaved,
                  ),
                );
              }
            }
          }
        } catch (_) {}
      }
    }

    // Sort by recent first
    list.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return list;
  }

  /// Save status permanently to device gallery
  Future<File> saveStatusToGallery(StatusItemModel status) async {
    final targetDir = Directory('/storage/emulated/0/Pictures/VidiMax_Status');
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
      text: 'Shared via VidiMax HD Player',
    );
  }
}
