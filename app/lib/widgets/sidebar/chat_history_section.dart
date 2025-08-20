import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../constants/enums.dart';
import '../../models/chat_models.dart';
import '../../models/file_models.dart';
import 'chat_mode_content.dart';
import 'documents_mode_content.dart';

/// Section that displays chat history or documents based on current mode
class ChatHistorySection extends StatelessWidget {
  const ChatHistorySection({
    Key? key,
    required this.currentMode,
    required this.chatHistory,
    required this.currentChatId,
    required this.legalDocuments,
    required this.onChatSelected,
    required this.onChatDeleted,
    required this.onChatRenamed,
    required this.onDocumentSelected,
    required this.onDocumentUpload,
  }) : super(key: key);

  final SidebarMode currentMode;
  final List<ChatSession> chatHistory;
  final String? currentChatId;
  final List<dynamic> legalDocuments;
  final Function(ChatSession) onChatSelected;
  final Function(ChatSession) onChatDeleted;
  final Function(ChatSession, String) onChatRenamed;
  final void Function(UploadedFile?) onDocumentSelected;
  final VoidCallback onDocumentUpload;

  @override
  Widget build(BuildContext context) {
    switch (currentMode) {
      case SidebarMode.chat:
        return ChatModeContent(
          chatHistory: chatHistory,
          currentChatId: currentChatId,
          onChatSelected: onChatSelected,
          onChatDeleted: onChatDeleted,
          onChatRenamed: onChatRenamed,
        );
      case SidebarMode.documents:
        return DocumentsModeContent(
          legalDocuments: legalDocuments,
          onDocumentSelected: onDocumentSelected,
          onDocumentUpload: onDocumentUpload,
        );
    }
  }
}
