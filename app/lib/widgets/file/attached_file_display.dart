import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/file_models.dart';
import '../common/file_type_icon.dart';

/// Widget for displaying attached files in messages or input areas
class AttachedFileDisplay extends StatelessWidget {
  const AttachedFileDisplay({
    Key? key,
    required this.file,
    this.isInMessage = false,
    this.onRemove,
    this.onPreview,
    this.onPromptEdit,
  }) : super(key: key);

  final AttachedFile file;
  final bool isInMessage;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;
  final VoidCallback? onPromptEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: isInMessage 
            ? Colors.white.withOpacity(0.1)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: isInMessage 
              ? Colors.white.withOpacity(0.2)
              : AppColors.borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              FileTypeIcon(
                fileType: file.type,
                size: AppSizes.iconXLarge + 4,
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w500,
                        color: isInMessage 
                            ? Colors.white.withOpacity(0.9)
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.paddingXSmall),
                    Row(
                      children: [
                        Text(
                          file.size,
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeSmall,
                            color: isInMessage 
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (file.prompt != null && file.prompt!.isNotEmpty) ...[
                          const SizedBox(width: AppSizes.paddingSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingXSmall,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isInMessage
                                  ? Colors.white.withOpacity(0.2)
                                  : AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: AppSizes.fontSizeSmall,
                                  color: isInMessage
                                      ? Colors.white.withOpacity(0.8)
                                      : AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Instructions',
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.fontSizeSmall - 1,
                                    fontWeight: FontWeight.w600,
                                    color: isInMessage
                                        ? Colors.white.withOpacity(0.8)
                                        : AppColors.primaryGreen,
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
              if (!isInMessage) ...[
                const SizedBox(width: AppSizes.paddingSmall),
                _buildActionButtons(),
              ],
            ],
          ),
          if (file.prompt != null && file.prompt!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            _buildPromptDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPreview != null)
          _buildActionButton(
            icon: Icons.visibility_outlined,
            color: AppColors.accentBlue,
            onPressed: onPreview!,
            tooltip: 'Preview',
          ),
        if (onPromptEdit != null) ...[
          const SizedBox(width: AppSizes.paddingXSmall),
          _buildActionButton(
            icon: Icons.edit_outlined,
            color: AppColors.primaryGreen,
            onPressed: onPromptEdit!,
            tooltip: 'Edit Instructions',
          ),
        ],
        if (onRemove != null) ...[
          const SizedBox(width: AppSizes.paddingXSmall),
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.accentRed,
            onPressed: onRemove!,
            tooltip: 'Remove',
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
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
      ),
    );
  }

  Widget _buildPromptDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingSmall),
      decoration: BoxDecoration(
        color: isInMessage
            ? Colors.white.withOpacity(0.05)
            : AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
        border: Border.all(
          color: isInMessage
              ? Colors.white.withOpacity(0.1)
              : AppColors.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: AppSizes.iconSmall,
            color: isInMessage
                ? Colors.white.withOpacity(0.7)
                : AppColors.primaryGreen,
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: Text(
              file.prompt!,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeSmall,
                color: isInMessage
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

