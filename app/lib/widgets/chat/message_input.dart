import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;

import '../../constants/app_constants.dart';
import '../../providers/chat_provider.dart';
import '../../providers/voice_provider.dart';
import '../../providers/file_provider.dart';
import '../../controllers/app_ctrl.dart' as app_ctrl;
import '../voice/voice_input_button.dart';
import '../file/attachment_preview.dart';
import 'package:flutter/services.dart';

/// Widget for message input with voice capabilities and file attachments
class MessageInput extends StatefulWidget {
  const MessageInput({
    Key? key,
    this.isVoiceMode = false,
    this.onSendMessage,
  }) : super(key: key);

  final bool isVoiceMode;
  final Function(String)? onSendMessage;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late TextEditingController _messageController;
  final FocusNode _focusNode = FocusNode();
  bool _isFileUploading = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ChatProvider, VoiceProvider, FileProvider, app_ctrl.AppCtrl>(
      builder: (context, chatProvider, voiceProvider, fileProvider, appCtrl, child) {
        if (widget.isVoiceMode) {
          return _buildVoiceModeIndicator(appCtrl);
        }

        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              top: BorderSide(color: AppColors.borderColor, width: 1),
            ),
          ),
          child: Column(
            children: [
              if (fileProvider.attachedFiles.isNotEmpty) ...[
                AttachmentPreview(
                  attachedFiles: fileProvider.attachedFiles,
                  onRemoveFile: fileProvider.removeAttachedFile,
                  onUpdatePrompt: fileProvider.updateFilePrompt,
                  onClearAll: fileProvider.clearAttachedFiles,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
              ],
              Row(
                children: [
                  Expanded(child: _buildMessageInputField(voiceProvider)),
                  const SizedBox(width: AppSizes.paddingLarge),
                  _buildActionButtons(fileProvider),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInputField(VoiceProvider voiceProvider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: voiceProvider.isListening 
              ? AppColors.primaryGreen.withOpacity(0.4)
              : AppColors.borderColor,
          width: voiceProvider.isListening ? 2 : 1,
        ),
      ),
      child: KeyboardListener(
  focusNode: FocusNode(),
  onKeyEvent: (KeyEvent event) {
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
    }
  },
        child: TextField(
          controller: _messageController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: voiceProvider.isListening 
                ? AppStrings.messageInputListening
                : AppStrings.messageInputHint,
            hintStyle: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeLarge,
              color: voiceProvider.isListening 
                  ? AppColors.primaryGreen.withOpacity(0.8)
                  : AppColors.textSecondary,
              fontStyle: voiceProvider.isListening 
                  ? FontStyle.italic 
                  : FontStyle.normal,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXLarge,
              vertical: AppSizes.fontSizeLarge,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceInputButton(
                  isListening: voiceProvider.isListening,
                  speechEnabled: voiceProvider.hasMicPermission,
                  onToggleListening: () => _toggleListening(voiceProvider),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                _buildSendButton(),
              ],
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeLarge,
            color: AppColors.textPrimary,
          ),
          maxLines: 6,
          minLines: 1,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendMessage(),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.paddingXSmall),
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        child: const Icon(
          Icons.send_rounded,
          size: AppSizes.iconLarge,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButtons(FileProvider fileProvider) {
    return Consumer2<VoiceProvider, app_ctrl.AppCtrl>(
      builder: (context, voiceProvider, appCtrl, child) {
        return Row(
          children: [
            _buildActionButton(
              icon: Icons.attach_file,
              color: AppColors.accentBlue,
              label: 'Attach',
              onPressed: () => _handleAttachAction(fileProvider),
            ),
            const SizedBox(width: AppSizes.paddingMedium),
            _buildActionButton(
              icon: voiceProvider.isVoiceMode ? Icons.chat_outlined : Icons.graphic_eq_rounded,
              color: voiceProvider.isVoiceMode ? AppColors.primaryGreen : AppColors.accentPurple,
              label: voiceProvider.isVoiceMode ? 'Chat' : 'Voice AI',
              onPressed: () => _toggleVoiceMode(voiceProvider, appCtrl),
            ),
            // Show Send to Agent button only when in voice mode
            if (voiceProvider.isVoiceMode) ...[
              const SizedBox(width: AppSizes.paddingMedium),
                                _buildActionButton(
                    icon: _isFileUploading 
                        ? Icons.hourglass_empty 
                        : Icons.upload_file,
                    color: _isFileUploading ? Colors.grey : AppColors.accentGreen,
                    label: _isFileUploading ? 'Sending...' : 'Send to Agent',
                    onPressed: _isFileUploading ? null : () => _sendToAgent(fileProvider),
                  ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        ),
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? LinearGradient(colors: [Colors.grey, Colors.grey.withOpacity(0.8)])
              : LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: (onPressed == null ? Colors.grey : color).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            (_isFileUploading && label.contains('Sending'))
                ? const SizedBox(
                    width: AppSizes.iconLarge,
                    height: AppSizes.iconLarge,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    icon,
                    size: AppSizes.iconLarge,
                    color: Colors.white,
                  ),
            const SizedBox(width: AppSizes.paddingSmall),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildVoiceModeIndicator(app_ctrl.AppCtrl appCtrl) {
  return Consumer<FileProvider>(
    builder: (context, fileProvider, child) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(color: AppColors.borderColor, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Voice status indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXLarge,
                vertical: AppSizes.fontSizeLarge,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.accentGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppColors.accentGreen,
                    size: AppSizes.iconLarge,
                  ),
                  const SizedBox(width: AppSizes.paddingSmall + 2),
                  Expanded(
                    child: Text(
                      appCtrl.connectionState == app_ctrl.ConnectionState.connected
                          ? AppStrings.voiceModeListening
                          : AppStrings.voiceModeConnecting,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  String _getVoiceModeStatusText(dynamic selectedAgent) {
    // This would need proper typing based on the actual AgentType enum
    return 'HAAKEEM attorney agent - listening continuously';
  }

  void _toggleListening(VoiceProvider voiceProvider) async {
    final appCtrl = context.read<app_ctrl.AppCtrl>();
    await voiceProvider.toggleListening(agentType: appCtrl.selectedAgent);
  }

  void _sendMessage({bool isAIAnalysis = false}) {
    final text = _messageController.text.trim();
    final fileProvider = context.read<FileProvider>();
    
    debugPrint('📝💬 _sendMessage called with text: "$text", isAIAnalysis: $isAIAnalysis');
    
    if (text.isEmpty && !isAIAnalysis) {
      if (fileProvider.attachedFiles.isEmpty) {
        debugPrint('📝💬 No text and no files, returning');
        return;
      }
    }

    String messageToSend = text;
    if (isAIAnalysis && text.isEmpty) {
      messageToSend = "Please analyze the attached files.";
    }
    
    debugPrint('📝💬 Final message to send: "$messageToSend"');

    // Call the callback or handle message sending
    if (widget.onSendMessage != null) {
      debugPrint('📝💬 Using widget.onSendMessage callback');
      widget.onSendMessage!(messageToSend);
    } else {
      debugPrint('📝💬 Using ChatProvider directly');
      // Default behavior using ChatProvider with attached files
      final chatProvider = context.read<ChatProvider>();
      chatProvider.sendMessageToAI(messageToSend, attachedFiles: fileProvider.attachedFiles);
    }

    // Clear the input field and attached files
    _messageController.clear();
    _focusNode.unfocus();
    fileProvider.clearAttachedFiles();
  }

  void _toggleVoiceMode(VoiceProvider voiceProvider, app_ctrl.AppCtrl appCtrl) async {
    debugPrint('🎤 Toggling voice mode from message input');
    await voiceProvider.toggleVoiceMode(
      appCtrl: appCtrl,
      onVoiceModeActivated: () {
        debugPrint('🎤✅ Voice mode activated from message input');
      },
      onVoiceModeDeactivated: () {
        debugPrint('🎤❌ Voice mode deactivated from message input');
      },
    );
  }

  void _handleAttachAction(FileProvider fileProvider) {
    // Show options: Attach File or Scan Document
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Content',
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeXXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXLarge),
            Row(
              children: [
                Expanded(
                  child: _buildAttachOption(
                    icon: Icons.attach_file,
                    label: 'Attach Files',
                    color: AppColors.accentBlue,
                    onPressed: () {
                      Navigator.pop(context);
                      fileProvider.addAttachments();
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.paddingLarge),
                Expanded(
                  child: _buildAttachOption(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan Documents',
                    color: AppColors.accentBlue,
                    onPressed: () {
                      Navigator.pop(context);
                      _scanDocuments();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingXLarge),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppSizes.iconXLarge,
              color: color,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _scanDocuments() {
    // This would implement document scanning functionality
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Document scanner would be implemented here',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.accentBlue,
      ),
    );
  }

  void _sendToAgent(FileProvider fileProvider) async {
    try {
      setState(() {
        _isFileUploading = true;
      });

      // Use file picker to select files (same as original implementation)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false, // Send one file at a time to agent
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        var file = result.files.first;
        if (file.bytes != null) {
          // Get the AppCtrl to access LiveKit room
          final appCtrl = context.read<app_ctrl.AppCtrl>();

          if (appCtrl.connectionState == app_ctrl.ConnectionState.connected) {
            // Add message to chat showing file upload
            if (widget.onSendMessage != null) {
              widget.onSendMessage!('📤 Sending file "${file.name}" to agent...');
            }

            // Send file to agent using LiveKit byte streams
            await _sendFileToLiveKitAgent(
              appCtrl.room,
              file.bytes!,
              file.name,
              file.extension ?? '',
            );

            // Add success message to chat
            if (widget.onSendMessage != null) {
              widget.onSendMessage!(
                  '✅ File "${file.name}" sent to agent successfully! The agent will analyze it and respond shortly.');
            }

            // Show brief success snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'File sent to agent successfully!',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: AppColors.accentGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            throw Exception('Not connected to LiveKit room');
          }
        }
      }
    } catch (e) {
      // Add error message to chat
      if (widget.onSendMessage != null) {
        widget.onSendMessage!('❌ Failed to send file to agent: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending file to agent: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isFileUploading = false;
      });
    }
  }

  // CORRECT LiveKit Flutter implementation based on official documentation  
  Future<void> _sendFileToLiveKitAgent(
    sdk.Room room,
    Uint8List fileBytes,
    String fileName,
    String fileExtension,
  ) async {
    try {
      debugPrint(
          '📤 STARTING FILE UPLOAD - Name: $fileName, Size: ${fileBytes.length} bytes');
      String mimeType = _getMimeTypeFromExtension(fileExtension);
      debugPrint('📤 MIME Type: $mimeType');

      final localParticipant = room.localParticipant;
      debugPrint('📤 Local participant: ${localParticipant?.identity ?? "null"}');
      if (localParticipant == null) {
        throw Exception('No local participant available');
      }

      // Method 1: Use streamBytes (recommended for binary data)
      // Based on: https://pub.dev/documentation/livekit_client/latest/livekit_client/DataStreamParticipantMethods.html
      try {
        // Open a byte stream writer using correct StreamBytesOptions
        final writer = await localParticipant.streamBytes(
          sdk.StreamBytesOptions(
            topic: 'files',
            mimeType: mimeType,
            name: fileName,
          ),
        );

        debugPrint('📤 Opened byte stream: ${writer.info.id}');

        // Write the file data in chunks for better performance
        const chunkSize = 16384; // 16KB chunks
        for (int i = 0; i < fileBytes.length; i += chunkSize) {
          int end = (i + chunkSize < fileBytes.length)
              ? i + chunkSize
              : fileBytes.length;
          final chunk = fileBytes.sublist(i, end);
          await writer.write(chunk);
        }

        // IMPORTANT: Must close the stream when done
        await writer.close();

        debugPrint(
            '📤 File sent via streamBytes: $fileName (${fileBytes.length} bytes, $mimeType)');
      } catch (streamError) {
        debugPrint('⚠️ streamBytes failed: $streamError');

        // Method 2: Fallback using publishData with base64 encoding
        final fileData = {
          'type': 'file_upload',
          'fileName': fileName,
          'mimeType': mimeType,
          'data': base64Encode(fileBytes),
          'size': fileBytes.length,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await localParticipant.publishData(
          utf8.encode(jsonEncode(fileData)),
          reliable: true,
          topic: 'files',
        );

        debugPrint('📤 File sent via publishData fallback: $fileName');
      }
    } catch (e) {
      debugPrint('❌ Error sending file to agent: $e');
      rethrow;
    }
  }

  String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
  
  void _exitVoiceMode() {
    final voiceProvider = context.read<VoiceProvider>();
    final appCtrl = context.read<app_ctrl.AppCtrl>();
    _toggleVoiceMode(voiceProvider, appCtrl);
  }
}
