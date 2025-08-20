import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/file_models.dart';
import '../common/file_type_icon.dart';

/// Individual attached file item with prompt editing capabilities
class AttachedFileItem extends StatefulWidget {
  const AttachedFileItem({
    Key? key,
    required this.file,
    required this.onRemove,
    required this.onUpdatePrompt,
    required this.onToggleExpansion,
  }) : super(key: key);

  final AttachedFile file;
  final VoidCallback onRemove;
  final Function(String) onUpdatePrompt;
  final VoidCallback onToggleExpansion;

  @override
  State<AttachedFileItem> createState() => _AttachedFileItemState();
}

class _AttachedFileItemState extends State<AttachedFileItem> {
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.file.prompt ?? '');
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPrompt = widget.file.prompt != null && widget.file.prompt!.isNotEmpty;
    final isPromptLocked = !widget.file.isExpanded && hasPrompt;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingSmall + 2),
            child: Row(
              children: [
                FileTypeIcon(
                  fileType: widget.file.type,
                  size: AppSizes.iconXLarge + 4,
                ),
                const SizedBox(width: AppSizes.paddingSmall + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.name,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            widget.file.size,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (hasPrompt) ...[
                            const SizedBox(width: AppSizes.paddingSmall - 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingXSmall,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPromptLocked
                                        ? Icons.lock_outline
                                        : Icons.edit_outlined,
                                    size: AppSizes.fontSizeSmall,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Instructions',
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.fontSizeSmall - 1,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactButton(
                      icon: Icons.visibility_outlined,
                      color: AppColors.accentBlue,
                      onPressed: _previewFile,
                    ),
                    const SizedBox(width: 2),
                    _buildCompactButton(
                      icon: widget.file.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.add_comment_outlined,
                      color: AppColors.primaryGreen,
                      onPressed: widget.onToggleExpansion,
                    ),
                    const SizedBox(width: 2),
                    _buildCompactButton(
                      icon: Icons.close,
                      color: AppColors.accentRed,
                      onPressed: widget.onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPromptLocked) _buildLockedPromptDisplay(),
          if (widget.file.isExpanded) _buildPromptEditor(),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusXSmall),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingXSmall),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusXSmall),
          ),
          child: Icon(
            icon,
            size: AppSizes.iconSmall,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildLockedPromptDisplay() {
    return GestureDetector(
      onTap: widget.onToggleExpansion,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          AppSizes.paddingSmall + 2,
          0,
          AppSizes.paddingSmall + 2,
          AppSizes.paddingSmall + 2,
        ),
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: AppSizes.fontSizeSmall,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: AppSizes.paddingSmall - 2),
            Expanded(
              child: Text(
                widget.file.prompt!,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.edit_outlined,
                size: AppSizes.fontSizeSmall,
                color: AppColors.primaryGreen.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptEditor() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingSmall + 2,
        0,
        AppSizes.paddingSmall + 2,
        AppSizes.paddingSmall + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.comment_outlined,
                size: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.paddingXSmall),
              Text(
                'Instructions for this file:',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall - 2),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: AppStrings.filePromptHint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: AppSizes.fontSizeSmall + 1,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSizes.paddingSmall),
                    isDense: true,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeSmall + 1,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _cancelPromptEdit,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(AppSizes.borderRadiusSmall + 2),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingSmall,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.close,
                                    size: AppSizes.fontSizeMedium,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSizes.paddingXSmall),
                                  Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.fontSizeSmall,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        height: 30,
                        color: AppColors.borderColor,
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _savePrompt,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(AppSizes.borderRadiusSmall + 2),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingSmall,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: AppSizes.fontSizeMedium,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: AppSizes.paddingXSmall),
                                  Text(
                                    'Done',
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.fontSizeSmall,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _previewFile() {
    // This would show a preview of the file
    // For now, just a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File Preview'),
        content: Text('Preview for ${widget.file.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _savePrompt() {
    final newPrompt = _promptController.text.trim();
    widget.onUpdatePrompt(newPrompt.isEmpty ? '' : newPrompt);
    widget.onToggleExpansion();
  }

  void _cancelPromptEdit() {
    _promptController.text = widget.file.originalPrompt ?? '';
    widget.onToggleExpansion();
  }
}

