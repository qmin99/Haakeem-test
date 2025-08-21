import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:audioplayers/audioplayers.dart';

import '../services/livekit_service.dart';
import '../services/token_service.dart';
enum AppScreenState { welcome, agent }
enum AgentScreenState { visualizer, transcription }
enum ConnectionState { disconnected, connecting, connected }
enum AgentLanguage { en, ar }
enum AgentType { attorney, clickToTalk, arabic, arabicClickToTalk }
enum ClickToTalkState { idle, listening, readyToSend, processing }

class AppCtrl extends ChangeNotifier {
  AppScreenState appScreenState = AppScreenState.welcome;
  ConnectionState connectionState = ConnectionState.disconnected;
  AgentScreenState agentScreenState = AgentScreenState.transcription;

  AgentLanguage selectedLanguage = AgentLanguage.en;
  AgentType selectedAgent = AgentType.attorney;
  ClickToTalkState clickToTalkState = ClickToTalkState.idle;

  Timer? _clickToTalkTimer;
  Duration _speakingDuration = Duration.zero;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _keepAliveTimer;

  bool isUserCameEnabled = false;
  bool isScreenshareEnabled = false;
  final messageCtrl = TextEditingController();
  final messageFocusNode = FocusNode();
  bool isSendButtonEnabled = false;
  bool useContextualAI = true;

  late final sdk.Room room = sdk.Room(roomOptions: const sdk.RoomOptions(enableVisualizer: true));
  late final components.RoomContext roomContext = components.RoomContext(room: room);
  final tokenService = TokenService();

  bool _isAgentSwitching = false;
  DateTime? _lastSwitchAttempt;

  bool get isAgentSwitching => _isAgentSwitching;
  bool get isClickToTalkListening => clickToTalkState == ClickToTalkState.listening;
  bool get isClickToTalkReady => clickToTalkState == ClickToTalkState.readyToSend;
  bool get isClickToTalkProcessing => clickToTalkState == ClickToTalkState.processing;
  Duration get speakingDuration => _speakingDuration;

  AppCtrl() {
    messageCtrl.addListener(() {
      final v = messageCtrl.text.isNotEmpty;
      if (v != isSendButtonEnabled) {
        isSendButtonEnabled = v;
        notifyListeners();
      }
    });
    room.addListener(_onRoomEvent);
  }

  @override
  void dispose() {
    messageCtrl.dispose();
    _clickToTalkTimer?.cancel();
    _audioPlayer.dispose();
    room.removeListener(_onRoomEvent);
    super.dispose();
  }

  void _onRoomEvent() {
    notifyListeners();
  }

  void setupAgentMessageHandlers({
    Function(String)? onAgentMessage,
    Function(String)? onError,
  }) {
    final liveKitService = LiveKitService();
    liveKitService.setRoom(room);

    liveKitService.setupDataListener(
      onTextReceived: (message) {
        debugPrint('📥 Agent message received: $message');
        onAgentMessage?.call(message);
      },
      onError: (error) {
        debugPrint('❌ Agent communication error: $error');
        onError?.call(error);
      },
    );
  }

  List<AgentType> agentsFor(AgentLanguage lang) {
    return lang == AgentLanguage.en
        ? [AgentType.attorney, AgentType.clickToTalk]
        : [AgentType.arabic, AgentType.arabicClickToTalk];
  }

