class VaultItemModel {
  final String id;
  final String originalName;
  final String originalPath;
  final String encryptedPath;
  final int sizeBytes;
  final int dateAdded;
  final int durationMs;
  final String? thumbnailPath;
  final String mediaType; // 'video' or 'music'

  VaultItemModel({
    required this.id,
    required this.originalName,
    required this.originalPath,
    required this.encryptedPath,
    required this.sizeBytes,
    required this.dateAdded,
    required this.durationMs,
    this.thumbnailPath,
    this.mediaType = 'video',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalName': originalName,
    'originalPath': originalPath,
    'encryptedPath': encryptedPath,
    'sizeBytes': sizeBytes,
    'dateAdded': dateAdded,
    'durationMs': durationMs,
    'thumbnailPath': thumbnailPath,
    'mediaType': mediaType,
  };

  factory VaultItemModel.fromJson(Map<String, dynamic> json) => VaultItemModel(
    id: json['id'] as String,
    originalName: json['originalName'] as String,
    originalPath: json['originalPath'] as String,
    encryptedPath: json['encryptedPath'] as String,
    sizeBytes: json['sizeBytes'] as int,
    dateAdded: json['dateAdded'] as int,
    durationMs: json['durationMs'] as int,
    thumbnailPath: json['thumbnailPath'] as String?,
    mediaType: (json['mediaType'] as String?) ?? 'video',
  );
}

enum StatusMediaType { video, image }
enum StatusAppSource { whatsapp, whatsappBusiness }

class StatusItemModel {
  final String id;
  final String path;
  final StatusMediaType mediaType;
  final StatusAppSource source;
  final int sizeBytes;
  final int modifiedDate;
  final bool isSaved;

  StatusItemModel({
    required this.id,
    required this.path,
    required this.mediaType,
    required this.source,
    required this.sizeBytes,
    required this.modifiedDate,
    this.isSaved = false,
  });

  StatusItemModel copyWith({bool? isSaved}) => StatusItemModel(
    id: id,
    path: path,
    mediaType: mediaType,
    source: source,
    sizeBytes: sizeBytes,
    modifiedDate: modifiedDate,
    isSaved: isSaved ?? this.isSaved,
  );
}
