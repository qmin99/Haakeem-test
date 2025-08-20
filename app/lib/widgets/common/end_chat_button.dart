import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_ctrl.dart' as app_ctrl;

/// Button to end current chat session with confirmation dialog
class EndChatButton extends StatelessWidget {
  const EndChatButton({
    Key? key,
    required this.isVoiceMode,
    required this.onEndChat,
    this.currentChatId,
  }) : super(key: key);

  final bool isVoiceMode;
  final VoidCallback onEndChat;
  final String? currentChatId;

  static const Color primaryGreen = Color(0xFF153F1E);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    if (currentChatId == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showEndChatDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentRed.withOpacity(0.2)),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 16,
          color: accentRed,
        ),
      ),
    );
  }

  void _showEndChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  const Icon(Icons.close_rounded, color: accentRed, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              isVoiceMode ? 'End Voice Chat' : 'End Current Chat',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          isVoiceMode
              ? 'Are you sure you want to end the current voice chat session? Your conversation will be saved to chat history.'
              : 'Are you sure you want to end the current chat session? Your conversation will be saved to chat history.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              onEndChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isVoiceMode ? 'End Voice Chat' : 'End Chat',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
