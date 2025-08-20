import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../constants/app_constants.dart';

/// Custom painter for drawing audio waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color primaryColor;
  final Color accentColor;

  WaveformPainter({
    required this.waveformData,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    // Save canvas state and clip to bounds
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final x = (i / waveformData.length) * width;
      // Normalize amplitude to 0-1 range and compute barHeight
      final normalizedAmplitude = waveformData[i].clamp(0.0, 1.0);
      final barHeight = normalizedAmplitude * height;

      final t = i / waveformData.length;
      paint.color = Color.lerp(
        primaryColor.withOpacity(0.7),
        accentColor.withOpacity(0.9),
        t,
      )!;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }

    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Widget that displays a draggable waveform visualization
class WaveformDisplay extends StatefulWidget {
  const WaveformDisplay({
    Key? key,
    required this.waveformData,
    required this.isVisible,
    this.isVoiceMode = false,
    this.isLiveVoiceActive = false,
    this.isRecording = false,
    this.liveTranscription = '',
    this.onStop,
    this.initialPosition = const Offset(640, 500),
  }) : super(key: key);

  final List<double> waveformData;
  final bool isVisible;
  final bool isVoiceMode;
  final bool isLiveVoiceActive;
  final bool isRecording;
  final String liveTranscription;
  final VoidCallback? onStop;
  final Offset initialPosition;

  @override
  State<WaveformDisplay> createState() => _WaveformDisplayState();
}

class _WaveformDisplayState extends State<WaveformDisplay> {
  late Offset _position;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx)
                  .clamp(0.0, MediaQuery.of(context).size.width - 300),
              (_position.dy + details.delta.dy)
                  .clamp(0.0, MediaQuery.of(context).size.height - 120),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: _buildWaveformContainer(),
      ),
    );
  }

  Widget _buildWaveformContainer() {
    return Container(
      width: 300,
      height: 120,
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusXXLarge),
        border: Border.all(
          color: widget.isVoiceMode
              ? AppColors.accentGreen.withOpacity(0.2)
              : AppColors.primaryGreen.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (widget.liveTranscription.isNotEmpty &&
              (widget.isRecording || widget.isVoiceMode)) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            _buildTranscriptionDisplay(),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
          Expanded(
            child: CustomPaint(
              size: const Size(268, 40),
              painter: WaveformPainter(
                waveformData: widget.waveformData,
                primaryColor: widget.isVoiceMode 
                    ? AppColors.accentGreen 
                    : AppColors.primaryGreen,
                accentColor: AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.drag_indicator,
              color: (widget.isVoiceMode 
                  ? AppColors.accentGreen 
                  : AppColors.primaryGreen).withOpacity(0.7),
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSizes.paddingSmall - 2),
            Text(
              widget.isVoiceMode
                  ? 'Live Conversation Active...'
                  : 'Recording...',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        if (widget.isVoiceMode && 
            widget.isLiveVoiceActive && 
            widget.onStop != null)
          _buildStopButton(),
      ],
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: widget.onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSmall,
          vertical: AppSizes.paddingXSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stop_rounded,
              size: AppSizes.fontSizeMedium,
              color: AppColors.accentRed,
            ),
            const SizedBox(width: AppSizes.paddingXSmall),
            Text(
              'Stop',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.accentRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(
        '"${widget.liveTranscription}"',
        style: const TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

