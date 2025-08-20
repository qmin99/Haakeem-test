import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart';

class AgentSelectionWidget extends StatelessWidget {
  const AgentSelectionWidget({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF153F1E);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppCtrl>(
      builder: (context, appCtrl, child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_outlined, color: primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Your AI Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Language Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLanguageTab(
                      context,
                      appCtrl,
                      language: AgentLanguage.en,
                      label: 'English',
                      isSelected: appCtrl.selectedLanguage == AgentLanguage.en,
                    ),
                  ),
                  Expanded(
                    child: _buildLanguageTab(
                      context,
                      appCtrl,
                      language: AgentLanguage.ar,
                      label: 'العربية',
                      isSelected: appCtrl.selectedLanguage == AgentLanguage.ar,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Agent Mode Selection - filtered by language
            Row(
              children: appCtrl.agentsFor(appCtrl.selectedLanguage)
                  .map((agentType) => [
                        Expanded(
                          child: _buildAgentOption(
                            context,
                            appCtrl,
                            agentType: agentType,
                          ),
                        ),
                        if (agentType != appCtrl.agentsFor(appCtrl.selectedLanguage).last)
                          const SizedBox(width: 12),
                      ])
                  .expand((e) => e)
                  .toList(),
            ),
            if (appCtrl.selectedAgent == AgentType.attorney) ...[
              const SizedBox(height: 12),
              _buildAgentDescription(
                'Engage in natural, continuous conversation with HAAKEEM about legal matters. Perfect for quick questions and ongoing legal guidance.',
                accentGreen,
              ),
            ],
            if (appCtrl.selectedAgent == AgentType.clickToTalk) ...[
              const SizedBox(height: 12),
              _buildAgentDescription(
                'Speak for as long as you need without interruption. Click "End" when finished, and HAAKEEM will provide a comprehensive response.',
                accentBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTab(
    BuildContext context,
    AppCtrl appCtrl, {
    required AgentLanguage language,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => appCtrl.setLanguage(language),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Map<String, dynamic> _getAgentProperties(AgentType agentType) {
    switch (agentType) {
      case AgentType.attorney:
        return {
          'title': 'Attorney Assistant',
          'subtitle': 'Continuous legal guidance',
          'icon': Icons.gavel_outlined,
          'color': accentGreen,
        };
      case AgentType.clickToTalk:
        return {
          'title': 'Click-to-Talk',
          'subtitle': 'Detailed consultation',
          'icon': Icons.record_voice_over_outlined,
          'color': accentBlue,
        };
      case AgentType.arabic:
        return {
          'title': 'Arabic Assistant',
          'subtitle': 'التحدث بالعربية الفصحى',
          'icon': Icons.translate_outlined,
          'color': accentGreen,
        };
      case AgentType.arabicClickToTalk:
        return {
          'title': 'Arabic Click-to-Talk',
          'subtitle': 'العربية — اضغط للتحدث',
          'icon': Icons.mic_none_outlined,
          'color': accentBlue,
        };
    }
  }

  Widget _buildAgentOption(
    BuildContext context,
    AppCtrl appCtrl, {
    required AgentType agentType,
  }) {
    // Get agent properties based on type
    final agentProps = _getAgentProperties(agentType);
    final isSelected = appCtrl.selectedAgent == agentType;
    
    return GestureDetector(
      onTap: appCtrl.isAgentSwitching ? null : () => appCtrl.selectAgent(agentType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? agentProps['color'].withOpacity(0.1) : lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? agentProps['color'].withOpacity(0.3) : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? agentProps['color'].withOpacity(0.2) : agentProps['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                agentProps['icon'],
                size: 24,
                color: agentProps['color'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              agentProps['title'],
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              agentProps['subtitle'],
              style: GoogleFonts.inter(
                fontSize: 11,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected && !appCtrl.isAgentSwitching) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: agentProps['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else if (appCtrl.isAgentSwitching && isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: agentProps['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(agentProps['color']),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Switching...',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: agentProps['color'],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgentDescription(String description, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 