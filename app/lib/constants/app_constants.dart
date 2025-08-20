import 'package:flutter/material.dart';

/// Application color scheme
class AppColors {
  // Primary colors
  static const Color primaryGreen = Color(0xFF153F1E);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFF8F9FA);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Accent colors
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFEA7C69);
  
  // UI colors
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color hoverColor = Color(0xFFF3F4F6);
}

/// Application sizing constants
class AppSizes {
  // Layout dimensions
  static const double sidebarWidth = 280.0;
  static const double filePreviewPanelWidth = 350.0;
  
  // Border radius
  static const double borderRadiusXSmall = 2.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusXXLarge = 20.0;
  
  // Padding and margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double paddingXXLarge = 24.0;
  
  // Icon sizes
  static const double iconSmall = 14.0;
  static const double iconMedium = 16.0;
  static const double iconLarge = 20.0;
  static const double iconXLarge = 24.0;
  
  // Font sizes
  static const double fontSizeSmall = 10.0;
  static const double fontSizeMedium = 12.0;
  static const double fontSizeLarge = 14.0;
  static const double fontSizeXLarge = 16.0;
  static const double fontSizeXXLarge = 18.0;
}

/// Animation duration constants
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xSlow = Duration(milliseconds: 800);
  
  // Voice-specific durations
  static const Duration voicePulse = Duration(milliseconds: 1000);
  static const Duration voiceSlide = Duration(milliseconds: 300);
  static const Duration voiceLive = Duration(milliseconds: 800);
  static const Duration voiceFloating = Duration(milliseconds: 3000);
}

/// Application string constants
class AppStrings {
  // App info
  static const String appName = 'Legal Assistant';
  static const String appDescription = 'AI-powered legal assistant';
  
  // Voice mode messages
  static const String voiceModeActivated = 'Voice mode activated!';
  static const String voiceModeListening = 'HAAKEEM is listening and ready to respond';
  static const String voiceModeConnecting = 'Establishing connection...';
  static const String voiceModeError = 'Voice mode error. Please try again.';
  
  // File upload messages
  static const String fileUploadSuccess = 'File uploaded successfully!';
  static const String fileUploadError = 'Error uploading file';
  static const String fileDownloadSuccess = 'Downloaded';
  static const String fileDownloadError = 'Download failed';
  
  // Chat messages
  static const String chatHistoryEmpty = 'No conversations yet';
  static const String chatHistoryEmptySubtitle = 'Start a new chat to begin';
  static const String documentsEmpty = 'No documents yet';
  static const String documentsEmptySubtitle = 'Upload files to get started';
  
  // Prompts and hints
  static const String messageInputHint = 'Ask your legal question...';
  static const String messageInputListening = 'Listening...';
  static const String filePromptHint = 'e.g., "Summarize key points" or "Extract names and dates"';
  
  // Error messages
  static const String micPermissionRequired = 'Microphone Permission Required';
  static const String micPermissionMessage = 'Please allow microphone access to use voice features. Check your browser settings and reload the page.';
  static const String speechRecognitionError = 'Speech recognition error. Please try again.';
  
  // Legal levels
  static const String legalLevelBeginner = 'Beginner';
  static const String legalLevelExpert = 'Expert';
  static const String legalLevelBeginnerDesc = 'Simple explanations';
  static const String legalLevelExpertDesc = 'Technical details';
}

/// File type constants
class FileTypeConstants {
  static const List<String> supportedExtensions = [
    'pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'
  ];
  
  static const Map<String, String> mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt': 'text/plain',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
  };
  
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int chunkSize = 16384; // 16KB for streaming
}

/// Voice recognition constants
class VoiceConstants {
  static const Duration listenDuration = Duration(seconds: 30);
  static const Duration pauseDuration = Duration(seconds: 3);
  static const Duration speechTimeout = Duration(seconds: 30);
  static const Duration waveformUpdateInterval = Duration(milliseconds: 80);
  static const Duration liveVoiceUpdateInterval = Duration(milliseconds: 100);
  
  static const String localeEnglish = 'en_US';
  static const String localeArabic = 'ar_SA';
  
  static const int waveformDataPoints = 60;
}

/// Chat constants
class ChatConstants {
  static const int maxConversationHistory = 10; // messages
  static const int maxChatTitleLength = 30;
  static const int maxVoiceChatTitleLength = 25;
  static const double scrollThreshold = 100.0;
}
