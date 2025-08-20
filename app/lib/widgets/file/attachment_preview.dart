import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/file_models.dart';

/// Attachment preview with professional styling and prompt editing
class AttachmentPreview extends StatefulWidget {
  const AttachmentPreview({
    Key? key,
    required this.attachedFiles,
    required this.onRemoveFile,
    required this.onUpdatePrompt,
    required this.onClearAll,
  }) : super(key: key);

  final List<AttachedFile> attachedFiles;
  final Function(AttachedFile) onRemoveFile;
  final Function(AttachedFile, String) onUpdatePrompt;
  final VoidCallback onClearAll;

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  final Map<String, TextEditingController> _promptControllers = {};
  final Map<String, bool> _expandedFiles = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(AttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attachedFiles != oldWidget.attachedFiles) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _promptControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    // Only recreate controllers for new files or remove controllers for missing files
    final currentFileIds = widget.attachedFiles.map((f) => f.id).toSet();
    final existingControllerIds = _promptControllers.keys.toSet();

    // Remove controllers for files that are no longer present
    final toRemove = existingControllerIds.difference(currentFileIds);
    for (final id in toRemove) {
      _promptControllers[id]?.dispose();
      _promptControllers.remove(id);
      _expandedFiles.remove(id);
    }

    // Add controllers for new files
    for (final file in widget.attachedFiles) {
      if (!_promptControllers.containsKey(file.id)) {
        _promptControllers[file.id] = TextEditingController(text: file.prompt ?? '');
      } else {
        // Update existing controller text if the prompt changed externally
        final controller = _promptControllers[file.id]!;
        if (controller.text != (file.prompt ?? '')) {
          // Only update if the text is different to avoid cursor issues
          final cursorPosition = controller.selection.baseOffset;
          controller.text = file.prompt ?? '';
          // Restore cursor position if it's still valid
          if (cursorPosition <= controller.text.length) {
            controller.selection = TextSelection.collapsed(offset: cursorPosition);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXXLarge,
        vertical: AppSizes.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFileList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.borderRadiusMedium),
          topRight: Radius.circular(AppSizes.borderRadiusMedium),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.attach_file_rounded,
              color: AppColors.accentBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.attachedFiles.length} file${widget.attachedFiles.length == 1 ? '' : 's'} attached',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Add prompts to specify how each file should be analyzed',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: widget.onClearAll,
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Clear All'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentRed,
              textStyle: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: widget.attachedFiles
          .map((file) => _buildFileItem(file))
          .toList(),
    );
  }

  Widget _buildFileItem(AttachedFile file) {
    final isExpanded = _expandedFiles[file.id] ?? false;
    final controller = _promptControllers[file.id]!;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpanded(file.id),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Row(
                children: [
                  _buildFileIcon(file.type),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeLarge,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatFileSize(file.size),
                              style: GoogleFonts.inter(
                                fontSize: AppSizes.fontSizeMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getFileTypeText(file.type),
                              style: GoogleFonts.inter(
                                fontSize: AppSizes.fontSizeMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (file.prompt != null && file.prompt!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Prompt added',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                  ],
                  IconButton(
                    onPressed: () => widget.onRemoveFile(file),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.accentRed,
                      size: 18,
                    ),
                    tooltip: 'Remove file',
                  ),
                  Icon(
                    isExpanded 
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildPromptEditor(file, controller),
        ],
      ),
    );
  }

  Widget _buildFileIcon(MyFileType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case MyFileType.pdf:
        iconData = Icons.picture_as_pdf_outlined;
        iconColor = AppColors.accentRed;
        break;
      case MyFileType.doc:
      case MyFileType.docx:
        iconData = Icons.description_outlined;
        iconColor = AppColors.accentBlue;
        break;
      case MyFileType.txt:
        iconData = Icons.text_snippet_outlined;
        iconColor = AppColors.textSecondary;
        break;
      case MyFileType.jpeg:
      case MyFileType.png:
        iconData = Icons.image_outlined;
        iconColor = AppColors.accentPurple;
        break;
      default:
        iconData = Icons.insert_drive_file_outlined;
        iconColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildPromptEditor(AttachedFile file, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Analysis Prompt',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            'Specify how you want this file to be analyzed or what questions you have about it.',
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          TextField(
            controller: controller,
            maxLines: 3,
            onChanged: (value) {
              // Update the prompt but avoid infinite loops
              if (value != file.prompt) {
                widget.onUpdatePrompt(file, value);
              }
            },
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'e.g., "Summarize the key legal points" or "What are the main risks mentioned?"',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryGreen),
              ),
              contentPadding: const EdgeInsets.all(AppSizes.paddingLarge),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              const Spacer(),
              if (controller.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    controller.clear();
                    widget.onUpdatePrompt(file, '');
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleExpanded(String fileId) {
    setState(() {
      _expandedFiles[fileId] = !(_expandedFiles[fileId] ?? false);
    });
  }

  String _formatFileSize(String size) {
    // If size is already formatted, return as-is
    if (size.contains('B') || size.contains('KB') || size.contains('MB')) {
      return size;
    }
    
    // Try to parse as bytes if it's a number
    try {
      final bytes = int.parse(size);
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } catch (e) {
      return size; // Return as-is if not parseable
    }
  }

  String _getFileTypeText(MyFileType type) {
    switch (type) {
      case MyFileType.pdf:
        return 'PDF Document';
      case MyFileType.doc:
        return 'Word Document';
      case MyFileType.docx:
        return 'Word Document';
      case MyFileType.txt:
        return 'Text File';
      case MyFileType.jpeg:
        return 'JPEG Image';
      case MyFileType.png:
        return 'PNG Image';
      default:
        return 'Document';
    }
  }
}