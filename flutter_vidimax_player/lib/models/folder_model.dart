import 'video_model.dart';

class FolderModel {
  final String name;
  final String path;
  final List<VideoModel> videos;

  FolderModel({
    required this.name,
    required this.path,
    required this.videos,
  });

  int get count => videos.length;

  int get totalSizeBytes => videos.fold(0, (sum, v) => sum + v.sizeBytes);

  String get formattedTotalSize {
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double s = totalSizeBytes.toDouble();
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String? get previewThumbnail => videos.isNotEmpty ? videos.first.thumbnailPath : null;
}
