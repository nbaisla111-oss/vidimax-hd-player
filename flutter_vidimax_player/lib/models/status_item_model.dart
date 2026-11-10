import 'dart:io';

enum StatusMediaType {
  image,
  video,
}

enum StatusAppSource {
  whatsapp,
  whatsappBusiness,
}

class StatusItemModel {
  final String id;
  final String title;
  final String path;
  final File file;
  final StatusMediaType mediaType;
  final StatusAppSource source;
  final DateTime modifiedDate;
  final int size;
  final bool isSaved;

  StatusItemModel({
    required this.id,
    required this.title,
    required this.path,
    required this.file,
    required this.mediaType,
    required this.source,
    required this.modifiedDate,
    required this.size,
    this.isSaved = false,
  });

  StatusItemModel copyWith({
    String? id,
    String? title,
    String? path,
    File? file,
    StatusMediaType? mediaType,
    StatusAppSource? source,
    DateTime? modifiedDate,
    int? size,
    bool? isSaved,
  }) {
    return StatusItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      file: file ?? this.file,
      mediaType: mediaType ?? this.mediaType,
      source: source ?? this.source,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      size: size ?? this.size,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
