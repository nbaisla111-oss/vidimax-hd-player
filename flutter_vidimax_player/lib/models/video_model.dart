class VideoModel {
  final String id;
  final String title;
  final String path;
  final String folderName;
  final int durationMs;
  final int sizeBytes;
  final int dateModified;
  final String? thumbnailPath;
  final String resolution;
  final int lastPlayedPositionMs;

  VideoModel({
    required this.id,
    required this.title,
    required this.path,
    required this.folderName,
    required this.durationMs,
    required this.sizeBytes,
    required this.dateModified,
    this.thumbnailPath,
    this.resolution = '1080p FHD',
    this.lastPlayedPositionMs = 0,
  });

  String get formattedDuration {
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (sizeBytes <= 0) return "0 MB";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double s = sizeBytes.toDouble();
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(1)} ${suffixes[i]}';
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? path,
    String? folderName,
    int? durationMs,
    int? sizeBytes,
    int? dateModified,
    String? thumbnailPath,
    String? resolution,
    int? lastPlayedPositionMs,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      folderName: folderName ?? this.folderName,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dateModified: dateModified ?? this.dateModified,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      resolution: resolution ?? this.resolution,
      lastPlayedPositionMs: lastPlayedPositionMs ?? this.lastPlayedPositionMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'path': path,
    'folderName': folderName,
    'durationMs': durationMs,
    'sizeBytes': sizeBytes,
    'dateModified': dateModified,
    'thumbnailPath': thumbnailPath,
    'resolution': resolution,
    'lastPlayedPositionMs': lastPlayedPositionMs,
  };

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
    id: json['id'] as String,
    title: json['title'] as String,
    path: json['path'] as String,
    folderName: json['folderName'] as String,
    durationMs: json['durationMs'] as int,
    sizeBytes: json['sizeBytes'] as int,
    dateModified: json['dateModified'] as int,
    thumbnailPath: json['thumbnailPath'] as String?,
    resolution: json['resolution'] as String? ?? '1080p FHD',
    lastPlayedPositionMs: json['lastPlayedPositionMs'] as int? ?? 0,
  );
}
