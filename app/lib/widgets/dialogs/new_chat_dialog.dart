import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/enums.dart' ;
import '../../controllers/app_ctrl.dart' hide LegalLevel;
import '../../providers/chat_provider.dart';
import '../../providers/voice_provider.dart';

/// Comprehensive new chat dialog with agent selection and settings
class NewChatDialog extends StatefulWidget {
  const NewChatDialog({Key? key}) : super(key: key);

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  LegalLevel _selectedLegalLevel = LegalLevel.beginner;
  bool _isVoiceMode = false;

  @override
  Widget build(BuildContext context) {
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                  ),
                  child: const Icon(
                    Icons.add_comment_outlined,
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
                        'Start New Legal Consultation',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontSizeXXLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXSmall),
                      Text(
                        'Choose your consultation preferences',
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
            
            const SizedBox(height: AppSizes.paddingXXLarge),
            
            // Legal Level Selection
            Text(
              'Experience Level',
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeXLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            _buildLegalLevelSelection(),
            
            const SizedBox(height: AppSizes.paddingXXLarge),
            
            // Voice Mode Toggle
            _buildVoiceModeToggle(),
            
            const SizedBox(height: AppSizes.paddingXXLarge),
            
            // Action Buttons
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
                  child: ElevatedButton(
                    onPressed: _createNewChat,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: AppSizes.iconMedium),
                        const SizedBox(width: AppSizes.paddingMedium),
                        Text(
                          'Start Consultation',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLevelSelection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: LegalLevel.values.map((level) {
          final isSelected = _selectedLegalLevel == level;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedLegalLevel = level),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.borderColor,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: AppSizes.paddingLarge),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.displayName,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingXSmall),
                          Text(
                            level.fullDescription,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.fontSizeMedium,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoiceModeToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.mic_outlined,
              color: AppColors.accentBlue,
              size: AppSizes.iconLarge,
            ),
          ),
          const SizedBox(width: AppSizes.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Mode',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXSmall),
                Text(
                  'Start with voice conversation instead of text chat',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isVoiceMode,
            onChanged: (value) => setState(() => _isVoiceMode = value),
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  void _createNewChat() {
    final chatProvider = context.read<ChatProvider>();
    final voiceProvider = context.read<VoiceProvider>();
    
    // Create new chat with selected options
    chatProvider.createNewChat(
      isVoiceMode: _isVoiceMode,
      legalLevel: _selectedLegalLevel,
    );
    
    // If voice mode is selected, activate it
    if (_isVoiceMode) {
      final appCtrl = context.read<AppCtrl>();
      voiceProvider.toggleVoiceMode(
        appCtrl: appCtrl,
        onVoiceModeActivated: () {
          // Add voice mode activation message
          chatProvider.addMessage(
            "Voice mode activated! ${_getLegalLevelMessage(_selectedLegalLevel)} Ready for your legal questions.",
            false,
          );
        },
      );
    }
    
    Navigator.pop(context);
  }

  String _getLegalLevelMessage(LegalLevel level) {
    return level == LegalLevel.beginner
        ? "I'll explain legal concepts in simple, easy-to-understand terms with practical examples."
        : "I'll provide detailed legal analysis with technical terminology and comprehensive citations.";
  }
}
