import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/chat_models.dart';
import '../models/file_models.dart';
import '../constants/app_constants.dart';
import '../constants/enums.dart';
import '../screens/gemini_service.dart';

/// Service class to handle all chat-related operations
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Storage for chat sessions and messages
  final Map<String, List<ChatMessage>> _chatSessions = {};
  final List<ChatSession> _chatHistory = [];

  // Getters
  Map<String, List<ChatMessage>> get chatSessions => Map.unmodifiable(_chatSessions);
  List<ChatSession> get chatHistory => List.unmodifiable(_chatHistory);

  /// Send message to AI and get response
  Future<String> sendMessageToAI({
    required String message,
    required bool isVoiceMode,
    required LegalLevel legalLevel,
    required AgentType selectedAgent,
    List<ChatMessage> conversationHistory = const [],
    List<AttachedFile> attachedFiles = const [],
  }) async {
    try {
      final geminiService = GeminiService();
      
      // Build conversation history for Gemini
      final geminiHistory = _buildGeminiConversationHistory(conversationHistory);
      
      // Send to appropriate AI service
      final response = await geminiService.sendMessage(
        message: message,
        attachedFiles: attachedFiles,
        legalLevel: legalLevel,
        conversationHistory: geminiHistory,
      );
      
      return response;
    } catch (e) {
      debugPrint('Error sending message to AI: $e');
      return 'Sorry, I encountered an error processing your request. Please try again.';
    }
  }

  /// Build conversation history in Gemini format
  List<Map<String, String>> _buildGeminiConversationHistory(List<ChatMessage> messages) {
    final history = <Map<String, String>>[];
    final recentMessages = messages.where((msg) => msg.isTyping != true).toList();
    final messagesToInclude = recentMessages.length > 10
        ? recentMessages.sublist(recentMessages.length - 10)
        : recentMessages;

    for (int i = 0; i < messagesToInclude.length - 1; i += 2) {
      final userMsg = messagesToInclude[i];
      final assistantMsg = i + 1 < messagesToInclude.length ? messagesToInclude[i + 1] : null;

      if (userMsg.isUser && assistantMsg != null && !assistantMsg.isUser) {
        history.add({
          'user': userMsg.text,
          'assistant': assistantMsg.text,
        });
      }
    }
    return history;
  }

  /// Create demo chat history for testing
  List<ChatSession> createDemoChatHistory() {
    return [
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

  /// Save a chat session to storage
  void saveChatSession(String chatId, List<ChatMessage> messages) {
    if (chatId.isEmpty || messages.isEmpty) return;

    _chatSessions[chatId] = List.from(messages);

    final existingChatIndex = _chatHistory.indexWhere((chat) => chat.id == chatId);
    
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

    String chatTitle = _generateChatTitle(firstUserMessage.text, false);

    final chatSession = ChatSession(
      id: chatId,
      title: chatTitle,
      lastMessage: messages.last.text,
      timestamp: DateTime.now(),
      messageCount: messages.length,
    );

    if (existingChatIndex != -1) {
      _chatHistory[existingChatIndex] = chatSession;
    } else {
      _chatHistory.insert(0, chatSession);
    }
  }

  /// Load messages for a specific chat session
  List<ChatMessage> loadChatSession(String chatId) {
    return _chatSessions[chatId] ?? [];
  }

  /// Delete a chat session
  bool deleteChatSession(String chatId) {
    try {
      _chatSessions.remove(chatId);
      _chatHistory.removeWhere((chat) => chat.id == chatId);
      return true;
    } catch (e) {
      debugPrint('Error deleting chat session: $e');
      return false;
    }
  }

  /// Rename a chat session
  bool renameChatSession(String chatId, String newTitle) {
    try {
      final chatIndex = _chatHistory.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        final existingChat = _chatHistory[chatIndex];
        _chatHistory[chatIndex] = existingChat.copyWith(title: newTitle);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error renaming chat session: $e');
      return false;
    }
  }

  /// Generate a unique chat ID
  String generateChatId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generate chat title from message text
  String _generateChatTitle(String messageText, bool isVoiceMode) {
    if (isVoiceMode) {
      return messageText.length > ChatConstants.maxVoiceChatTitleLength
          ? '🎤 ${messageText.substring(0, ChatConstants.maxVoiceChatTitleLength)}...'
          : '🎤 $messageText';
    } else {
      return messageText.length > ChatConstants.maxChatTitleLength
          ? '${messageText.substring(0, ChatConstants.maxChatTitleLength)}...'
          : messageText;
    }
  }

  /// Build conversation history for context
  List<Map<String, String>> buildConversationHistory(List<ChatMessage> messages) {
    final history = <Map<String, String>>[];

    // Take the last 10 messages (5 exchanges) to avoid token limits
    final recentMessages = messages.where((msg) => msg.isTyping != true).toList();
    final messagesToInclude = recentMessages.length > ChatConstants.maxConversationHistory
        ? recentMessages.sublist(recentMessages.length - ChatConstants.maxConversationHistory)
        : recentMessages;

    for (int i = 0; i < messagesToInclude.length - 1; i += 2) {
      final userMsg = messagesToInclude[i];
      final assistantMsg = i + 1 < messagesToInclude.length ? messagesToInclude[i + 1] : null;

      if (userMsg.isUser && assistantMsg != null && !assistantMsg.isUser) {
        history.add({
          'user': userMsg.text,
          'assistant': assistantMsg.text,
        });
      }
    }

    return history;
  }

  /// Send message to Gemini AI service
  Future<String> sendToGemini({
    required String message,
    List<AttachedFile>? attachedFiles,
    LegalLevel legalLevel = LegalLevel.beginner,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final geminiService = GeminiService();
      final response = await geminiService.sendMessage(
        message: message,
        attachedFiles: attachedFiles ?? [],
        legalLevel: legalLevel,
        conversationHistory: conversationHistory ?? [],
      );
      return response;
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return 'Error: ${e.toString()}';
    }
  }

  /// Normalize brand name variants in message text
  String normalizeBrandNames(String text) {
    final brandRegex = RegExp(r'\b(ha+k[iy]e?m|hakim|hakeem)\b', caseSensitive: false);
    return text.replaceAll(brandRegex, 'HAAKEEM');
  }

  /// Create a typing indicator message
  ChatMessage createTypingMessage() {
    return ChatMessage(
      text: "Processing your request...",
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
  }

  /// Create a system message
  ChatMessage createSystemMessage(String text) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  /// Create a user message
  ChatMessage createUserMessage(String text, {List<AttachedFile>? attachedFiles}) {
    return ChatMessage(
      text: normalizeBrandNames(text),
      isUser: true,
      timestamp: DateTime.now(),
      attachedFiles: attachedFiles ?? [],
    );
  }

  /// Format message with attachments for display
  String formatMessageWithAttachments(String userMessage, List<AttachedFile> attachedFiles) {
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

    return fullMessage;
  }

  /// Get welcome message for new chat
  String getWelcomeMessage(LegalLevel legalLevel, bool isVoiceMode) {
    String levelMessage = legalLevel == LegalLevel.beginner
        ? "I'll explain legal concepts in simple, easy-to-understand terms with practical examples."
        : "I'll provide detailed legal analysis with technical terminology and comprehensive citations.";

    if (isVoiceMode) {
      return "Voice mode activated! $levelMessage Ready for your legal questions.";
    } else {
      return '''Hello! I'm your AI Legal Assistant powered by Gemini. $levelMessage

I can help you with:
• Legal document analysis and review
• Contract interpretation and key terms
• Legal research and case law
• Compliance and regulatory questions
• Estate planning guidance
• Business law matters

How can I assist you today?''';
    }
  }

  /// Clear all chat data
  void clearAllChats() {
    _chatSessions.clear();
    _chatHistory.clear();
  }

  /// Export chat session to JSON
  String exportChatSession(String chatId) {
    final messages = _chatSessions[chatId];
    if (messages == null) return '';

    final chatData = {
      'chatId': chatId,
      'exportDate': DateTime.now().toIso8601String(),
      'messages': messages.map((msg) => msg.toMap()).toList(),
    };

    return jsonEncode(chatData);
  }

  /// Import chat session from JSON
  bool importChatSession(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final chatId = data['chatId'] as String;
      final messagesData = data['messages'] as List<dynamic>;

      final messages = messagesData
          .map((msgData) => ChatMessage.fromMap(msgData as Map<String, dynamic>))
          .toList();

      saveChatSession(chatId, messages);
      return true;
    } catch (e) {
      debugPrint('Error importing chat session: $e');
      return false;
    }
  }

  /// Get chat statistics
  Map<String, dynamic> getChatStatistics() {
    int totalMessages = 0;
    int totalChats = _chatHistory.length;
    
    for (final messages in _chatSessions.values) {
      totalMessages += messages.length;
    }

    return {
      'totalChats': totalChats,
      'totalMessages': totalMessages,
      'averageMessagesPerChat': totalChats > 0 ? (totalMessages / totalChats).round() : 0,
      'newestChat': _chatHistory.isNotEmpty ? _chatHistory.first.timestamp : null,
      'oldestChat': _chatHistory.isNotEmpty ? _chatHistory.last.timestamp : null,
    };
  }
}
