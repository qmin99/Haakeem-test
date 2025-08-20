import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../controllers/app_ctrl.dart';
import '../common/hover_button.dart';

/// Footer section of the sidebar with action buttons
class SidebarFooter extends StatelessWidget {
  const SidebarFooter({
    Key? key,
    required this.onSettingsPressed,
    required this.onCallPressed,
  }) : super(key: key);

  final VoidCallback onSettingsPressed;
  final VoidCallback onCallPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Current agent indicator
          Consumer<AppCtrl>(
            builder: (context, appCtrl, child) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingXSmall),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                    ),
                    child: Icon(
                      _getAgentIcon(appCtrl.selectedAgent),
                      size: AppSizes.iconSmall,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAgentDisplayName(appCtrl.selectedAgent),
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeSmall + 1,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Text(
                          _getConnectionStatusText(appCtrl.connectionState),
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildConnectionIndicator(appCtrl.connectionState),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: HoverButton(
                  onPressed: onCallPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingSmall + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                      border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: AppSizes.iconMedium,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: AppSizes.paddingXSmall),
                        Text(
                          'Call',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: HoverButton(
                  onPressed: onSettingsPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingSmall + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                      border: Border.all(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          size: AppSizes.iconMedium,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSizes.paddingXSmall),
                        Text(
                          'Settings',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getAgentIcon(dynamic selectedAgent) {
    // This would need to be updated based on the actual AgentType enum
    return Icons.psychology_outlined;
  }

  String _getAgentDisplayName(dynamic selectedAgent) {
    // This would need to be updated based on the actual AgentType enum
    return 'Attorney Agent';
  }

  String _getConnectionStatusText(dynamic connectionState) {
    // This would need to be updated based on the actual ConnectionState enum
    return 'Connected';
  }

  Widget _buildConnectionIndicator(dynamic connectionState) {
    // For now, just show a simple green dot
    return Container(
      width: AppSizes.paddingSmall,
      height: AppSizes.paddingSmall,
      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

