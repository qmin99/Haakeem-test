import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_ctrl.dart' as app_ctrl;
import '../../providers/chat_provider.dart';
import '../../providers/voice_provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/enums.dart';
import 'end_chat_button.dart';

/// Top header with chat status, agent info, and action buttons
class TopHeader extends StatelessWidget {
  const TopHeader({
    Key? key,
    this.onSettings,
    this.onCall,
  }) : super(key: key);

  final VoidCallback? onSettings;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Consumer3<ChatProvider, VoiceProvider, app_ctrl.AppCtrl>(
        builder: (context, chatProvider, voiceProvider, appCtrl, child) {
          return Row(
            children: [
              Expanded(
                child: _buildTitleSection(voiceProvider, appCtrl),
              ),
              _buildActionButtons(chatProvider, voiceProvider, appCtrl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(VoiceProvider voiceProvider, app_ctrl.AppCtrl appCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          voiceProvider.isVoiceMode
              ? (appCtrl.connectionState == app_ctrl.ConnectionState.connected
                  ? 'HAAKEEM Assistant'
                  : 'Voice AI Assistant')
              : 'AI Legal Assistant',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          voiceProvider.isVoiceMode
              ? (appCtrl.connectionState == app_ctrl.ConnectionState.connected
                  ? _getAgentStatusText(appCtrl.selectedAgent)
                  : 'Connecting...')
              : (appCtrl.useContextualAI
                  ? 'Remembering conversation'
                  : 'Fresh responses'),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ChatProvider chatProvider, VoiceProvider voiceProvider, app_ctrl.AppCtrl appCtrl) {
    return Row(
      children: [
        if (!voiceProvider.isVoiceMode) _buildContextualAIBadge(appCtrl),
        if (chatProvider.currentChatId != null) ...[
          const SizedBox(width: 12),
          _buildLegalLevelBadge(chatProvider.currentLegalLevel),
          const SizedBox(width: 12),
          EndChatButton(
            isVoiceMode: voiceProvider.isVoiceMode,
            onEndChat: () => _handleEndChat(chatProvider, voiceProvider, appCtrl),
            currentChatId: chatProvider.currentChatId,
          ),
        ],
        if (onCall != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onCall,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: const Icon(
                Icons.phone_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        if (onSettings != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSettings,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContextualAIBadge(app_ctrl.AppCtrl appCtrl) {
    return GestureDetector(
      onTap: () => appCtrl.toggleContextualAI(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: appCtrl.useContextualAI
              ? AppColors.accentGreen.withOpacity(0.1)
              : AppColors.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: appCtrl.useContextualAI
                ? AppColors.accentGreen.withOpacity(0.3)
                : AppColors.accentBlue.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              appCtrl.useContextualAI ? Icons.history : Icons.refresh,
              size: 14,
              color: appCtrl.useContextualAI ? AppColors.accentGreen : AppColors.accentBlue,
            ),
            const SizedBox(width: 6),
            Text(
              appCtrl.useContextualAI ? 'Memory On' : 'Fresh Start',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: appCtrl.useContextualAI ? AppColors.accentGreen : AppColors.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLevelBadge(LegalLevel currentLegalLevel) {
    final isExpert = currentLegalLevel == LegalLevel.expert;
    final color = isExpert ? AppColors.accentRed : AppColors.accentPurple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpert ? Icons.gavel_outlined : Icons.school_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${isExpert ? 'Expert' : 'Beginner'} Mode',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getAgentStatusText(dynamic selectedAgent) {
    final agentName = selectedAgent.toString().split('.').last;
    switch (agentName) {
      case 'attorney':
        return 'Attorney agent active';
      case 'arabic':
        return 'Arabic agent active';
      case 'clickToTalk':
        return 'Click-to-talk agent ready';
      case 'arabicClickToTalk':
        return 'Arabic click-to-talk agent ready';
      default:
        return 'Agent active';
    }
  }

  void _handleEndChat(ChatProvider chatProvider, VoiceProvider voiceProvider, app_ctrl.AppCtrl appCtrl) async {
    if (voiceProvider.isVoiceMode) {
      await voiceProvider.toggleVoiceMode(appCtrl: appCtrl);
    }
    chatProvider.clearCurrentChat();
  }
}
