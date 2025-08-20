import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart';

class ClickToTalkControls extends StatelessWidget {
  const ClickToTalkControls({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF153F1E);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppCtrl>(
      builder: (context, appCtrl, child) {
        // Check for click-to-talk agent types from app_ctrl
        final currentAgent = appCtrl.selectedAgent;
        final isClickToTalk = currentAgent.toString().contains('clickToTalk') || 
                             currentAgent.toString().contains('ClickToTalk');
        
        if (!isClickToTalk) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.record_voice_over_outlined, color: accentBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    appCtrl.selectedAgent == AgentType.arabicClickToTalk
                        ? 'Arabic Click-to-Talk'
                        : 'Click-to-Talk Mode',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(appCtrl),
                ],
              ),
              const SizedBox(height: 16),
              _buildCurrentStateDisplay(appCtrl),
              const SizedBox(height: 16),
              _buildControlButtons(appCtrl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(AppCtrl appCtrl) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (appCtrl.clickToTalkState) {
      case ClickToTalkState.idle:
        statusColor = textSecondary;
        statusText = 'Ready';
        statusIcon = Icons.radio_button_unchecked;
        break;
      case ClickToTalkState.listening:
        statusColor = accentRed;
        statusText = 'Recording';
        statusIcon = Icons.fiber_manual_record;
        break;
      case ClickToTalkState.readyToSend:
        statusColor = accentGreen;
        statusText = 'Ready to Send';
        statusIcon = Icons.check_circle_outline;
        break;
      case ClickToTalkState.processing:
        statusColor = accentBlue;
        statusText = 'Processing';
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateDisplay(AppCtrl appCtrl) {
    if (appCtrl.clickToTalkState == ClickToTalkState.idle) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: accentBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Click "Start Speaking" to begin. Speak for as long as you need, then click "End" to get HAAKEEM\'s response.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (appCtrl.clickToTalkState == ClickToTalkState.listening) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentRed.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: accentRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recording... Speak freely for as long as you need.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: accentRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, color: textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${appCtrl.formatDuration(appCtrl.speakingDuration)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (appCtrl.clickToTalkState == ClickToTalkState.readyToSend) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: accentGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recording complete! Click "Send" for HAAKEEM to process your message.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: accentGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (appCtrl.clickToTalkState == ClickToTalkState.processing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'HAAKEEM is processing your message...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: accentBlue,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControlButtons(AppCtrl appCtrl) {
    if (appCtrl.clickToTalkState == ClickToTalkState.idle) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: appCtrl.startClickToTalkListening,
          icon: Icon(Icons.mic, size: 20),
          label: Text(
            'Start Speaking',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    if (appCtrl.clickToTalkState == ClickToTalkState.listening) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: appCtrl.cancelClickToTalk,
              icon: Icon(Icons.close, size: 18),
              label: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentRed,
                side: BorderSide(color: accentRed.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: appCtrl.stopClickToTalkListening,
              icon: Icon(Icons.stop, size: 18),
              label: Text(
                'End Speaking',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    if (appCtrl.clickToTalkState == ClickToTalkState.readyToSend) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: appCtrl.cancelClickToTalk,
              icon: Icon(Icons.delete_outline, size: 18),
              label: Text(
                'Discard',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textSecondary,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: appCtrl.sendClickToTalkResponse,
              icon: Icon(Icons.send, size: 18),
              label: Text(
                'Send to HAAKEEM',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    if (appCtrl.clickToTalkState == ClickToTalkState.processing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          child: Text(
            'Processing...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: textSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
} 