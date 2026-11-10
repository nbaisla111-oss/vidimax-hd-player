class MusicModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int size;
  final Duration duration;
  final String folder;
  final DateTime dateAdded;
  final bool isFavorite;

  const MusicModel({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Local Audio',
    required this.path,
    required this.size,
    required this.duration,
    required this.folder,
    required this.dateAdded,
    this.isFavorite = false,
  });

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String get formattedSize {
    if (size <= 0) return '0 MB';
    final mb = size / (1024 * 1024);
    if (mb < 1.0) {
      final kb = size / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  MusicModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    int? size,
    Duration? duration,
    String? folder,
    DateTime? dateAdded,
    bool? isFavorite,
  }) {
    return MusicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      folder: folder ?? this.folder,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
