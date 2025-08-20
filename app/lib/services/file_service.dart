import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/file_models.dart';
import '../constants/app_constants.dart';
import '../constants/enums.dart';

/// Service class to handle all file-related operations
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Pick multiple files from the device
  Future<List<AttachedFile>> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? FileTypeConstants.supportedExtensions,
        withData: true,
      );

      if (result != null) {
        List<AttachedFile> attachedFiles = [];
        
        for (var file in result.files) {
          if (file.bytes != null) {
            // Validate file size
            if (file.size > FileTypeConstants.maxFileSize) {
              debugPrint('File ${file.name} is too large (${file.size} bytes)');
              continue;
            }

            String extension = file.extension?.toLowerCase() ?? '';
            String fileId = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

            AttachedFile attachedFile = AttachedFile(
              id: fileId,
              name: file.name,
              type: _getFileTypeFromExtension(extension),
              size: _formatFileSize(file.size),
              data: file.bytes!,
            );

            attachedFiles.add(attachedFile);
          }
        }
        
        return attachedFiles;
      }
      
      return [];
    } catch (e) {
      debugPrint('Error picking files: $e');
      rethrow;
    }
  }

  /// Pick a single file for agent upload
  Future<AttachedFile?> pickSingleFileForAgent() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: FileTypeConstants.supportedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        var file = result.files.first;
        if (file.bytes != null) {
          // Validate file size
          if (file.size > FileTypeConstants.maxFileSize) {
            throw Exception('File is too large. Maximum size is ${_formatFileSize(FileTypeConstants.maxFileSize)}');
          }

          String extension = file.extension?.toLowerCase() ?? '';
          String fileId = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

          return AttachedFile(
            id: fileId,
            name: file.name,
            type: _getFileTypeFromExtension(extension),
            size: _formatFileSize(file.size),
            data: file.bytes!,
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking file for agent: $e');
      rethrow;
    }
  }

  /// Download a file to the user's device
  Future<void> downloadFile(UploadedFile file) async {
    try {
      if (file.data == null) {
        throw Exception('File data is not available');
      }

      final blob = html.Blob([file.data!]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = file.name;
        
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }

  /// Get MIME type from file extension
  String getMimeTypeFromExtension(String extension) {
    return FileTypeConstants.mimeTypes[extension.toLowerCase()] ?? 
           'application/octet-stream';
  }

  /// Validate file extension
  bool isValidFileExtension(String extension) {
    return FileTypeConstants.supportedExtensions.contains(extension.toLowerCase());
  }

  /// Validate file size
  bool isValidFileSize(int sizeInBytes) {
    return sizeInBytes <= FileTypeConstants.maxFileSize;
  }

  /// Create demo uploaded files for testing
  List<UploadedFile> createDemoFiles() {
    return [
      UploadedFile(
        id: '1',
        name: 'Employment_Contract_2024.pdf',
        type: MyFileType.pdf,
        size: '2.4 MB',
        uploadDate: DateTime.now().subtract(const Duration(hours: 1)),
        thumbnailData: _generatePdfThumbnail(),
        data: Uint8List.fromList([]), // Demo data
      ),
      UploadedFile(
        id: '2',
        name: 'Legal_Brief_Screenshot.png',
        type: MyFileType.png,
        size: '1.2 MB',
        uploadDate: DateTime.now().subtract(const Duration(hours: 3)),
        thumbnailData: _generateImageThumbnail(),
        data: Uint8List.fromList([]), // Demo data
      ),
      UploadedFile(
        id: '3',
        name: 'Client_Agreement.docx',
        type: MyFileType.docx,
        size: '856 KB',
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
        thumbnailData: _generateDocThumbnail(),
        data: Uint8List.fromList([]), // Demo data
      ),
    ];
  }

  /// Generate demo thumbnail data for PDF files
  Uint8List _generatePdfThumbnail() {
    // In a real implementation, this would generate an actual thumbnail
    return Uint8List.fromList([]);
  }

  /// Generate demo thumbnail data for image files
  Uint8List _generateImageThumbnail() {
    // In a real implementation, this would generate an actual thumbnail
    return Uint8List.fromList([]);
  }

  /// Generate demo thumbnail data for document files
  Uint8List _generateDocThumbnail() {
    // In a real implementation, this would generate an actual thumbnail
    return Uint8List.fromList([]);
  }

  /// Convert file extension to MyFileType enum
  MyFileType _getFileTypeFromExtension(String extension) {
    return MyFileTypeExtension.fromString(extension);
  }

  /// Format file size in bytes to human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Convert AttachedFile to UploadedFile
  UploadedFile attachedFileToUploadedFile(AttachedFile attachedFile) {
    return UploadedFile(
      id: attachedFile.id,
      name: attachedFile.name,
      type: attachedFile.type,
      size: attachedFile.size,
      uploadDate: DateTime.now(),
      thumbnailData: Uint8List.fromList([]), // Placeholder
      data: attachedFile.data,
    );
  }

  /// Convert UploadedFile to AttachedFile
  AttachedFile uploadedFileToAttachedFile(UploadedFile uploadedFile) {
    return AttachedFile(
      id: uploadedFile.id,
      name: uploadedFile.name,
      type: uploadedFile.type,
      size: uploadedFile.size,
      data: uploadedFile.data ?? Uint8List.fromList([]),
    );
  }

  /// Get file icon name based on file type
  String getFileIconName(MyFileType fileType) {
    switch (fileType) {
      case MyFileType.pdf:
        return 'picture_as_pdf';
      case MyFileType.doc:
      case MyFileType.docx:
        return 'description';
      case MyFileType.txt:
        return 'text_fields';
      case MyFileType.jpeg:
      case MyFileType.png:
        return 'image';
      case MyFileType.other:
      default:
        return 'insert_drive_file';
    }
  }

  /// Get file color based on file type
  String getFileColorHex(MyFileType fileType) {
    switch (fileType) {
      case MyFileType.pdf:
        return '#FF5722'; // Deep Orange
      case MyFileType.doc:
      case MyFileType.docx:
        return '#2196F3'; // Blue
      case MyFileType.txt:
        return '#9C27B0'; // Purple
      case MyFileType.jpeg:
      case MyFileType.png:
        return '#4CAF50'; // Green
      case MyFileType.other:
      default:
        return '#757575'; // Grey
    }
  }

  /// Chunk file data for streaming upload
  List<Uint8List> chunkFileData(Uint8List data, {int chunkSize = FileTypeConstants.chunkSize}) {
    List<Uint8List> chunks = [];
    for (int i = 0; i < data.length; i += chunkSize) {
      int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  /// Encode file to base64 for API transmission
  String encodeFileToBase64(Uint8List data) {
    return base64Encode(data);
  }

  /// Decode base64 string to file data
  Uint8List decodeBase64ToFile(String base64String) {
    return base64Decode(base64String);
  }

  /// Convert HTML File to AttachedFile for drag-and-drop support
  Future<AttachedFile> attachedFileFromHtmlFile(html.File f) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(f);
    await reader.onLoad.first;
    final buffer = reader.result as ByteBuffer;
    final bytes = Uint8List.view(buffer);

    // Derive type & size strings similarly to your other helpers
    final name = f.name;
    final sizeStr = _formatFileSize(bytes.length);

    // Guess file type from extension (reuse your existing getMimeTypeFromExtension or mapping)
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final type = _mapExtensionToMyFileType(ext);

    return AttachedFile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      type: type,
      size: sizeStr,
      data: bytes,
    );
  }

  /// Map extension to your MyFileType enum (minimal coverage)
  MyFileType _mapExtensionToMyFileType(String ext) {
    switch (ext) {
      case 'pdf': return MyFileType.pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp': return MyFileType.jpeg;
      case 'txt':
      case 'md': return MyFileType.txt;
      case 'doc':
      case 'docx': return MyFileType.doc;
      default: return MyFileType.other;
    }
  }
}