  Future<void> selectAgent(AgentType targetAgent) async {
    if (selectedAgent == targetAgent) return;

    final now = DateTime.now();
    if (_lastSwitchAttempt != null &&
        now.difference(_lastSwitchAttempt!) < const Duration(milliseconds: 1500)) {
      debugPrint('🔄 Agent switch too frequent, ignoring');
      return;
    }

    _lastSwitchAttempt = now;
    _isAgentSwitching = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 150));

      if (connectionState == ConnectionState.connected) {
        await _performAgentSwitch(targetAgent);
      }

      selectedAgent = targetAgent;
      selectedLanguage = _getLanguageForAgent(targetAgent);

      if (connectionState == ConnectionState.connected) {
        await _configureMicrophoneForAgent(targetAgent);
      }

      debugPrint('✅ Agent switched successfully to: ${targetAgent.name}');
    } catch (e) {
      debugPrint('❌ Error during agent switch: $e');
    } finally {
      _isAgentSwitching = false;
      notifyListeners();
    }
  }

  AgentLanguage _getLanguageForAgent(AgentType agent) {
    return agent == AgentType.arabic || agent == AgentType.arabicClickToTalk
        ? AgentLanguage.ar
        : AgentLanguage.en;
  }

  Future<void> _performAgentSwitch(AgentType targetAgent) async {
    final lp = room.localParticipant;
    if (lp == null) return;

    String agentCommand;
    switch (targetAgent) {
      case AgentType.attorney:
        agentCommand = 'switch_to_attorney';
        break;
      case AgentType.clickToTalk:
        agentCommand = 'switch_to_click_to_talk';
        break;
      case AgentType.arabic:
        agentCommand = 'switch_to_arabic';
        break;
      case AgentType.arabicClickToTalk:
        agentCommand = 'switch_to_arabic_click_to_talk';
        break;
    }

    debugPrint('📤 Sending agent switch command: $agentCommand');
    await lp.publishData(utf8.encode(agentCommand));
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _configureMicrophoneForAgent(AgentType agent) async {
    final lp = room.localParticipant;
    if (lp == null) return;

    bool shouldEnableMic = agent == AgentType.attorney || agent == AgentType.arabic;

    await lp.setMicrophoneEnabled(shouldEnableMic);
    debugPrint('🎤 Microphone ${shouldEnableMic ? 'enabled' : 'disabled'} for ${agent.name}');
  }

void setLanguage(AgentLanguage language) {
  selectedLanguage = language;
  notifyListeners();
}

Future<void> stopClickToTalkListening() async {
  await endClickToTalkListening();
}

Future<void> sendClickToTalkResponse() async {
  await sendClickToTalkRecording();
}
 
    void toggleUserCamera(components.MediaDeviceContext? ctx) {
    isUserCameEnabled = !isUserCameEnabled;
    isUserCameEnabled ? ctx?.enableCamera() : ctx?.disableCamera();
    notifyListeners();
  }

  void toggleScreenShare() {
    isScreenshareEnabled = !isScreenshareEnabled;
    notifyListeners();
  }

  void toggleAgentScreenMode() {
    agentScreenState = agentScreenState == AgentScreenState.visualizer
        ? AgentScreenState.transcription
        : AgentScreenState.visualizer;
    notifyListeners();
  }

  Future<void> connect() async {
    debugPrint('🔌 Connecting to LiveKit...');
    connectionState = ConnectionState.connecting;
    notifyListeners();

    try {
      final roomName = 'room-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';
      final participantName = 'user-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';

      debugPrint('🏠 Creating room: $roomName with participant: $participantName');

      final details = await tokenService.fetchConnectionDetails(
          roomName: roomName, participantName: participantName);

      debugPrint('🔗 Connecting to: ${details.serverUrl}');
      await room.connect(details.serverUrl, details.participantToken);
      debugPrint('✅ Connected to room: $roomName');

      connectionState = ConnectionState.connected;
      appScreenState = AppScreenState.agent;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1000));

      if (selectedAgent == AgentType.clickToTalk ||
          selectedAgent == AgentType.arabicClickToTalk) {
        await room.localParticipant!.setMicrophoneEnabled(false);
        debugPrint('🎤 Microphone disabled for click-to-talk mode');
      } else {
        await room.localParticipant!.setMicrophoneEnabled(true);
        debugPrint('🎤 Microphone enabled for attorney mode');
      }

      final lp = room.localParticipant;
      if (lp != null && selectedAgent != AgentType.attorney) {
        String agentCommand;
        switch (selectedAgent) {
          case AgentType.attorney:
            agentCommand = 'switch_to_attorney';
            break;
          case AgentType.clickToTalk:
            agentCommand = 'switch_to_click_to_talk';
            break;
          case AgentType.arabic:
            agentCommand = 'switch_to_arabic';
            break;
          case AgentType.arabicClickToTalk:
            agentCommand = 'switch_to_arabic_click_to_talk';
            break;
        }

        debugPrint('📤 Sending initial agent selection: $agentCommand');
        await lp.publishData(utf8.encode(agentCommand));
      } else {
        debugPrint('📤 Backend already starts with attorney agent - no switch needed');
      }

      debugPrint('🎯 Room setup complete with agent: ${selectedAgent.name}');

      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
        try {
          final liveKitService = LiveKitService();
          if (liveKitService.isRoomReady()) {
            await liveKitService.sendKeepAlive();
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      connectionState = ConnectionState.disconnected;
      // appScreenState = AppScreenState.welcome;
      notifyListeners();
    }
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting from LiveKit...');

    if (clickToTalkState != ClickToTalkState.idle) {
      cancelClickToTalk();
    }

    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    room.disconnect();
    connectionState = ConnectionState.disconnected;
    appScreenState = AppScreenState.welcome;
    agentScreenState = AgentScreenState.visualizer;

    notifyListeners();
  }

  void toggleContextualAI() {
    useContextualAI = !useContextualAI;
    notifyListeners();
  }

  Future<void> startClickToTalkListening() async {
    if (clickToTalkState != ClickToTalkState.idle) return;

    debugPrint('🎤 startClickToTalkListening called');

    try {
      final lp = room.localParticipant;
      if (lp == null) {
        debugPrint('❌ No local participant available');
        return;
      }

      debugPrint('🛑 Sent interrupt command before starting to speak');
      await lp.publishData(utf8.encode('interrupt_agent'));

      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('📤 Sent start_turn command to backend');
      await lp.publishData(utf8.encode('start_turn'));

      await lp.setMicrophoneEnabled(true);
      debugPrint('🎤 Microphone enabled for click-to-talk recording');

      clickToTalkState = ClickToTalkState.listening;
      _speakingDuration = Duration.zero;

      _clickToTalkTimer?.cancel();
      _clickToTalkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _speakingDuration = Duration(seconds: timer.tick);
        notifyListeners();
      });

      notifyListeners();
      debugPrint('✅ Click-to-talk listening started successfully');
    } catch (e) {
      debugPrint('❌ Error starting click-to-talk: $e');
      clickToTalkState = ClickToTalkState.idle;
      notifyListeners();
    }
  }

  Future<void> endClickToTalkListening() async {
    if (clickToTalkState != ClickToTalkState.listening) return;

    debugPrint('🛑 endClickToTalkListening called');

    try {
      _clickToTalkTimer?.cancel();
      _clickToTalkTimer = null;

      await room.localParticipant?.setMicrophoneEnabled(false);
      debugPrint('🎤 Microphone disabled');

      clickToTalkState = ClickToTalkState.readyToSend;
      notifyListeners();

      debugPrint('✅ Click-to-talk listening ended successfully');
    } catch (e) {
      debugPrint('❌ Error ending click-to-talk: $e');
      clickToTalkState = ClickToTalkState.idle;
      notifyListeners();
    }
  }

  Future<void> sendClickToTalkRecording() async {
    if (clickToTalkState != ClickToTalkState.readyToSend) return;

    debugPrint('📤 sendClickToTalkRecording called');

    try {
      clickToTalkState = ClickToTalkState.processing;
      notifyListeners();

      final lp = room.localParticipant;
      if (lp != null) {
        debugPrint('📤 Sent end_turn command to backend');
        await lp.publishData(utf8.encode('end_turn'));
      }

      await Future.delayed(const Duration(seconds: 2));

      clickToTalkState = ClickToTalkState.idle;
      _speakingDuration = Duration.zero;
      notifyListeners();

      debugPrint('✅ Click-to-talk recording sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending click-to-talk recording: $e');
      clickToTalkState = ClickToTalkState.idle;
      notifyListeners();
    }
  }

  void cancelClickToTalk() {
    debugPrint('❌ cancelClickToTalk called');

    _clickToTalkTimer?.cancel();
    _clickToTalkTimer = null;

    try {
      final lp = room.localParticipant;
      if (lp != null) {
        lp.publishData(utf8.encode('cancel_turn'));
        lp.setMicrophoneEnabled(false);
      }
    } catch (e) {
      debugPrint('❌ Error during click-to-talk cancel: $e');
    }

    clickToTalkState = ClickToTalkState.idle;
    _speakingDuration = Duration.zero;
    notifyListeners();

    debugPrint('✅ Click-to-talk cancelled successfully');
  }

  Future<void> sendMessage() async {
    if (messageCtrl.text.trim().isEmpty) return;

    final message = messageCtrl.text.trim();
    messageCtrl.clear();

    try {
      final lp = room.localParticipant;
      if (lp != null) {
        await lp.publishData(utf8.encode(message));
        debugPrint('📤 Message sent: $message');
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}