import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

/// Utility class for formatting text with markdown-like syntax
class TextFormatter {
  
  /// Parse formatted text and return a TextSpan with styling
  static TextSpan parseFormattedText(String text, bool isUser) {
    return TextSpan(
      children: _parseTextWithFormatting(text, isUser),
    );
  }

  /// Parse text with formatting and return list of InlineSpans
  static List<InlineSpan> _parseTextWithFormatting(String text, bool isUser) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      if (lineIndex > 0) {
        spans.add(const TextSpan(text: '\n'));
      }

      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: ' '));
        continue;
      }

      if (line.trim().startsWith('• ')) {
        spans.addAll(_parseListItem(line, isUser, isBullet: true));
      } else if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        spans.addAll(_parseListItem(line, isUser, isBullet: false));
      } else if (line.trim().startsWith('* ')) {
        final modifiedLine = line.replaceFirst('* ', '• ');
        spans.addAll(_parseListItem(modifiedLine, isUser, isBullet: true));
      } else {
        spans.addAll(_parseInlineFormatting(line, isUser));
      }
    }

    return spans;
  }

  /// Parse list items with bullets or numbers
  static List<InlineSpan> _parseListItem(String line, bool isUser, {required bool isBullet}) {
    final spans = <InlineSpan>[];

    if (isBullet) {
      spans.add(TextSpan(
        text: '• ',
        style: GoogleFonts.inter(
          fontSize: AppSizes.fontSizeLarge + 1,
          fontWeight: FontWeight.w600,
          color: isUser ? Colors.white : AppColors.primaryGreen,
          height: 1.6,
        ),
      ));

      final content = line.replaceFirst(RegExp(r'^\s*•\s*'), '');
      spans.addAll(_parseInlineFormatting(content, isUser));
    } else {
      final match = RegExp(r'^(\s*)(\d+)\.\s+(.*)$').firstMatch(line);
      if (match != null) {
        final indent = match.group(1) ?? '';
        final number = match.group(2) ?? '';
        final content = match.group(3) ?? '';

        spans.add(TextSpan(text: indent));
        spans.add(TextSpan(
          text: '$number. ',
          style: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeLarge + 1,
            fontWeight: FontWeight.w600,
            color: isUser ? Colors.white : AppColors.primaryGreen,
            height: 1.6,
          ),
        ));

        spans.addAll(_parseInlineFormatting(content, isUser));
      }
    }

    return spans;
  }

  /// Parse inline formatting like bold, italic, code
  static List<InlineSpan> _parseInlineFormatting(String text, bool isUser) {
    final spans = <InlineSpan>[];
    String remaining = text;

    while (remaining.isNotEmpty) {
      final boldMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(remaining);
      final italicMatch = RegExp(r'(?<!\*)\*([^*\n]+?)\*(?!\*)').firstMatch(remaining);
      final codeMatch = RegExp(r'`([^`\n]+?)`').firstMatch(remaining);
      final codeBlockMatch = RegExp(r'```([\s\S]*?)```').firstMatch(remaining);

      final matches = <MapEntry<int, Match>>[
        if (boldMatch != null) MapEntry(boldMatch.start, boldMatch),
        if (italicMatch != null) MapEntry(italicMatch.start, italicMatch),
        if (codeMatch != null) MapEntry(codeMatch.start, codeMatch),
        if (codeBlockMatch != null) MapEntry(codeBlockMatch.start, codeBlockMatch),
      ];

      if (matches.isEmpty) {
        spans.add(_createPlainTextSpan(remaining, isUser));
        break;
      }

      matches.sort((a, b) => a.key.compareTo(b.key));
      final earliestMatch = matches.first.value;

      if (earliestMatch.start > 0) {
        spans.add(_createPlainTextSpan(
            remaining.substring(0, earliestMatch.start), isUser));
      }

      if (earliestMatch == boldMatch) {
        spans.add(_createBoldTextSpan(boldMatch!.group(1)!, isUser));
      } else if (earliestMatch == italicMatch) {
        spans.add(_createItalicTextSpan(italicMatch!.group(1)!, isUser));
      } else if (earliestMatch == codeMatch) {
        spans.add(_createCodeSpan(codeMatch!.group(1)!, isUser));
      } else if (earliestMatch == codeBlockMatch) {
        spans.add(_createCodeBlockSpan(codeBlockMatch!.group(1)!, isUser));
      }

      remaining = remaining.substring(earliestMatch.end);
    }

    return spans;
  }

  /// Create plain text span
  static TextSpan _createPlainTextSpan(String text, bool isUser) {
    return TextSpan(
      text: text,
      style: GoogleFonts.inter(
        fontSize: AppSizes.fontSizeLarge + 1,
        fontWeight: FontWeight.w400,
        color: isUser ? Colors.white : AppColors.textPrimary,
        height: 1.6,
      ),
    );
  }

  /// Create bold text span
  static TextSpan _createBoldTextSpan(String text, bool isUser) {
    return TextSpan(
      text: text,
      style: GoogleFonts.inter(
        fontSize: AppSizes.fontSizeLarge + 1,
        fontWeight: FontWeight.w700,
        color: isUser ? Colors.white : AppColors.textPrimary,
        height: 1.6,
      ),
    );
  }

  /// Create italic text span
  static TextSpan _createItalicTextSpan(String text, bool isUser) {
    return TextSpan(
      text: text,
      style: GoogleFonts.inter(
        fontSize: AppSizes.fontSizeLarge + 1,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: isUser ? Colors.white : AppColors.textPrimary,
        height: 1.6,
      ),
    );
  }

  /// Create inline code span
  static WidgetSpan _createCodeSpan(String text, bool isUser) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSmall - 2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withOpacity(0.2)
              : AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusXSmall),
          border: Border.all(
            color: isUser
                ? Colors.white.withOpacity(0.3)
                : AppColors.primaryGreen.withOpacity(0.2),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.robotoMono(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w500,
            color: isUser ? Colors.white : AppColors.primaryGreen,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  /// Create code block span
  static WidgetSpan _createCodeBlockSpan(String text, bool isUser) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: isUser 
              ? Colors.white.withOpacity(0.1) 
              : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(
            color: isUser 
                ? Colors.white.withOpacity(0.2) 
                : AppColors.borderColor,
          ),
        ),
        child: Text(
          text.trim(),
          style: GoogleFonts.robotoMono(
            fontSize: AppSizes.fontSizeMedium + 1,
            fontWeight: FontWeight.w400,
            color: isUser 
                ? Colors.white.withOpacity(0.9) 
                : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Truncate text to a specific length
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalize first letter of a string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Extract first sentence from text
  static String extractFirstSentence(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'));
    return sentences.isNotEmpty ? sentences.first.trim() : text;
  }
}

