import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/file_models.dart';
import '../common/file_type_icon.dart';

/// Panel for previewing and analyzing selected files
class FilePreviewPanel extends StatefulWidget {
  const FilePreviewPanel({
    Key? key,
    required this.file,
    required this.onClose,
    required this.onDownload,
    required this.onAnalyze,
  }) : super(key: key);

  final UploadedFile file;
  final VoidCallback onClose;
  final Function(UploadedFile) onDownload;
  final Function(String) onAnalyze;

  @override
  State<FilePreviewPanel> createState() => _FilePreviewPanelState();
}

class _FilePreviewPanelState extends State<FilePreviewPanel> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.filePreviewPanelWidth,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          left: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXLarge),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Preview',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXSmall),
                Text(
                  widget.file.name,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
              child: const Icon(
                Icons.close,
                size: AppSizes.iconMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFileInfo(),
          const SizedBox(height: AppSizes.paddingXLarge),
          _buildActionButtons(),
          const SizedBox(height: AppSizes.paddingXLarge),
          _buildAnalysisSection(),
          const Spacer(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FileTypeIcon(
                fileType: widget.file.type,
                size: AppSizes.iconXLarge + 8,
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.file.name,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.paddingXSmall),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSmall - 2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getFileTypeColor(widget.file.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusXSmall),
                          ),
                          child: Text(
                            widget.file.size,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: _getFileTypeColor(widget.file.type),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(
                          _formatUploadDate(widget.file.uploadDate),
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.download_outlined,
            label: 'Download',
            color: AppColors.accentBlue,
            onPressed: () => widget.onDownload(widget.file),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMedium),
        Expanded(
          child: _buildActionButton(
            icon: Icons.visibility_outlined,
            label: 'View',
            color: AppColors.primaryGreen,
            onPressed: _showViewDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconLarge),
            const SizedBox(height: AppSizes.paddingXSmall),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Analysis',
          style: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeXLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Text(
          'What would you like to know about this file?',
          style: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeLarge,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  hintText: AppStrings.filePromptHint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeLarge,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppSizes.paddingMedium),
                ),
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeLarge,
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
              ),
              _buildQuickPrompts(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildQuickPromptButton('Summarize', 'Provide a comprehensive summary of this document')),
          Container(width: 1, height: 40, color: AppColors.borderColor),
          Expanded(child: _buildQuickPromptButton('Key Points', 'Extract and list the key points from this document')),
          Container(width: 1, height: 40, color: AppColors.borderColor),
          Expanded(child: _buildQuickPromptButton('Legal Analysis', 'Analyze the legal implications and important clauses in this document')),
        ],
      ),
    );
  }

  Widget _buildQuickPromptButton(String title, String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _promptController.text = prompt,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final prompt = _promptController.text.trim();
          if (prompt.isNotEmpty) {
            widget.onAnalyze(prompt);
          } else {
            widget.onAnalyze("Please analyze this file and tell me what it contains.");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.fontSizeLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: AppSizes.iconMedium),
            const SizedBox(width: AppSizes.paddingSmall - 2),
            Text(
              'Analyze with Gemini',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileTypeColor(MyFileType fileType) {
    switch (fileType) {
      case MyFileType.pdf:
        return const Color(0xFFFF5722);
      case MyFileType.doc:
      case MyFileType.docx:
        return AppColors.accentBlue;
      case MyFileType.txt:
        return AppColors.accentPurple;
      case MyFileType.jpeg:
      case MyFileType.png:
        return AppColors.accentGreen;
      case MyFileType.other:
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatUploadDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showViewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File Viewer'),
        content: Text('File viewer would be implemented here for ${widget.file.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

