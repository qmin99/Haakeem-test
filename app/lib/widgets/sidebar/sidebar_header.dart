import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';

/// Header section of the sidebar with app branding
class SidebarHeader extends StatelessWidget {
  const SidebarHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Row(
        children: [
          Container(
            width: AppSizes.iconXLarge,
            height: AppSizes.iconXLarge,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Colors.white,
              size: AppSizes.iconSmall,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Text(
            AppStrings.appName,
            style: GoogleFonts.inter(
              fontSize: AppSizes.fontSizeXXLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

