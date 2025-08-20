import 'package:flutter/foundation.dart';

import '../models/file_models.dart';
import '../constants/enums.dart';
import '../services/file_service.dart';
import '../services/livekit_service.dart';

/// Provider for managing file state and operations
class FileProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  final LiveKitService _liveKitService = LiveKitService();

  // File state
  List<UploadedFile> _legalDocuments = [];
  UploadedFile? _selectedFilePreview;
  FileUploadState _uploadState = FileUploadState.idle;
  FileUploadState _agentUploadState = FileUploadState.idle;

  // Progress tracking
  double _uploadProgress = 0.0;
  String? _uploadError;

  // Getters
  List<UploadedFile> get legalDocuments => List.unmodifiable(_legalDocuments);
  UploadedFile? get selectedFilePreview => _selectedFilePreview;
  FileUploadState get uploadState => _uploadState;
  FileUploadState get agentUploadState => _agentUploadState;
  double get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;
  bool get isUploading => _uploadState.isLoading;
  bool get isUploadingToAgent => _agentUploadState.isLoading;

  /// Initialize the file provider
  void initialize() {
    _loadDemoDocuments();
  }

  /// Load demo documents for testing
  void _loadDemoDocuments() {
    _legalDocuments = _fileService.createDemoFiles();
    notifyListeners();
  }

  /// Select file for preview
  void selectFileForPreview(UploadedFile? file) {
    _selectedFilePreview = file;
    notifyListeners();
  }

  /// Upload documents to the app
  Future<void> uploadDocuments() async {
    try {
      _setUploadState(FileUploadState.picking);
      
      final attachedFiles = await _fileService.pickFiles();
      
      if (attachedFiles.isNotEmpty) {
        _setUploadState(FileUploadState.uploading);
        
        // Convert attached files to uploaded files and add to documents
        for (var attachedFile in attachedFiles) {
          final uploadedFile = _fileService.attachedFileToUploadedFile(attachedFile);
          _legalDocuments.insert(0, uploadedFile); // Add to beginning
        }
        
        _setUploadState(FileUploadState.completed);
        _uploadProgress = 1.0;
        
        // Reset after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          _setUploadState(FileUploadState.idle);
          _uploadProgress = 0.0;
        });
      } else {
        _setUploadState(FileUploadState.idle);
      }
    } catch (e) {
      _setUploadError('Error uploading documents: $e');
    }
  }

  /// Upload file directly to LiveKit agent
  Future<void> uploadFileToAgent() async {
    try {
      _setAgentUploadState(FileUploadState.picking);
      
      final attachedFile = await _fileService.pickSingleFileForAgent();
      
      if (attachedFile != null) {
        _setAgentUploadState(FileUploadState.uploading);
        
        // Send file to LiveKit agent
        await _liveKitService.sendFileToAgent(
          attachedFile.data,
          attachedFile.name,
          _getFileExtension(attachedFile.name),
        );
        
        _setAgentUploadState(FileUploadState.completed);
        
        // Reset after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          _setAgentUploadState(FileUploadState.idle);
        });
      } else {
        _setAgentUploadState(FileUploadState.idle);
      }
    } catch (e) {
      _setAgentUploadError('Error sending file to agent: $e');
    }
  }

  /// Download a file
  Future<void> downloadFile(UploadedFile file) async {
    try {
      await _fileService.downloadFile(file);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }

  /// Remove a document from the list
  void removeDocument(UploadedFile file) {
    _legalDocuments.removeWhere((doc) => doc.id == file.id);
    
    // Clear preview if the removed file was selected
    if (_selectedFilePreview?.id == file.id) {
      _selectedFilePreview = null;
    }
    
    notifyListeners();
  }

  /// Add a new document to the list
  void addDocument(UploadedFile file) {
    _legalDocuments.insert(0, file);
    notifyListeners();
  }

  /// Get file icon name for UI display
  String getFileIconName(MyFileType fileType) {
    return _fileService.getFileIconName(fileType);
  }

  /// Get file color for UI display
  String getFileColorHex(MyFileType fileType) {
    return _fileService.getFileColorHex(fileType);
  }

  /// Check if file extension is supported
  bool isValidFileExtension(String extension) {
    return _fileService.isValidFileExtension(extension);
  }

  /// Check if file size is valid
  bool isValidFileSize(int sizeInBytes) {
    return _fileService.isValidFileSize(sizeInBytes);
  }

  /// Get MIME type for file extension
  String getMimeType(String extension) {
    return _fileService.getMimeTypeFromExtension(extension);
  }

  /// Clear all documents
  void clearAllDocuments() {
    _legalDocuments.clear();
    _selectedFilePreview = null;
    notifyListeners();
  }

  /// Get file statistics
  Map<String, dynamic> getFileStatistics() {
    int totalFiles = _legalDocuments.length;
    int totalSize = 0;
    Map<MyFileType, int> typeCount = {};
    
    for (var doc in _legalDocuments) {
      // Add to type count
      typeCount[doc.type] = (typeCount[doc.type] ?? 0) + 1;
      
      // Calculate total size (would need actual file sizes)
      // For now, this is placeholder
    }
    
    return {
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'typeBreakdown': typeCount,
      'lastUpload': _legalDocuments.isNotEmpty ? _legalDocuments.first.uploadDate : null,
    };
  }

  /// Set upload state and notify listeners
  void _setUploadState(FileUploadState state) {
    _uploadState = state;
    if (state != FileUploadState.error) {
      _uploadError = null;
    }
    notifyListeners();
  }

  /// Set agent upload state and notify listeners
  void _setAgentUploadState(FileUploadState state) {
    _agentUploadState = state;
    if (state != FileUploadState.error) {
      _uploadError = null;
    }
    notifyListeners();
  }

  /// Set upload error and notify listeners
  void _setUploadError(String error) {
    _uploadError = error;
    _uploadState = FileUploadState.error;
    notifyListeners();
    
    // Reset error after some time
    Future.delayed(const Duration(seconds: 5), () {
      if (_uploadState == FileUploadState.error) {
        _setUploadState(FileUploadState.idle);
      }
    });
  }

  /// Set agent upload error and notify listeners
  void _setAgentUploadError(String error) {
    _uploadError = error;
    _agentUploadState = FileUploadState.error;
    notifyListeners();
    
    // Reset error after some time
    Future.delayed(const Duration(seconds: 5), () {
      if (_agentUploadState == FileUploadState.error) {
        _setAgentUploadState(FileUploadState.idle);
      }
    });
  }

  /// Extract file extension from filename
  String _getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Search documents by name
  List<UploadedFile> searchDocuments(String query) {
    if (query.isEmpty) return _legalDocuments;
    
    return _legalDocuments.where((doc) =>
      doc.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  /// Filter documents by type
  List<UploadedFile> filterDocumentsByType(MyFileType? type) {
    if (type == null) return _legalDocuments;
    
    return _legalDocuments.where((doc) => doc.type == type).toList();
  }

  /// Sort documents by various criteria
  List<UploadedFile> sortDocuments(String criteria, {bool ascending = true}) {
    final sorted = List<UploadedFile>.from(_legalDocuments);
    
    switch (criteria.toLowerCase()) {
      case 'name':
        sorted.sort((a, b) => ascending 
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
        break;
      case 'date':
        sorted.sort((a, b) => ascending 
          ? a.uploadDate.compareTo(b.uploadDate)
          : b.uploadDate.compareTo(a.uploadDate));
        break;
      case 'type':
        sorted.sort((a, b) => ascending 
          ? a.type.name.compareTo(b.type.name)
          : b.type.name.compareTo(a.type.name));
        break;
      case 'size':
        // Would need actual file size comparison
        break;
    }
    
    return sorted;
  }

  // File attachment methods for message input
  List<AttachedFile> _attachedFiles = [];
  
  /// Get the list of attached files for message input
  List<AttachedFile> get attachedFiles => List.unmodifiable(_attachedFiles);

  /// Add files to attachments for message input
  Future<void> addAttachments() async {
    try {
      final files = await _fileService.pickFiles();
      _attachedFiles.addAll(files);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding attachments: $e');
    }
  }

  /// Add prebuilt attachments from drag-and-drop
  Future<void> addAttachmentsFromList(List<AttachedFile> files) async {
    try {
      _attachedFiles.addAll(files);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding dropped attachments: $e');
    }
  }

  /// Remove a file from attachments
  void removeAttachedFile(AttachedFile file) {
    _attachedFiles.removeWhere((f) => f.id == file.id);
    notifyListeners();
  }

  /// Update the prompt for an attached file
  void updateFilePrompt(AttachedFile file, String prompt) {
    final index = _attachedFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _attachedFiles[index] = file.copyWith(prompt: prompt);
      notifyListeners();
    }
  }

  /// Toggle expansion state for file prompt editing
  void toggleFileExpansion(AttachedFile file) {
    final index = _attachedFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      final currentFile = _attachedFiles[index];
      _attachedFiles[index] = currentFile.copyWith(
        isExpanded: !currentFile.isExpanded,
        originalPrompt: currentFile.isExpanded ? null : currentFile.prompt,
      );
      notifyListeners();
    }
  }

  /// Clear all attached files
  void clearAttachedFiles() {
    _attachedFiles.clear();
    notifyListeners();
  }
}
