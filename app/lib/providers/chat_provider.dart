import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import '../models/file_models.dart';
import '../constants/enums.dart';
import '../services/chat_service.dart';
import '../services/livekit_service.dart';

/// Provider for managing chat state and operations
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Chat state
  List<ChatMessage> _messages = [];
  List<ChatSession> _chatHistory = [];
  String? _currentChatId;
  LegalLevel _currentLegalLevel = LegalLevel.beginner;
  bool _isProcessingAI = false;

  // Current sidebar mode
  SidebarMode _currentSidebarMode = SidebarMode.chat;

  // Map to store chat sessions
  final Map<String, List<ChatMessage>> _chatSessions = {};

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSession> get chatHistory => List.unmodifiable(_chatHistory);
  String? get currentChatId => _currentChatId;
  LegalLevel get currentLegalLevel => _currentLegalLevel;
  bool get isProcessingAI => _isProcessingAI;
  SidebarMode get currentSidebarMode => _currentSidebarMode;

  /// Initialize the chat provider
  void initialize() {
    _loadDemoData();
    // Automatically create a default chat session if none exists
    if (_currentChatId == null) {
      createNewChat(isVoiceMode: false);
    }
  }

  /// Load demo data for testing
  void _loadDemoData() {
    _chatHistory = [
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
    
    // Populate chatSessions map with dummy messages for demo
    for (var session in _chatHistory) {
      _chatSessions[session.id] = [
        ChatMessage(
          text: "Hello, how can I help you with ${session.title}?", 
          isUser: false, 
          timestamp: DateTime.now().subtract(const Duration(minutes: 5))
        ),
        ChatMessage(
          text: session.lastMessage, 
          isUser: true, 
          timestamp: DateTime.now().subtract(const Duration(minutes: 2))
        ),
      ];
    }
    notifyListeners();
  }

  /// Set the current sidebar mode
  void setSidebarMode(SidebarMode mode) {
    _currentSidebarMode = mode;
    notifyListeners();
  }

  /// Add a new message to the current chat
  void addMessage(String text, bool isUser, {List<AttachedFile> attachedFiles = const []}) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      attachedFiles: attachedFiles,
    ));
    notifyListeners();
  }

  /// Set processing AI state
  void _setProcessingAI(bool value) {
    _isProcessingAI = value;
    notifyListeners();
  }

  /// Add typing indicator
  void _addTypingIndicator() {
    _messages.add(ChatMessage(
      text: "Processing your request...",
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    ));
    notifyListeners();
  }

  /// Remove typing indicator
  void _removeTypingIndicator() {
    _messages.removeWhere((msg) => msg.isTyping == true);
    notifyListeners();
  }

  /// Send message to AI (supports both Gemini and LiveKit agents)
  Future<void> sendMessageToAI(String message, {List<AttachedFile> attachedFiles = const []}) async {
    debugPrint('💬📤 sendMessageToAI called with: "$message"');
    if (message.trim().isEmpty && attachedFiles.isEmpty) {
      debugPrint('💬📤 Skipping empty message');
      return;
    }

    String userMessage = message.trim();
    final brandRegex = RegExp(r'\b(ha+k[iy]e?m|hakim|hakeem)\b', caseSensitive: false);
    userMessage = userMessage.replaceAll(brandRegex, 'HAAKEEM');
    debugPrint('💬📤 Processed message: "$userMessage"');

    _currentChatId ??= DateTime.now().millisecondsSinceEpoch.toString();

    String fullMessage = userMessage;
    if (attachedFiles.isNotEmpty) {
      fullMessage += '\n\n[Attachments]:';
      for (var file in attachedFiles) {
        fullMessage += '\n📄 ${file.name}';
        if (file.prompt != null && file.prompt!.isNotEmpty) {
          fullMessage += ' - Instructions: ${file.prompt}';
        }
      }
    }

    addMessage(fullMessage, true, attachedFiles: attachedFiles);
    _addTypingIndicator();
    _setProcessingAI(true);

    try {
      // Check if we should send to LiveKit agent instead of Gemini
      final liveKitService = LiveKitService();
      bool sentToLiveKit = false;
      
      if (liveKitService.isRoomReady()) {
        try {
          debugPrint('📤 Sending message to LiveKit agent: $userMessage');
          await liveKitService.sendTextToAgent(userMessage);
          debugPrint('✅ Message sent to LiveKit agent successfully');
          sentToLiveKit = true;
          
          // For LiveKit agents, we don't remove the typing indicator immediately
          // It will be removed when we receive the agent's response
        } catch (liveKitError) {
          debugPrint('❌ Failed to send to LiveKit agent: $liveKitError');
          // Fall back to Gemini if LiveKit fails
        }
      }
      
      // If not sent to LiveKit or LiveKit failed, send to Gemini
      if (!sentToLiveKit) {
        debugPrint('📤 Sending message to Gemini AI: $userMessage');
        String aiResponse = await _chatService.sendMessageToAI(
          message: userMessage,
          isVoiceMode: false,
          legalLevel: _currentLegalLevel,
          selectedAgent: AgentType.gemini,
          conversationHistory: _messages,
          attachedFiles: attachedFiles,
        );
        
        _removeTypingIndicator();
        _setProcessingAI(false);
        addMessage(aiResponse, false);
      }
      
    } catch (e) {
      _removeTypingIndicator();
      _setProcessingAI(false);
      addMessage('Error: ${e.toString()}', false);
      debugPrint('❌ Error in sendMessageToAI: $e');
    } finally {
      // Only save if we're not waiting for LiveKit response
      final liveKitService = LiveKitService();
      if (!liveKitService.isRoomReady() || !_isProcessingAI) {
        saveChatSession();
      }
    }
  }
