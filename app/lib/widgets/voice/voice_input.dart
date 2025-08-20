import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Voice input button with sophisticated animations and state management
class VoiceInput extends StatefulWidget {
  const VoiceInput({
    Key? key,
    required this.isListening,
    required this.speechEnabled,
    required this.onToggleListening,
    this.size = 16.0,
  }) : super(key: key);

  final bool isListening;
  final bool speechEnabled;
  final VoidCallback onToggleListening;
  final double size;

  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color primaryGreen = Color(0xFF153F1E);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
  void didUpdateWidget(VoiceInput oldWidget) {
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
            ? LinearGradient(
                colors: [primaryGreen, primaryGreen.withOpacity(0.8)])
            : const LinearGradient(
                colors: [lightBackground, lightBackground],
              ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isListening 
              ? primaryGreen.withOpacity(0.3)
              : borderColor,
          width: 1,
        ),
        boxShadow: widget.isListening ? [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
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
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: widget.isListening
                ? _buildListeningIndicator()
                : Icon(
                    Icons.mic_rounded,
                    color: widget.speechEnabled
                        ? textSecondary
                        : textSecondary.withOpacity(0.3),
                    size: widget.size,
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
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.8 + (math.sin(value * 4 * math.pi) * 0.2),
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
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
                width: widget.size * 0.3,
                height: widget.size * 0.3,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic_off_outlined,
                  color: accentRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Microphone Permission Required',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Please allow microphone access to use voice features. Check your browser settings and reload the page.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would trigger permission request
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
