import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/chat_models.dart';

/// Individual chat item in the sidebar chat list
class ChatItem extends StatelessWidget {
  const ChatItem({
    Key? key,
    required this.chat,
    required this.isCurrentChat,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  }) : super(key: key);

  final ChatSession chat;
  final bool isCurrentChat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onRename;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: isCurrentChat
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    chat.title,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.fontSizeMedium + 1,
                      fontWeight: FontWeight.w400,
                      color: isCurrentChat 
                          ? AppColors.primaryGreen 
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: AppSizes.iconSmall,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      height: 32,
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Text(
                            'Rename',
                            style: GoogleFonts.inter(fontSize: AppSizes.fontSizeMedium),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 32,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: AppSizes.iconSmall,
                            color: AppColors.accentRed,
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Text(
                            'Delete',
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.fontSizeMedium,
                              color: AppColors.accentRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameDialog(context);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: chat.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingSmall - 2),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primaryGreen,
                size: AppSizes.iconMedium,
              ),
            ),
            const SizedBox(width: AppSizes.paddingMedium),
            Text(
              'Rename Chat',
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeXLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter new chat title...',
            hintStyle: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeLarge,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            contentPadding: const EdgeInsets.all(AppSizes.paddingMedium),
          ),
          style: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeLarge,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onRename(newTitle);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingSmall - 2),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.accentRed,
                size: AppSizes.iconMedium,
              ),
            ),
            const SizedBox(width: AppSizes.paddingMedium),
            Text(
              'Delete Chat',
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeXLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${chat.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeLarge,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

