import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/chat_models.dart';
import 'message_bubble.dart';

/// Widget that displays a scrollable list of chat messages
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.isVoiceMode = false,
    this.isProcessingAI = false,
  }) : super(key: key);

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isVoiceMode;
  final bool isProcessingAI;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && messages.isNotEmpty) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXLarge),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(
          top: AppSizes.paddingXXLarge,
          bottom: AppSizes.paddingXXLarge * 2,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return MessageBubble(
            message: message,
            isVoiceMode: isVoiceMode,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXXLarge * 2),
      child: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.1),
                  AppColors.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusXXLarge),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 64,
              color: AppColors.primaryGreen.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSizes.paddingXXLarge),
          Text(
            'Welcome to Legal Assistant',
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeXXLarge + 4,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            isVoiceMode
                ? 'Voice mode is ready. Start speaking to begin your legal consultation.'
                : 'Start a conversation by typing your legal question below.',
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeLarge,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingXLarge),
          if (!isVoiceMode) ...[
            _buildSuggestionChip('Review my contract'),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildSuggestionChip('Explain legal terms'),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildSuggestionChip('Estate planning help'),
          ],
        ]),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.paddingSmall + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusXXLarge),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: AppSizes.iconSmall,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
