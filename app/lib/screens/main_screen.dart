// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;

import '../constants/app_constants.dart';
import '../constants/enums.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/file_provider.dart';
import '../controllers/app_ctrl.dart' as app_ctrl;
import '../models/chat_models.dart';
import '../models/file_models.dart';
import '../services/chat_service.dart';
import '../services/file_service.dart';
import '../widgets/sidebar/chat_sidebar.dart';
import '../widgets/chat/chat_message_list.dart';
import '../widgets/voice/bottom_controls.dart';
import '../widgets/voice/waveform_display.dart';
import '../widgets/file/file_preview_panel.dart';
import '../widgets/dialogs/new_chat_dialog.dart';
import '../widgets/common/top_header.dart';
import '../widgets/dialogs/settings_dialog.dart';
import '../widgets/click_to_talk_controls.dart';

/// Refactored main screen with clean architecture and separated components
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late ScrollController _chatScrollController;

  // EXACT SAME STATE AS ORIGINAL WORKING CODE:
  List<ChatMessage> messages = []; // Using exact same name as original
  bool _isProcessingAI = false;

  // File management state (exact same as original)
  List<AttachedFile> attachedFiles = [];
  Map<String, TextEditingController> filePromptControllers = {};
  bool _isUploading = false;
  bool _isFileUploading = false;

  // Chat session state (exact same as original)
  String? currentChatId;
  Map<String, List<ChatMessage>> chatSessions = {};
  List<ChatSession> chatHistory = [];
  LegalLevel currentLegalLevel = LegalLevel.beginner as LegalLevel;
  bool isCreatingNewChat = false;

  // File preview state
  UploadedFile? selectedFilePreview;

  // Waveform positioning (from original working code)
  Offset waveformPosition = const Offset(640, 500);
  bool isDraggingWaveform = false;

  // Scroll control state (from original)
  bool _isUserScrolling = false;
  double _scrollThreshold = 100.0;

  // Drag and drop listeners
  StreamSubscription<html.Event>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dropSub;

  @override
  void initState() {
    super.initState();
    _chatScrollController = ScrollController();

    // Initialize waveform data like original
    List<double> waveformData = List.generate(60, (index) => 0.0);

    // Add scroll listener like original
    _chatScrollController.addListener(_onScroll);

    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
      context.read<FileProvider>().initialize();
      context.read<VoiceProvider>().initialize(
            onFinalTranscription: _handleVoiceTranscription,
            onError: _handleVoiceError,
          );

      // Setup agent message handlers to connect LiveKit to ChatProvider
      _setupAgentMessageHandlers();

      // Load demo data like original
      _loadDemoData();
    });

    // Setup drag-and-drop for web
    if (kIsWeb) {
      // Allow dropping files anywhere on the page
      _dragOverSub = html.document.body?.onDragOver.listen((e) {
        e.preventDefault();
        e.stopPropagation();
      });

      _dropSub = html.document.body?.onDrop.listen((e) async {
        e.preventDefault();
        e.stopPropagation();
        final dt = e.dataTransfer;
        if (dt != null && dt.files != null && dt.files!.isNotEmpty) {
          final svc = FileService();
          final files = <AttachedFile>[];
          for (final f in dt.files!) {
            final af = await svc.attachedFileFromHtmlFile(f);
            files.add(af);
          }
          if (files.isNotEmpty) {
            await context.read<FileProvider>().addAttachmentsFromList(files);
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.hideCurrentSnackBar();
            messenger?.showSnackBar(
              const SnackBar(
                content: Text('Files attached'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Save current chat before disposing (like original)
    if (currentChatId != null && messages.isNotEmpty) {
      _saveChatSession();
    }

    _chatScrollController.dispose();

    // Cancel drag-and-drop subscriptions
    _dragOverSub?.cancel();
    _dropSub?.cancel();
    _dragOverSub = null;
    _dropSub = null;

    // Dispose all file prompt controllers (like original)
    for (var controller in filePromptControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatProvider, VoiceProvider, FileProvider>(
      builder: (context, chatProvider, voiceProvider, fileProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: Stack(
            children: [
              Row(
                children: [
                  // Sidebar
                  ChatSidebar(
                    currentSidebarMode: chatProvider.currentSidebarMode,
                    chatHistory: chatProvider.chatHistory,
                    currentChatId: chatProvider.currentChatId,
                    legalDocuments: fileProvider.legalDocuments,
                    onModeChanged: chatProvider.setSidebarMode,
                    onChatSelected: chatProvider.loadChatSession,
                    onNewChat: () =>
                        _showNewChatDialog(chatProvider, voiceProvider),
                    onChatDeleted: chatProvider.deleteChatSession,
                    onChatRenamed: chatProvider.renameChatSession,
                    onDocumentSelected: fileProvider.selectFileForPreview,
                    onDocumentUpload: fileProvider.uploadDocuments,
                  ),

                  // Main content area
                  Expanded(
                    child: Column(
                      children: [
                        // Top header
                        TopHeader(
                          onSettings: _showSettings,
                          onCall: _showCallDialog,
                        ),

                        // Chat messages with LiveKit transcription support
                        Expanded(
                          child: voiceProvider.isVoiceMode
                              ? _buildLiveTranscriptionChat()
                              : ChatMessageList(
                                  messages: messages,
                                  scrollController: _chatScrollController,
                                  isVoiceMode: voiceProvider.isVoiceMode,
                                  isProcessingAI: _isProcessingAI,
                                ),
                        ),

                        // Click-to-talk controls (when in voice mode with click-to-talk agents)
                        Consumer<app_ctrl.AppCtrl>(
                          builder: (context, appCtrl, child) => (voiceProvider
                                      .isVoiceMode &&
                                  (appCtrl.selectedAgent ==
                                          app_ctrl.AgentType.clickToTalk ||
                                      appCtrl.selectedAgent ==
                                          app_ctrl.AgentType.arabicClickToTalk))
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  child: const ClickToTalkControls(),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Bottom controls
                        Consumer<app_ctrl.AppCtrl>(
                          builder: (context, appCtrl, child) => BottomControls(
                            isVoiceMode: voiceProvider.isVoiceMode,
                            onSendMessage: (message) {
                              debugPrint(
                                  '🎯 MainScreen received message to send: "$message"');
                              _handleTextMessage(message);
                            },
                            showClickToTalkButton:
                                _shouldShowClickToTalkButton(appCtrl),
                            onToggleRecording: () =>
                                voiceProvider.toggleListening(
                              agentType: appCtrl.selectedAgent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // File preview panel
                  if (fileProvider.selectedFilePreview != null)
                    FilePreviewPanel(
                      file: fileProvider.selectedFilePreview!,
                      onClose: () => fileProvider.selectFileForPreview(null),
                      onDownload: fileProvider.downloadFile,
                      onAnalyze: (prompt) => _analyzeFileWithPrompt(
                        fileProvider.selectedFilePreview!,
                        prompt,
                        chatProvider,
                      ),
                    ),
                ],
              ),

              // Floating waveform display
              WaveformDisplay(
                waveformData: voiceProvider.waveformData,
                isVisible: voiceProvider.showWaveform,
                isVoiceMode: voiceProvider.isVoiceMode,
                isLiveVoiceActive: voiceProvider.isLiveVoiceActive,
                isRecording: voiceProvider.isRecording,
                liveTranscription: voiceProvider.liveTranscription,
                onStop: () => voiceProvider.toggleVoiceMode(
                  appCtrl: context.read<app_ctrl.AppCtrl>(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleVoiceTranscription(String transcription) {
    debugPrint(
        '🎤➡️💬 Voice transcription received in main_screen: "$transcription"');
    if (transcription.isNotEmpty) {
      debugPrint(
          '🎤➡️💬 Sending transcription via handleTextMessage: "$transcription"');
      final chatProvider = context.read<ChatProvider>();
      chatProvider.addMessage(transcription, true);
      _handleTextMessage(transcription);
    } else {
      debugPrint('🎤➡️💬 Skipping empty transcription');
    }
  }

  void _handleVoiceError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.accentRed, size: 16),
            const SizedBox(width: AppSizes.paddingMedium),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        margin: const EdgeInsets.all(AppSizes.paddingLarge),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleVoiceMode(
      VoiceProvider voiceProvider, app_ctrl.AppCtrl appCtrl) async {
    await voiceProvider.toggleVoiceMode(
      appCtrl: appCtrl,
      newChatId: context.read<ChatProvider>().currentChatId,
      onVoiceModeActivated: () {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.addMessage(
          "Voice mode activated! ${_getLegalLevelMessage(chatProvider.currentLegalLevel)} Ready for your legal questions.",
          false,
        );
        _scrollToBottom();
      },
      onVoiceModeDeactivated: () {
        final chatProvider = context.read<ChatProvider>();

        setState(() {
          messages.clear();
          messages.addAll(chatProvider.messages);
        });
        chatProvider.saveChatSession();

        _scrollToBottom();
      },
    );
  }

  void _showNewChatDialog(
      ChatProvider chatProvider, VoiceProvider voiceProvider) {
    showDialog(
      context: context,
      builder: (context) => const NewChatDialog(),
    );
  }

  void _showCallDialog() {
    // This would show the call dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Call'),
        content: const Text('Call feature would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _analyzeFileWithPrompt(
    dynamic file,
    String prompt,
    ChatProvider chatProvider,
  ) {
    // Convert file to AttachedFile and send with prompt
    final message = "$prompt\n📄 ${file.name}";
    chatProvider.sendMessageToAI(message);

    // Close file preview
    context.read<FileProvider>().selectFileForPreview(null);
    _scrollToBottom();
  }

  bool _shouldShowClickToTalkButton(app_ctrl.AppCtrl appCtrl) {
    // This would check if the current agent supports click-to-talk
    return appCtrl.selectedAgent == app_ctrl.AgentType.clickToTalk ||
        appCtrl.selectedAgent == app_ctrl.AgentType.arabicClickToTalk;
  }

  String _getLegalLevelMessage(LegalLevel level) {
    return level == LegalLevel.beginner
        ? "I'll explain legal concepts in simple, easy-to-understand terms with practical examples."
        : "I'll provide detailed legal analysis with technical terminology and comprehensive citations.";
  }

  void _setupAgentMessageHandlers() {
    final appCtrl = context.read<app_ctrl.AppCtrl>();
    final chatProvider = context.read<ChatProvider>();

    appCtrl.setupAgentMessageHandlers(
      onAgentMessage: (message) {
        debugPrint('📥 Adding agent message to chat: $message');
        // Add to both ChatProvider (for persistence) and local display
        chatProvider.handleAgentResponse(message);
        _addMessage(message, false);
        _scrollToBottom();
      },
      onError: (error) {
        debugPrint('❌ Agent error: $error');
        chatProvider.handleAgentResponse('Error: $error');
        _addMessage('Error: $error', false);
        _scrollToBottom();
      },
    );
  }

  // Handle text messages sent from UI (EXACT SAME AS ORIGINAL)
  void _handleTextMessage(String message) {
    if (message.trim().isEmpty && attachedFiles.isEmpty) {
      debugPrint('🎯 Skipping empty message with no attachments');
      return;
    }

    debugPrint(
        '🎯 Handling text message: "$message" with ${attachedFiles.length} attachments');

    // Build full message with attachments like original code
    String fullMessage = message.trim();
    if (attachedFiles.isNotEmpty) {
      fullMessage += '\n\n[Attachments]:';
      for (var file in attachedFiles) {
        fullMessage += '\n📄 ${file.name}';
        if (file.prompt != null && file.prompt!.isNotEmpty) {
          fullMessage += ' - Instructions: ${file.prompt}';
        }
      }
    }

    // Add user message to display immediately (with attachments) - SAME AS ORIGINAL
    _addMessage(fullMessage, true, attachedFiles: List.from(attachedFiles));

    // Clear attachments after sending
    _clearAttachments();

    // Add typing indicator
    setState(() {
      _isProcessingAI = true;
    });
    _addMessage("Processing your request...", false, isTyping: true);

    // Send to both systems for backward compatibility
    final chatProvider = context.read<ChatProvider>();
    final voiceProvider = context.read<VoiceProvider>();

    if (voiceProvider.isVoiceMode) {
      // Voice mode - send to LiveKit agent
      debugPrint('🎯 Sending to voice mode/LiveKit agent');
      final appCtrl = context.read<app_ctrl.AppCtrl>();
      appCtrl.messageCtrl.text = message;
      appCtrl.sendMessage().then((_) {
        // Remove typing indicator when done
        _removeTypingIndicator();
      }).catchError((error) {
        _removeTypingIndicator();
        _addMessage('Error: $error', false);
      });
    } else {
      // Text mode - send to ChatProvider (Gemini)
      debugPrint('🎯 Sending to text mode/Gemini');
      chatProvider.sendMessageToAI(message).then((_) {
        // Get the response from ChatProvider and add to local display
        if (chatProvider.messages.isNotEmpty) {
          final lastMessage = chatProvider.messages.last;
          if (!lastMessage.isUser && !_hasMessageInLocal(lastMessage.text)) {
            _removeTypingIndicator();
            _addMessage(lastMessage.text, false);
          }
        }
      }).catchError((error) {
        _removeTypingIndicator();
        _addMessage('Error: $error', false);
      });
    }

    _scrollToBottom();
  }

  // EXACT SAME AS ORIGINAL _addMessage function
  void _addMessage(String text, bool isUser,
      {bool isTyping = false, List<AttachedFile> attachedFiles = const []}) {
    if (!mounted) return;
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
        isTyping: isTyping,
        attachedFiles: attachedFiles,
      ));
    });

    if (isUser || _isNearBottom) {
      _scrollToBottom(force: isUser);
    }

    debugPrint('🎯 Added message (isUser: $isUser): "$text"');
  }

  void _removeTypingIndicator() {
    setState(() {
      messages.removeWhere((msg) => msg.isTyping == true);
      _isProcessingAI = false;
    });
  }

  bool _hasMessageInLocal(String text) {
    return messages.any((msg) => msg.text == text && !msg.isUser);
  }

  // EXACT SAME scroll functions as original
  bool get _isNearBottom {
    if (!_chatScrollController.hasClients) return true;
    return _chatScrollController.position.pixels >=
        _chatScrollController.position.maxScrollExtent - _scrollThreshold;
  }

  void _onScroll() {
    if (!_chatScrollController.hasClients) return;

    final maxScroll = _chatScrollController.position.maxScrollExtent;
    final currentScroll = _chatScrollController.position.pixels;
    final isAtBottom = (maxScroll - currentScroll) <= _scrollThreshold;

    if (_chatScrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      _isUserScrolling = true;
      Timer(const Duration(milliseconds: 1000), () {
        _isUserScrolling = false;
      });
    }
  }

  void _scrollToBottom({bool animated = true, bool force = false}) {
    if (!mounted || !_chatScrollController.hasClients) return;

    if (!force && !_isNearBottom && _isUserScrolling) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        if (animated) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _chatScrollController.jumpTo(
            _chatScrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  /// File management functions (from original working code)
  void _clearAttachments() {
    for (var controller in filePromptControllers.values) {
      controller.dispose();
    }
    setState(() {
      attachedFiles.clear();
      filePromptControllers.clear();
    });
  }

  Future<void> _scanDocuments() async {
    try {
      setState(() => _isUploading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.bytes != null) {
            String extension = file.extension?.toLowerCase() ?? '';
            String fileId =
                '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

            AttachedFile attachedFile = AttachedFile(
              id: fileId,
              name: file.name,
              type: _getFileTypeFromExtension(extension),
              size: _formatFileSize(file.size),
              data: file.bytes!,
            );

            setState(() {
              attachedFiles.add(attachedFile);
              filePromptControllers[fileId] = TextEditingController();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading documents: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadFileToAgent() async {
    try {
      setState(() => _isFileUploading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        var file = result.files.first;
        if (file.bytes != null) {
          final appCtrl = Provider.of<app_ctrl.AppCtrl>(context, listen: false);

          if (appCtrl.connectionState == app_ctrl.ConnectionState.connected) {
            _addMessage('📤 Sending file "${file.name}" to agent...', true);
            _scrollToBottom();

            await _sendFileToLiveKitAgent(
              appCtrl.room,
              file.bytes!,
              file.name,
              file.extension ?? '',
            );

            _addMessage(
                '✅ File "${file.name}" sent to agent successfully! The agent will analyze it and respond shortly.',
                false);
            _scrollToBottom();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File sent to agent successfully!'),
                  backgroundColor: AppColors.accentGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            throw Exception('Not connected to LiveKit room');
          }
        }
      }
    } catch (e) {
      _addMessage('❌ Failed to send file to agent: $e', false);
      _scrollToBottom();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending file to agent: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isFileUploading = false);
    }
  }

  Future<void> _sendFileToLiveKitAgent(
    dynamic room,
    Uint8List fileBytes,
    String fileName,
    String fileExtension,
  ) async {
    try {
      String mimeType = _getMimeTypeFromExtension(fileExtension);

      final localParticipant = room.localParticipant;
      if (localParticipant == null) {
        throw Exception('No local participant available');
      }

      try {
        // Create dynamic options object since we don't have proper import
        final options = {
          'topic': 'files',
          'mimeType': mimeType,
          'name': fileName,
        };

        final writer = await localParticipant.streamBytes(options);

        const chunkSize = 16384;
        for (int i = 0; i < fileBytes.length; i += chunkSize) {
          int end = (i + chunkSize < fileBytes.length)
              ? i + chunkSize
              : fileBytes.length;
          final chunk = fileBytes.sublist(i, end);
          await writer.write(chunk);
        }

        await writer.close();
      } catch (streamError) {
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
      }
    } catch (e) {
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

  MyFileType _getFileTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MyFileType.pdf;
      case 'doc':
        return MyFileType.doc;
      case 'docx':
        return MyFileType.docx;
      case 'jpg':
      case 'jpeg':
        return MyFileType.jpeg;
      case 'png':
        return MyFileType.png;
      case 'txt':
        return MyFileType.txt;
      default:
        return MyFileType.other;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _downloadFile(UploadedFile file) async {
    try {
      if (file.data != null) {
        final blob = html.Blob([file.data!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = file.name;
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded ${file.name}'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _saveChatSession() {
    if (currentChatId == null || messages.isEmpty) return;

    chatSessions[currentChatId!] = List.from(messages);

    final existingChatIndex =
        chatHistory.indexWhere((chat) => chat.id == currentChatId);

    final firstUserMessage = messages.firstWhere(
      (msg) => msg.isUser && msg.text.trim().isNotEmpty,
      orElse: () => messages.isNotEmpty
          ? messages.first
          : ChatMessage(
              text: 'New Chat',
              isUser: false,
              timestamp: DateTime.now(),
            ),
    );

    String chatTitle = firstUserMessage.text.length > 30
        ? '${firstUserMessage.text.substring(0, 30)}...'
        : firstUserMessage.text;

    final chatSession = ChatSession(
      id: currentChatId!,
      title: chatTitle,
      lastMessage: messages.last.text,
      timestamp: DateTime.now(),
      messageCount: messages.length,
    );

    setState(() {
      if (existingChatIndex != -1) {
        chatHistory[existingChatIndex] = chatSession;
      } else {
        chatHistory.insert(0, chatSession);
      }
    });
  }

  Future<void> _loadChatSession(ChatSession chat) async {
    if (currentChatId != null && messages.isNotEmpty) {
      _saveChatSession();
    }

    setState(() {
      currentChatId = chat.id;
      messages.clear();

      if (chatSessions.containsKey(chat.id)) {
        messages.addAll(chatSessions[chat.id]!);
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom(animated: false, force: true);
    });
  }

  void _clearCurrentChat() {
    if (currentChatId != null && messages.isNotEmpty) {
      _saveChatSession();
    }

    setState(() {
      currentChatId = null;
      messages.clear();
    });
  }

  void _deleteChatSession(ChatSession chat) {
    setState(() {
      chatHistory.removeWhere((c) => c.id == chat.id);
      chatSessions.remove(chat.id);
      if (currentChatId == chat.id) {
        currentChatId = null;
        messages.clear();
      }
    });
  }

  Future<void> _createNewChatWithMode(
      bool voiceMode, LegalLevel legalLevel) async {
    final newChatId = DateTime.now().millisecondsSinceEpoch.toString();

    if (currentChatId != null && messages.isNotEmpty) {
      _saveChatSession();
    }

    setState(() {
      currentChatId = newChatId;
      messages.clear();
      currentLegalLevel = legalLevel;
    });

    String levelMessage = legalLevel == LegalLevel.beginner
        ? "I'll explain legal concepts in simple, easy-to-understand terms with practical examples."
        : "I'll provide detailed legal analysis with technical terminology and comprehensive citations.";

    if (voiceMode) {
      final voiceProvider = context.read<VoiceProvider>();
      final appCtrl = context.read<app_ctrl.AppCtrl>();
      await voiceProvider.toggleVoiceMode(appCtrl: appCtrl);
      _addMessage(
          "Voice mode activated! $levelMessage Ready for your legal questions.",
          false);
    } else {
      String welcomeMessage =
          '''Hello! I'm your AI Legal Assistant powered by Gemini. $levelMessage

I can help you with:
• Legal document analysis and review
• Contract interpretation and key terms
• Legal research and case law
• Compliance and regulatory questions
• Estate planning guidance
• Business law matters

How can I assist you today?
''';

      _addMessage(welcomeMessage, false);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom(animated: false);
    });
  }

  void _loadDemoData() {
    // Demo chat history like original
    chatHistory = [
      ChatSession(
        id: '1',
        title: 'Contract Review Discussion',
        lastMessage: 'Can you review this employment contract?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        messageCount: 15,
      ),
      ChatSession(
        id: '2',
        title: 'Legal Document Analysis',
        lastMessage: 'What are the key terms in this agreement?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        messageCount: 8,
      ),
      ChatSession(
        id: '3',
        title: 'Estate Planning Consultation',
        lastMessage: 'Help me understand will requirements',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        messageCount: 23,
      ),
    ];
  }

  /// LiveKit voice mode chat display with real-time transcriptions
  Widget _buildLiveTranscriptionChat() {
    return Consumer2<app_ctrl.AppCtrl, VoiceProvider>(
      builder: (context, appCtrl, voiceProvider, child) {
        if (messages.isEmpty) {
          return _buildVoiceWelcomeMessage();
        }

        if (!voiceProvider.isSessionReady) {
          return _buildSessionLoadingState();
        }

        return components.TranscriptionBuilder(
          key: ValueKey(
              'transcription_${DateTime.now().millisecondsSinceEpoch}'),
          builder: (context, transcriptions) {
            final allDisplayItems = <Widget>[];

            for (int i = 0; i < messages.length; i++) {
              allDisplayItems.add(_buildMessageBubble(messages[i]));
            }

            String currentUserInput = "";
            String currentAIResponse = "";

            for (final transcription in transcriptions) {
              final participantIdentity = transcription.participant.identity;
              final participantName = transcription.participant.name;

              final isAgent = participantIdentity.startsWith('agent-') ||
                  participantIdentity == 'HAAKEEM' ||
                  participantIdentity == 'agent' ||
                  participantName == 'HAAKEEM Assistant' ||
                  participantName.contains('HAAKEEM');

              final text = transcription.segment.text.trim();
              if (text.isEmpty) continue;

              if (isAgent) {
                if (currentUserInput.isNotEmpty) {
                  allDisplayItems
                      .add(_buildLiveChatBubble(currentUserInput, true));
                  currentUserInput = "";
                }
                currentAIResponse +=
                    (currentAIResponse.isEmpty ? "" : " ") + text;
              } else {
                if (currentAIResponse.isNotEmpty) {
                  allDisplayItems
                      .add(_buildLiveChatBubble(currentAIResponse, false));
                  currentAIResponse = "";
                }
                currentUserInput +=
                    (currentUserInput.isEmpty ? "" : " ") + text;
              }
            }

            if (currentUserInput.isNotEmpty) {
              allDisplayItems.add(_buildLiveChatBubble(currentUserInput, true));
            }
            if (currentAIResponse.isNotEmpty) {
              allDisplayItems
                  .add(_buildLiveChatBubble(currentAIResponse, false));
            }

            if (allDisplayItems.isEmpty) {
              return _buildVoiceWelcomeMessage();
            }

            return ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(32),
              itemCount: allDisplayItems.length,
              itemBuilder: (context, index) => allDisplayItems[index],
            );
          },
        );
      },
    );
  }

  Widget _buildSessionLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
                Icon(
                  Icons.mic,
                  size: 30,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Initializing Voice Session...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting up microphone and voice recognition',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build live transcription bubble (real-time speech recognition)
  Widget _buildLiveTranscriptionBubble(String transcription) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transcription,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryGreen,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Build regular message bubble for non-voice conversations
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.isTyping == true
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen),
                      ),
                    )
                  : const Icon(
                      Icons.smart_toy_outlined,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.attachedFiles.isNotEmpty)
                  _buildAttachedFilesPreview(
                      message.attachedFiles, message.isUser),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppColors.primaryGreen
                        : AppColors.primaryGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: !message.isUser
                        ? Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.2))
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: message.isTyping == true
                        ? _buildTypingIndicator()
                        : SelectableText(
                            message.text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: message.isUser
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build attached files preview
  Widget _buildAttachedFilesPreview(List<AttachedFile> files, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            files.map((file) => _buildMessageFileItem(file, isUser)).toList(),
      ),
    );
  }

  /// Build file item for message
  Widget _buildMessageFileItem(AttachedFile file, bool isUser) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color:
            isUser ? Colors.white.withOpacity(0.1) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUser ? Colors.white.withOpacity(0.2) : AppColors.borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(file.type),
              size: 16,
              color: isUser ? Colors.white : AppColors.primaryGreen,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                file.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get file icon based on type
  IconData _getFileIcon(MyFileType type) {
    switch (type) {
      case MyFileType.pdf:
        return Icons.picture_as_pdf;
      case MyFileType.doc:
      case MyFileType.docx:
        return Icons.description;
      case MyFileType.txt:
        return Icons.text_snippet;
      case MyFileType.jpeg:
      case MyFileType.png:
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (i < 2) const SizedBox(width: 4),
        ],
      ],
    );
  }

  /// Build live chat bubble for voice conversations
  Widget _buildLiveChatBubble(String text, bool isUser) {
    if (!isUser && _isNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: !isUser
                    ? Border.all(color: AppColors.primaryGreen.withOpacity(0.2))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build voice welcome message
  Widget _buildVoiceWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.mic,
              size: 40,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Voice Mode Active',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start speaking to begin your conversation with the AI assistant',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
