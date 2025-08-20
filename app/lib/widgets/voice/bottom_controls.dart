import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/enums.dart';
import '../../providers/file_provider.dart';
import '../../providers/voice_provider.dart';
import '../chat/message_input.dart';
import '../click_to_talk_controls.dart';

/// Bottom control panel with voice controls and message input
class BottomControls extends StatelessWidget {
  const BottomControls({
    Key? key,
    required this.isVoiceMode,
    required this.onSendMessage,
    this.showClickToTalkButton = false,
    this.onToggleRecording,
  }) : super(key: key);

  final bool isVoiceMode;
  final Function(String)? onSendMessage;
  final bool showClickToTalkButton;
  final VoidCallback? onToggleRecording;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MessageInput(
          isVoiceMode: isVoiceMode,
          onSendMessage: onSendMessage,
        ),
        if (isVoiceMode && showClickToTalkButton) const ClickToTalkControls(),
      ],
    );
  }


}