void createNewChat({bool isVoiceMode = false, LegalLevel? legalLevel}) {
  // Only create new chat if explicitly requested, not during mode switches
  saveChatSession(); // Save current chat before creating new one
  _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
  _messages.clear();
  _currentLegalLevel = legalLevel ?? LegalLevel.beginner;

  String levelMessage = _currentLegalLevel == LegalLevel.beginner
      ? "I'll explain legal concepts in simple, easy-to-understand terms with practical examples."
      : "I'll provide detailed legal analysis with technical terminology and comprehensive citations.";

  // Only add welcome message for actual new chats, not mode switches
  if (!isVoiceMode) {
    String welcomeMessage = '''Hello! I'm your AI Legal Assistant powered by Gemini. $levelMessage

I can help you with:
- Legal document analysis and review
- Contract interpretation and key terms
- Legal research and case law
- Compliance and regulatory questions
- Estate planning guidance
- Business law matters

How can I assist you today?
''';
    addMessage(welcomeMessage, false);
  }
  notifyListeners();
}
  /// Save current chat session
  void saveChatSession() {
    if (_currentChatId == null || _messages.isEmpty) return;

    _chatSessions[_currentChatId!] = List.from(_messages);

    final existingChatIndex = _chatHistory.indexWhere((chat) => chat.id == _currentChatId);

    final firstUserMessage = _messages.firstWhere(
      (msg) => msg.isUser && msg.text.trim().isNotEmpty,
      orElse: () => _messages.isNotEmpty
          ? _messages.first
          : ChatMessage(
              text: 'New Chat',
              isUser: false,
              timestamp: DateTime.now(),
            ),
    );

    String chatTitle;
    if (firstUserMessage.text.startsWith('Voice mode activated!')) {
      chatTitle = '🎤 Voice Chat';
    } else {
      chatTitle = firstUserMessage.text.length > 30
          ? '${firstUserMessage.text.substring(0, 30)}...'
          : firstUserMessage.text;
    }

    final chatSession = ChatSession(
      id: _currentChatId!,
      title: chatTitle,
      lastMessage: _messages.last.text,
      timestamp: DateTime.now(),
      messageCount: _messages.length,
    );

    if (existingChatIndex != -1) {
      _chatHistory[existingChatIndex] = chatSession;
    } else {
      _chatHistory.insert(0, chatSession);
    }
    notifyListeners();
  }

  /// Load a chat session
  void loadChatSession(ChatSession chat) {
    saveChatSession(); // Save current chat before loading new one
    _currentChatId = chat.id;
    _messages.clear();
    if (_chatSessions.containsKey(chat.id)) {
      _messages.addAll(_chatSessions[chat.id]!);
    } else {
      // If no messages saved, add a default welcome message
      addMessage(chat.title.replaceFirst('🎤 ', ''), false);
    }
    notifyListeners();
  }

  /// Delete a chat session
  void deleteChatSession(ChatSession chat) {
    _chatHistory.removeWhere((c) => c.id == chat.id);
    _chatSessions.remove(chat.id);
    if (_currentChatId == chat.id) {
      _currentChatId = null;
      _messages.clear();
    }
    notifyListeners();
  }

  /// Rename a chat session
  void renameChatSession(ChatSession chat, String newTitle) {
    final index = _chatHistory.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      _chatHistory[index] = chat.copyWith(title: newTitle);
    }
    notifyListeners();
  }

  /// Handle agent response (used when messages come from LiveKit)
  void handleAgentResponse(String response) {
    if (response.isEmpty) return;
    
    _removeTypingIndicator();
    _setProcessingAI(false);
    
    // Clean up common error patterns and malformed responses
    String cleanResponse = response;
    if (cleanResponse.startsWith('Error: Error processing agent response:')) {
      cleanResponse = 'I apologize, but I encountered an issue processing your request. Please try again.';
    }
    
    // Handle JSON parsing errors
    if (cleanResponse.contains('FormatException') || cleanResponse.contains('SyntaxError')) {
      cleanResponse = 'I received your message but encountered a formatting issue. Please try asking your question again.';
    }
    
    addMessage(cleanResponse, false);
    saveChatSession();
  }

  /// Clear current chat
 void clearCurrentChat({bool isVoiceModeSwitch = false}) {
  if (!isVoiceModeSwitch) {
    saveChatSession();
    _currentChatId = null;
    _messages.clear();
  }
  notifyListeners();
}

  /// Export current chat as JSON
  String exportCurrentChatAsJson() {
    if (_currentChatId == null) return '';
    return _chatService.exportChatSession(_currentChatId!);
  }

  /// Import chat from JSON
  bool importChatFromJson(String jsonData) {
    final ok = _chatService.importChatSession(jsonData);
    if (ok) {
      // Optional: load last imported chat; for now just refresh memory view
      notifyListeners();
    }
    return ok;
  }

  /// Clear all chats
  void clearAllChats() {
    _chatService.clearAllChats();
    _messages.clear();
    _currentChatId = null;
    notifyListeners();
  }
}