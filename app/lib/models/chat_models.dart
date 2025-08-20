import 'file_models.dart';

/// Represents a single chat message in the conversation
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AttachedFile> attachedFiles;
  final bool? isTyping;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachedFiles = const [],
    this.isTyping,
  });

  /// Creates a copy of this message with updated properties
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<AttachedFile>? attachedFiles,
    bool? isTyping,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// Converts the message to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'attachedFiles': attachedFiles.map((f) => f.toMap()).toList(),
      'isTyping': isTyping,
    };
  }

  /// Creates a ChatMessage from a map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      attachedFiles: (map['attachedFiles'] as List<dynamic>?)
          ?.map((f) => AttachedFile.fromMap(f))
          .toList() ?? [],
      isTyping: map['isTyping'],
    );
  }
}

/// Represents a chat session with its metadata
class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.messageCount,
  });

  /// Creates a copy of this session with updated properties
  ChatSession copyWith({
    String? id,
    String? title,
    String? lastMessage,
    DateTime? timestamp,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  /// Converts the session to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lastMessage': lastMessage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'messageCount': messageCount,
    };
  }

  /// Creates a ChatSession from a map
  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      messageCount: map['messageCount'] ?? 0,
    );
  }
}
