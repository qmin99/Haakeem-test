import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// A simple button widget that responds to hover interactions
class HoverButton extends StatefulWidget {
  const HoverButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.hoverColor,
    this.borderRadius,
  }) : super(key: key);

  final VoidCallback onPressed;
  final Widget child;
  final Color? hoverColor;
  final BorderRadius? borderRadius;

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: _isHovered 
                ? (widget.hoverColor ?? AppColors.hoverColor)
                : Colors.transparent,
            borderRadius: widget.borderRadius ?? 
                BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

