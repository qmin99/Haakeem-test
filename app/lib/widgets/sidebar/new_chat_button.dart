import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';

/// Button to create a new chat session
class NewChatButton extends StatelessWidget {
  const NewChatButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.paddingMedium,
            horizontal: AppSizes.paddingLarge,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: AppSizes.iconLarge,
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Text(
                'New chat',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

