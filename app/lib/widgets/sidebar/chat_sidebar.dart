import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import '../../constants/app_constants.dart';
import '../../constants/enums.dart';
import '../../models/chat_models.dart';
import '../../models/contact_model.dart';
import '../../models/file_models.dart';
import '../../controllers/app_ctrl.dart';
import '../../providers/chat_provider.dart';
import 'sidebar_header.dart';
import 'new_chat_button.dart';
import 'navigation_buttons.dart';
import 'chat_history_section.dart';
import 'sidebar_footer.dart';
import '../dialogs/settings_dialog.dart';

/// Main sidebar widget that contains chat history and documents
class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    Key? key,
    required this.currentSidebarMode,
    required this.chatHistory,
    required this.currentChatId,
    required this.legalDocuments,
    required this.onModeChanged,
    required this.onChatSelected,
    required this.onNewChat,
    required this.onChatDeleted,
    required this.onChatRenamed,
    required this.onDocumentSelected,
    required this.onDocumentUpload,
  }) : super(key: key);

  final SidebarMode currentSidebarMode;
  final List<ChatSession> chatHistory;
  final String? currentChatId;
  final List<dynamic> legalDocuments; // Using dynamic for now to avoid import issues
  final Function(SidebarMode) onModeChanged;
  final Function(ChatSession) onChatSelected;
  final VoidCallback onNewChat;
  final Function(ChatSession) onChatDeleted;
  final Function(ChatSession, String) onChatRenamed;
  final void Function(UploadedFile?) onDocumentSelected;
  final VoidCallback onDocumentUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SidebarHeader(),
          const SizedBox(height: AppSizes.paddingXLarge),
          NewChatButton(onPressed: onNewChat),
          NavigationButtons(
            currentMode: currentSidebarMode,
            onModeChanged: onModeChanged,
          ),
          
          // Export/Import/Clear actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Export
                IconButton(
                  tooltip: 'Export current chat',
                  icon: const Icon(Icons.download_rounded, size: 18),
                  onPressed: () {
                    final json = context.read<ChatProvider>().exportCurrentChatAsJson();
                    if (json.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No chat to export'), behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    // Copy to clipboard for simplicity
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat exported to JSON (copied to clipboard)'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                // Import
                IconButton(
                  tooltip: 'Import chat JSON',
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom, allowedExtensions: ['json'], withData: true,
                    );
                    if (result != null && result.files.isNotEmpty && result.files.single.bytes != null) {
                      final data = utf8.decode(result.files.single.bytes!);
                      final ok = context.read<ChatProvider>().importChatFromJson(data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Chat imported' : 'Failed to import chat'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                // Clear all
                IconButton(
                  tooltip: 'Clear all chats',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    context.read<ChatProvider>().clearAllChats();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All chats cleared'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
          ),
          
          ChatHistorySection(
            currentMode: currentSidebarMode,
            chatHistory: chatHistory,
            currentChatId: currentChatId,
            legalDocuments: legalDocuments,
            onChatSelected: onChatSelected,
            onChatDeleted: onChatDeleted,
            onChatRenamed: onChatRenamed,
            onDocumentSelected: onDocumentSelected,
            onDocumentUpload: onDocumentUpload,
          ),
          SidebarFooter(
            onSettingsPressed: () => _showSettings(context),
            onCallPressed: () => _showCallDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showCallDialog(BuildContext context) {
    // This will be implemented when we extract the call dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Call'),
        content: Text('Call dialog will be implemented'),
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
