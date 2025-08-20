import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../constants/app_constants.dart';
import '../../models/chat_models.dart';
import '../../models/file_models.dart';
import '../file/attached_file_display.dart';
import '../../utils/text_formatter.dart';

/// Individual message bubble widget
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    Key? key,
    required this.message,
    this.isVoiceMode = false,
  }) : super(key: key);

  final ChatMessage message;
  final bool isVoiceMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: AppSizes.paddingMedium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context),
                if (message.attachedFiles.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingSmall),
                  _buildAttachments(),
                ],
                const SizedBox(height: AppSizes.paddingXSmall),
                _buildTimestamp(),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: AppSizes.paddingMedium),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF1E5A2E)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.psychology_outlined,
        color: Colors.white,
        size: AppSizes.iconLarge,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentBlue, Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.white,
        size: AppSizes.iconLarge,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Handle typing indicator
    if (message.isTyping == true) {
      return _buildTypingIndicator();
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        gradient: message.isUser
            ? const LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF1E5A2E)],
              )
            : null,
        color: message.isUser ? null : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: message.isUser ? null : Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(message.isUser ? 0.1 : 0.03),
            blurRadius: message.isUser ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVoiceMode && message.isUser) ...[
            Row(
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: AppSizes.iconSmall,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: AppSizes.paddingXSmall),
                Text(
                  'Voice Input',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),
          ],
          RichText(
            text: TextFormatter.parseFormattedText(message.text, message.isUser),
          ),
          if (!message.isUser && (message.isTyping != true)) 
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: message.text));
                  // lightweight feedback
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  messenger?.hideCurrentSnackBar();
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypingDot(0),
          const SizedBox(width: AppSizes.paddingXSmall),
          _buildTypingDot(1),
          const SizedBox(width: AppSizes.paddingXSmall),
          _buildTypingDot(2),
          const SizedBox(width: AppSizes.paddingMedium),
          Text(
            'Processing...',
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('typing_dot_$index'),
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      onEnd: () {
        // This will cause the animation to repeat
      },
      builder: (context, value, child) {
        final animationValue = math.sin((value + (index * 0.2)) * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, animationValue * 3),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachments() {
    return Column(
      children: message.attachedFiles.map((file) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: AttachedFileDisplay(
            file: file,
            isInMessage: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      _formatTimestamp(message.timestamp),
      style: GoogleFonts.inter(
        fontSize: AppSizes.fontSizeSmall,
        color: AppColors.textSecondary.withOpacity(0.6),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
