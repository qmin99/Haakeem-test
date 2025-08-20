import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../constants/app_constants.dart';

/// Voice input button with listening animation
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    Key? key,
    required this.isListening,
    required this.speechEnabled,
    required this.onToggleListening,
  }) : super(key: key);

  final bool isListening;
  final bool speechEnabled;
  final VoidCallback onToggleListening;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: AppDurations.voicePulse,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isListening ? _pulseAnimation.value : 1.0,
          child: _buildButton(),
        );
      },
    );
  }

  Widget _buildButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.isListening
            ? const LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF1E5A2E)])
            : const LinearGradient(
                colors: [AppColors.lightBackground, AppColors.lightBackground],
              ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: widget.isListening 
              ? AppColors.primaryGreen.withOpacity(0.3)
              : AppColors.borderColor,
          width: 1,
        ),
        boxShadow: widget.isListening ? [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.speechEnabled 
              ? widget.onToggleListening 
              : _showPermissionDialog,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingSmall),
            child: widget.isListening
                ? _buildListeningIndicator()
                : Icon(
                    Icons.mic_rounded,
                    color: widget.speechEnabled
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withOpacity(0.3),
                    size: AppSizes.iconLarge,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      onEnd: () {
        if (mounted && widget.isListening) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
      builder: (context, double value, child) {
        return SizedBox(
          width: AppSizes.iconLarge,
          height: AppSizes.iconLarge,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.8 + (math.sin(value * 4 * math.pi) * 0.2),
                child: Container(
                  width: AppSizes.iconMedium,
                  height: AppSizes.iconMedium,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Container(
                width: AppSizes.paddingXSmall,
                height: AppSizes.paddingXSmall,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusXXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
              child: const Icon(
                Icons.mic_off_outlined,
                color: AppColors.accentRed,
                size: AppSizes.iconLarge,
              ),
            ),
            const SizedBox(width: AppSizes.paddingMedium),
            Expanded(
              child: Text(
                AppStrings.micPermissionRequired,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeXLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.micPermissionMessage,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would trigger permission request
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

