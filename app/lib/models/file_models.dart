import 'dart:typed_data';

/// Enum for supported file types
enum MyFileType {
  pdf,
  doc,
  docx,
  txt,
  jpeg,
  png,
  other,
}

/// Extension to convert file type to string
extension MyFileTypeExtension on MyFileType {
  String get name {
    switch (this) {
      case MyFileType.pdf:
        return 'pdf';
      case MyFileType.doc:
        return 'doc';
      case MyFileType.docx:
        return 'docx';
      case MyFileType.txt:
        return 'txt';
      case MyFileType.jpeg:
        return 'jpeg';
      case MyFileType.png:
        return 'png';
      case MyFileType.other:
        return 'other';
    }
  }

  static MyFileType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return MyFileType.pdf;
      case 'doc':
        return MyFileType.doc;
      case 'docx':
        return MyFileType.docx;
      case 'txt':
        return MyFileType.txt;
      case 'jpeg':
      case 'jpg':
        return MyFileType.jpeg;
      case 'png':
        return MyFileType.png;
      default:
        return MyFileType.other;
    }
  }
}

/// Represents a file uploaded to the system
class UploadedFile {
  final String id;
  final String name;
  final MyFileType type;
  final String size;
  final DateTime uploadDate;
  final Uint8List thumbnailData;
  final Uint8List? data;

  UploadedFile({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadDate,
    required this.thumbnailData,
    required this.data,
  });

  /// Creates a copy of this file with updated properties
  UploadedFile copyWith({
    String? id,
    String? name,
    MyFileType? type,
    String? size,
    DateTime? uploadDate,
    Uint8List? thumbnailData,
    Uint8List? data,
  }) {
    return UploadedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadDate: uploadDate ?? this.uploadDate,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      data: data ?? this.data,
    );
  }

  /// Converts the file to a map for storage (excluding binary data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'size': size,
      'uploadDate': uploadDate.millisecondsSinceEpoch,
    };
  }

  /// Creates an UploadedFile from a map
  factory UploadedFile.fromMap(Map<String, dynamic> map) {
    return UploadedFile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: MyFileTypeExtension.fromString(map['type'] ?? ''),
      size: map['size'] ?? '',
      uploadDate: DateTime.fromMillisecondsSinceEpoch(map['uploadDate'] ?? 0),
      thumbnailData: Uint8List.fromList([]), // Placeholder
      data: null, // Binary data not stored in map
    );
  }
}

/// Represents a file attached to a message
class AttachedFile {
  final String id;
  final String name;
  final MyFileType type;
  final String size;
  final Uint8List data;
  final String? prompt;
  final bool isExpanded;
  final String? originalPrompt;

  AttachedFile({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.data,
    this.prompt,
    this.isExpanded = false,
    this.originalPrompt,
  });

  /// Creates a copy of this file with updated properties
  AttachedFile copyWith({
    String? id,
    String? name,
    MyFileType? type,
    String? size,
    Uint8List? data,
    String? prompt,
    bool? isExpanded,
    String? originalPrompt,
  }) {
    return AttachedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      data: data ?? this.data,
      prompt: prompt ?? this.prompt,
      isExpanded: isExpanded ?? this.isExpanded,
      originalPrompt: originalPrompt ?? this.originalPrompt,
    );
  }

  bool get isImage {
    final extension = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  bool get isPdf {
    final extension = name.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  bool get isDocument {
    final extension = name.split('.').last.toLowerCase();
    return ['doc', 'docx', 'txt', 'rtf'].contains(extension);
  }

  /// Converts the file to a map for storage (excluding binary data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'size': size,
      'prompt': prompt,
      'isExpanded': isExpanded,
      'originalPrompt': originalPrompt,
    };
  }

  /// Creates an AttachedFile from a map
  factory AttachedFile.fromMap(Map<String, dynamic> map) {
    return AttachedFile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: MyFileTypeExtension.fromString(map['type'] ?? ''),
      size: map['size'] ?? '',
      data: Uint8List.fromList([]), // Binary data not stored in map
      prompt: map['prompt'],
      isExpanded: map['isExpanded'] ?? false,
      originalPrompt: map['originalPrompt'],
    );
  }
}
