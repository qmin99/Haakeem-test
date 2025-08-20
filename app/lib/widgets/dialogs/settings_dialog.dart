import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_ctrl.dart' as app_ctrl;
import '../../providers/voice_provider.dart';
import '../../constants/app_constants.dart';
import '../agent_selection_widget.dart';

/// Comprehensive settings dialog for app configuration
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
      ),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAgentSettings(),
                    const SizedBox(height: AppSizes.paddingXXLarge),
                    _buildVoiceSettings(),
                    const SizedBox(height: AppSizes.paddingXXLarge),
                    _buildChatSettings(),
                    const SizedBox(height: AppSizes.paddingXXLarge),
                    _buildAboutSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.borderRadiusXLarge),
          topRight: Radius.circular(AppSizes.borderRadiusXLarge),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.primaryGreen,
              size: AppSizes.iconLarge,
            ),
          ),
          const SizedBox(width: AppSizes.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeXXLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXSmall),
                Text(
                  'Configure your AI legal assistant preferences',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeLarge,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentSettings() {
    return Consumer<app_ctrl.AppCtrl>(
      builder: (context, appCtrl, child) => _buildSettingsSection(
        'AI Assistant',
        Icons.psychology_outlined,
        [
          _buildSettingItem(
            'Current Agent',
            _getAgentDisplayName(appCtrl.selectedAgent),
            subtitle: 'Tap to change your AI assistant',
            onTap: () => _showAgentSelectionSheet(context, appCtrl),
          ),
          _buildSettingItem(
            'Language',
            _getLanguageDisplayName(appCtrl),
            subtitle: 'Interface and conversation language',
            trailing: _buildLanguageToggle(appCtrl),
          ),
          _buildSettingItem(
            'Contextual AI',
            appCtrl.useContextualAI ? 'Enabled' : 'Disabled',
            subtitle: 'AI remembers previous conversation context',
            trailing: Switch(
              value: appCtrl.useContextualAI,
              onChanged: (value) {
                appCtrl.toggleContextualAI();
              },
              activeColor: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSettings() {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) => _buildSettingsSection(
        'Voice Settings',
        Icons.mic_outlined,
        [
          _buildSettingItem(
            'Microphone Permission',
            voiceProvider.hasMicPermission ? 'Granted' : 'Not granted',
            subtitle: 'Required for voice conversations',
            trailing: Icon(
              voiceProvider.hasMicPermission ? Icons.check_circle : Icons.error_outline,
              color: voiceProvider.hasMicPermission ? AppColors.accentGreen : AppColors.accentRed,
            ),
          ),
          _buildSettingItem(
            'Voice Quality',
            'Standard',
            subtitle: 'Audio processing quality for speech recognition',
          ),
          _buildSettingItem(
            'Auto-start Voice Mode',
            'Disabled',
            subtitle: 'Automatically start new chats in voice mode',
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Implement auto-start voice mode setting
              },
              activeColor: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSettings() {
    return _buildSettingsSection(
      'Chat Settings',
      Icons.chat_bubble_outline,
      [
        _buildSettingItem(
          'Default Legal Level',
          'Beginner',
          subtitle: 'Default complexity level for new chats',
          onTap: () => _showLegalLevelSelector(),
        ),
        _buildSettingItem(
          'Chat History',
          '10 messages',
          subtitle: 'Number of messages to remember in conversations',
        ),
        _buildSettingItem(
          'Auto-save Chats',
          'Enabled',
          subtitle: 'Automatically save conversation history',
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // Implement auto-save setting
            },
            activeColor: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      'About',
      Icons.info_outline,
      [
        _buildSettingItem(
          'Version',
          '1.0.0',
          subtitle: 'Current app version',
        ),
        _buildSettingItem(
          'Privacy Policy',
          'View',
          subtitle: 'How we handle your data',
          onTap: () => _showPrivacyPolicy(),
        ),
        _buildSettingItem(
          'Terms of Service',
          'View',
          subtitle: 'Legal terms and conditions',
          onTap: () => _showTermsOfService(),
        ),
        _buildSettingItem(
          'Contact Support',
          'Get help',
          subtitle: 'Need assistance? Reach out to our team',
          onTap: () => _showContactSupport(),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: AppSizes.iconMedium),
            const SizedBox(width: AppSizes.paddingMedium),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeXLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingLarge),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String value, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSizes.paddingXSmall),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontSizeMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing,
              ] else ...[
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGreen,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSizes.paddingMedium),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: AppSizes.fontSizeLarge,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(app_ctrl.AppCtrl appCtrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('EN', true, appCtrl),
          _buildLanguageOption('AR', false, appCtrl),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, bool isEnglish, app_ctrl.AppCtrl appCtrl) {
    final currentLang = _getLanguageDisplayName(appCtrl);
    final isSelected = (isEnglish && currentLang == 'English') || 
                     (!isEnglish && currentLang == 'العربية');

    return GestureDetector(
      onTap: () {
        // Toggle language logic here
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
                backgroundColor: AppColors.lightBackground,
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingLarge),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                ),
              ),
              child: Text(
                'Save Settings',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAgentDisplayName(dynamic agentType) {
    final agentTypeName = agentType.toString().split('.').last;
    switch (agentTypeName) {
      case 'attorney':
        return 'Attorney Assistant';
      case 'clickToTalk':
        return 'Click-to-Talk';
      case 'arabic':
        return 'Arabic Assistant';
      case 'arabicClickToTalk':
        return 'Arabic Click-to-Talk';
      case 'gemini':
        return 'Gemini AI';
      default:
        return 'Unknown Agent';
    }
  }

  String _getLanguageDisplayName(app_ctrl.AppCtrl appCtrl) {
    final agent = appCtrl.selectedAgent.toString().split('.').last;
    if (agent.contains('arabic') || agent.contains('Arabic')) {
      return 'العربية';
    }
    return 'English';
  }

  void _showAgentSelectionSheet(BuildContext context, app_ctrl.AppCtrl appCtrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.primaryGreen),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Text(
                      'Choose AI Assistant',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeXLarge,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                const AgentSelectionWidget(),
                const SizedBox(height: AppSizes.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
                          backgroundColor: AppColors.lightBackground,
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingLarge),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          'Use Selected Assistant',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLegalLevelSelector() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Legal level selection coming soon!')),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy coming soon!')),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service coming soon!')),
    );
  }

  void _showContactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support coming soon!')),
    );
  }
}