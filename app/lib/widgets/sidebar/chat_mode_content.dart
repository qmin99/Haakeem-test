import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/chat_models.dart';
import 'chat_item.dart';

/// Content widget for chat mode in sidebar
class ChatModeContent extends StatelessWidget {
  const ChatModeContent({
    Key? key,
    required this.chatHistory,
    required this.currentChatId,
    required this.onChatSelected,
    required this.onChatDeleted,
    required this.onChatRenamed,
  }) : super(key: key);

  final List<ChatSession> chatHistory;
  final String? currentChatId;
  final Function(ChatSession) onChatSelected;
  final Function(ChatSession) onChatDeleted;
  final Function(ChatSession, String) onChatRenamed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
              vertical: AppSizes.paddingSmall,
            ),
            child: Row(
              children: [
                Text(
                  'Chat History',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (chatHistory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSmall - 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                    ),
                    child: Text(
                      '${chatHistory.length}',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: chatHistory.isEmpty
                ? _buildEmptyChatsState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLarge,
                      0,
                      AppSizes.paddingLarge,
                      80,
                    ),
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = chatHistory[index];
                      final isCurrentChat = currentChatId == chat.id;
                      return ChatItem(
                        chat: chat,
                        isCurrentChat: isCurrentChat,
                        onTap: () => onChatSelected(chat),
                        onDelete: () => onChatDeleted(chat),
                        onRename: (newTitle) => onChatRenamed(chat, newTitle),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Text(
              AppStrings.chatHistoryEmpty,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall - 2),
            Text(
              AppStrings.chatHistoryEmptySubtitle,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

