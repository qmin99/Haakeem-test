import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../constants/enums.dart';

/// Navigation buttons for switching between sidebar modes
class NavigationButtons extends StatelessWidget {
  const NavigationButtons({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
  }) : super(key: key);

  final SidebarMode currentMode;
  final Function(SidebarMode) onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        children: [
          _buildModeNavButton(
            icon: Icons.folder_outlined,
            title: 'Documents',
            isActive: currentMode == SidebarMode.documents,
            onTap: () => onModeChanged(SidebarMode.documents),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _buildModeNavButton(
            icon: Icons.chat_bubble_outline,
            title: 'Chat History',
            isActive: currentMode == SidebarMode.chat,
            onTap: () => onModeChanged(SidebarMode.chat),
          ),
        ],
      ),
    );
  }

  Widget _buildModeNavButton({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: isActive ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isActive ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.paddingSmall + 2,
            horizontal: AppSizes.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: isActive 
                ? AppColors.primaryGreen.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
            border: isActive
                ? Border.all(color: AppColors.primaryGreen.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                size: AppSizes.iconMedium,
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

