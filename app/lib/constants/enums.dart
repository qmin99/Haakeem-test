/// Enum for sidebar mode selection
enum SidebarMode { 
  chat, 
  documents,
}

/// Extension for SidebarMode
extension SidebarModeExtension on SidebarMode {
  String get displayName {
    switch (this) {
      case SidebarMode.chat:
        return 'Chat History';
      case SidebarMode.documents:
        return 'Documents';
    }
  }
  
  String get iconName {
    switch (this) {
      case SidebarMode.chat:
        return 'chat_bubble_outline';
      case SidebarMode.documents:
        return 'folder_outlined';
    }
  }
}

/// Enum for legal experience levels
enum LegalLevel { 
  beginner, 
  expert,
}

/// Extension for LegalLevel
extension LegalLevelExtension on LegalLevel {
  String get displayName {
    switch (this) {
      case LegalLevel.beginner:
        return 'Beginner';
      case LegalLevel.expert:
        return 'Expert';
    }
  }
  
  String get description {
    switch (this) {
      case LegalLevel.beginner:
        return 'Simple explanations';
      case LegalLevel.expert:
        return 'Technical details';
    }
  }
  
  String get fullDescription {
    switch (this) {
      case LegalLevel.beginner:
        return 'AI will explain legal concepts in simple terms with examples.';
      case LegalLevel.expert:
        return 'AI will provide technical legal analysis with detailed citations.';
    }
  }
}

/// Enum for voice recognition states
enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

/// Extension for VoiceState
extension VoiceStateExtension on VoiceState {
  String get displayName {
    switch (this) {
      case VoiceState.idle:
        return 'Ready';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.processing:
        return 'Processing...';
      case VoiceState.speaking:
        return 'Speaking...';
      case VoiceState.error:
        return 'Error';
    }
  }
  
  bool get isActive {
    return this == VoiceState.listening || 
           this == VoiceState.processing || 
           this == VoiceState.speaking;
  }
}

/// Enum for chat message types
enum MessageType {
  text,
  voice,
  file,
  system,
  typing,
}

/// Extension for MessageType
extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.voice:
        return 'Voice';
      case MessageType.file:
        return 'File';
      case MessageType.system:
        return 'System';
      case MessageType.typing:
        return 'Typing';
    }
  }
}

/// Enum for file upload states
enum FileUploadState {
  idle,
  picking,
  uploading,
  completed,
  error,
}

/// Extension for FileUploadState
extension FileUploadStateExtension on FileUploadState {
  String get displayName {
    switch (this) {
      case FileUploadState.idle:
        return 'Ready';
      case FileUploadState.picking:
        return 'Selecting...';
      case FileUploadState.uploading:
        return 'Uploading...';
      case FileUploadState.completed:
        return 'Completed';
      case FileUploadState.error:
        return 'Error';
    }
  }
  
  bool get isLoading {
    return this == FileUploadState.picking || this == FileUploadState.uploading;
  }
}

/// Enum for AI agent types
enum AgentType {
  attorney,
  clickToTalk,
  arabic,
  arabicClickToTalk,
  gemini, // For text-based AI
}

/// Extension for AgentType
extension AgentTypeExtension on AgentType {
  String get displayName {
    switch (this) {
      case AgentType.attorney:
        return 'Attorney Agent';
      case AgentType.clickToTalk:
        return 'Click to Talk';
      case AgentType.arabic:
        return 'Arabic Agent';
      case AgentType.arabicClickToTalk:
        return 'Arabic Click to Talk';
      case AgentType.gemini:
        return 'Gemini AI';
    }
  }
  
  bool get isVoiceBased {
    return this != AgentType.gemini;
  }
  
  bool get isClickToTalk {
    return this == AgentType.clickToTalk || this == AgentType.arabicClickToTalk;
  }
  
  bool get isArabic {
    return this == AgentType.arabic || this == AgentType.arabicClickToTalk;
  }
}

/// Enum for connection states
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Extension for ConnectionState
extension ConnectionStateExtension on ConnectionState {
  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.error:
        return 'Connection Error';
    }
  }
  
  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting => this == ConnectionState.connecting;
}
