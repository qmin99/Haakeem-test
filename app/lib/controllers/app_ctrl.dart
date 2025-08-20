// app_ctrl.dart
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;

import '../services/livekit_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import '../services/token_service.dart';

/* ───────── ENUMS ───────── */
enum AppScreenState { welcome, agent }

enum AgentScreenState { visualizer, transcription }

enum ConnectionState { disconnected, connecting, connected }

enum AgentLanguage { en, ar }

enum AgentType { attorney, clickToTalk, arabic, arabicClickToTalk }

enum ClickToTalkState { idle, listening, readyToSend, processing }

/* ───────── CONTROLLER ───────── */
class AppCtrl extends ChangeNotifier {
  static const uuid = Uuid();

  /* --------------- UI & connection state --------------- */
  AppScreenState appScreenState = AppScreenState.welcome;
  ConnectionState connectionState = ConnectionState.disconnected;
  AgentScreenState agentScreenState = AgentScreenState.transcription;

  /* --------------- Agent selection and state --------------- */
  AgentLanguage selectedLanguage = AgentLanguage.en;
  AgentType selectedAgent = AgentType
      .attorney; // Start with attorney as the default - matches backend
  ClickToTalkState clickToTalkState = ClickToTalkState.idle;

  // Audio timing for click-to-talk mode
  Timer? _clickToTalkTimer;
  Duration _speakingDuration = Duration.zero;

  // Audio player for TTS playback
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Keep-alive timer
  Timer? _keepAliveTimer;

  /* --------------- misc UI --------------- */
  bool isUserCameEnabled = false;
  bool isScreenshareEnabled = false;

  final messageCtrl = TextEditingController();
  final messageFocusNode = FocusNode();
  bool isSendButtonEnabled = false;

  /* --------------- AI Assistant state --------------- */
  bool useContextualAI = true;

  /* --------------- LiveKit room --------------- */
  late final sdk.Room room =
      sdk.Room(roomOptions: const sdk.RoomOptions(enableVisualizer: true));
  late final roomContext = components.RoomContext(room: room);

  final tokenService = TokenService();

  /* ─────────────────────────── constructor */
  AppCtrl() {
    messageCtrl.addListener(() {
      final v = messageCtrl.text.isNotEmpty;
      if (v != isSendButtonEnabled) {
        isSendButtonEnabled = v;
        notifyListeners();
      }
    });

    // Listen for data messages from agent using the correct LiveKit client API
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

  /* ─────────────────────────── GETTERS */
  bool get isClickToTalkListening =>
      clickToTalkState == ClickToTalkState.listening;
  bool get isClickToTalkReady =>
      clickToTalkState == ClickToTalkState.readyToSend;
  bool get isClickToTalkProcessing =>
      clickToTalkState == ClickToTalkState.processing;
  Duration get speakingDuration => _speakingDuration;

  /* ─────────────────────────── ROOM EVENT HANDLER */
  void _onRoomEvent() {
    // Handle room events for agent responses and agent state sync
    // debugPrint('🏠 Room event received');
  }

  /// Setup LiveKit data handlers to receive agent messages
  void setupAgentMessageHandlers({
    Function(String)? onAgentMessage,
    Function(String)? onError,
  }) {
    // Import the LiveKit service
    final liveKitService = LiveKitService();
    liveKitService.setRoom(room);

    // Setup data listener for agent responses
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

  /* ─────────────────────────── AGENT SELECTION */

  // Track agent switching state to prevent glitches
  bool _isAgentSwitching = false;
  DateTime? _lastSwitchAttempt;

  bool get isAgentSwitching => _isAgentSwitching;

  // Get available agents for a language
  List<AgentType> agentsFor(AgentLanguage lang) {
    return lang == AgentLanguage.en
        ? [AgentType.attorney, AgentType.clickToTalk]
        : [AgentType.arabic, AgentType.arabicClickToTalk];
  }

  // Set language and auto-switch agent if needed
  Future<void> setLanguage(AgentLanguage lang) async {
    if (selectedLanguage == lang) return;

    selectedLanguage = lang;
    final options = agentsFor(lang);

    if (!options.contains(selectedAgent)) {
      // Default to continuous for that language
      final defaultAgent =
          lang == AgentLanguage.ar ? AgentType.arabic : AgentType.attorney;
      await selectAgent(defaultAgent);
    } else {
      notifyListeners();
    }
  }

  Future<void> selectAgent(AgentType agentType) async {
    // Prevent multiple simultaneous switches
    if (_isAgentSwitching) {
      debugPrint('⚠️ Agent switch already in progress, ignoring request');
      return;
    }

    // Prevent rapid successive switches (debounce mechanism)
    final now = DateTime.now();
    if (_lastSwitchAttempt != null &&
        now.difference(_lastSwitchAttempt!).inMilliseconds < 2000) {
      debugPrint('⚠️ Agent switch too soon after last attempt, debouncing');
      return;
    }
    _lastSwitchAttempt = now;

    if (selectedAgent == agentType) {
      debugPrint('ℹ️ Agent already selected: ${agentType.name}');
      return;
    }

    final lp = room.localParticipant;
    if (lp == null) {
      debugPrint('⚠️ No local participant yet for agent selection');
      return;
    }

    try {
      // Set switching state and notify UI
      _isAgentSwitching = true;
      notifyListeners();
      debugPrint('🔄 Starting agent switch to: ${agentType.name}');

      // Phase 1: Comprehensive cleanup of current agent state
      await _cleanupCurrentAgentState();

      // Phase 2: Send agent switch command
      String agentCommand;
      switch (agentType) {
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

      await lp.publishData(utf8.encode(agentCommand));
      debugPrint('📤 Sent agent switch command: $agentCommand');

      // Phase 3: Wait for backend processing and verify connection
      await _waitForAgentSwitch(agentType);

      // Phase 4: Update frontend state and configure agent
      await _configureNewAgent(agentType);

      debugPrint('✅ Successfully switched to agent: ${agentType.name}');
    } catch (e) {
      debugPrint('❌ Error switching agent: $e');
      await _recoverFromSwitchError(agentType);
    } finally {
      // Ensure switching flag is always reset
      _isAgentSwitching = false;
      notifyListeners();
    }
  }

  Future<void> _cleanupCurrentAgentState() async {
    debugPrint('🧹 Phase 1: Cleaning up current agent state...');

    final lp = room.localParticipant;
    if (lp != null) {
      // Send aggressive interrupt commands
      await lp.publishData(utf8.encode('interrupt_agent'));
      debugPrint('🛑 Sent interrupt command #1');

      await Future.delayed(const Duration(milliseconds: 150));

      await lp.publishData(utf8.encode('interrupt_agent'));
      debugPrint('🛑 Sent interrupt command #2 - ensuring complete stop');

      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Reset click-to-talk state when switching agents
    if (clickToTalkState != ClickToTalkState.idle) {
      await cancelClickToTalk();
      debugPrint('🛑 Reset click-to-talk state');
    }

    debugPrint('✅ Current agent state cleanup completed');
  }

  Future<void> _waitForAgentSwitch(AgentType agentType) async {
    debugPrint(
        '⏳ Phase 3: Waiting for backend agent switch to ${agentType.name}...');

    // Implement timeout mechanism for agent switching
    const timeout = Duration(seconds: 8);
    final completer = Completer<void>();
    Timer? timeoutTimer;

    // Start timeout timer
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
            'Agent switch timeout after ${timeout.inSeconds} seconds');
      }
    });

    try {
      // Wait for backend processing with health checks
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('⏳ Initial wait completed, checking agent status...');

      // Verify connection is still healthy
      if (room.connectionState != sdk.ConnectionState.connected) {
        throw Exception('Connection lost during agent switch');
      }

      // Additional wait to ensure backend has fully processed the switch
      // Give more time for attorney->click-to-talk since it requires more cleanup
      final extraWait = agentType == AgentType.clickToTalk
          ? const Duration(milliseconds: 800)
          : const Duration(milliseconds: 500);

      await Future.delayed(extraWait);
      debugPrint(
          '✅ Backend agent switch processing completed for ${agentType.name}');

      // Mark as completed if not already
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    } finally {
      timeoutTimer.cancel();
    }

    // Wait for either completion or timeout
    await completer.future;
  }

  Future<void> _configureNewAgent(AgentType agentType) async {
    debugPrint('⚙️ Phase 4: Configuring new agent...');

    final lp = room.localParticipant;
    if (lp == null) return;

    // Update the selected agent
    selectedAgent = agentType;
    debugPrint('✅ Updated selected agent to: ${agentType.name}');

    // Configure microphone based on agent type
    // Continuous for attorney and arabic; disabled for click-to-talk variants
    if (agentType == AgentType.clickToTalk ||
        agentType == AgentType.arabicClickToTalk) {
      await lp.setMicrophoneEnabled(false);
      debugPrint('🎤 Microphone disabled for click-to-talk agent');
    } else {
      await lp.setMicrophoneEnabled(true);
      debugPrint('🎤 Microphone enabled for continuous agent');
    }

    debugPrint('✅ New agent configuration completed');
  }

  Future<void> _recoverFromSwitchError(AgentType targetAgentType) async {
    debugPrint('🔄 Attempting recovery from agent switch error...');

    try {
      // Reset to previous agent if possible, or default to attorney
      final fallbackAgent = selectedAgent;
      debugPrint(
          '🔄 Attempting to restore previous agent: ${fallbackAgent.name}');

      final lp = room.localParticipant;
      if (lp != null) {
        String recoveryCommand;
        switch (fallbackAgent) {
          case AgentType.attorney:
            recoveryCommand = 'switch_to_attorney';
            break;
          case AgentType.clickToTalk:
            recoveryCommand = 'switch_to_click_to_talk';
            break;
          case AgentType.arabic:
            recoveryCommand = 'switch_to_arabic';
            break;
          case AgentType.arabicClickToTalk:
            recoveryCommand = 'switch_to_arabic_click_to_talk';
            break;
        }

        await lp.publishData(utf8.encode(recoveryCommand));
        debugPrint('📤 Sent recovery command: $recoveryCommand');

        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('✅ Recovery attempt completed');
      }
    } catch (recoveryError) {
      debugPrint('❌ Recovery also failed: $recoveryError');
      // Last resort: disconnect and require reconnection
      debugPrint(
          '🔌 Initiating disconnect due to unrecoverable agent switch error');
    }
  }

  /* ─────────────────────────── CLICK-TO-TALK FUNCTIONALITY */
  Future<void> startClickToTalkListening() async {
    debugPrint('🎤 startClickToTalkListening called');
    debugPrint('Current agent: ${selectedAgent.name}');
    debugPrint('Current state: $clickToTalkState');

    if (selectedAgent != AgentType.clickToTalk &&
        selectedAgent != AgentType.arabicClickToTalk) {
      debugPrint('⚠️ Not in click-to-talk agent mode');
      return;
    }

    if (clickToTalkState != ClickToTalkState.idle) {
      debugPrint('⚠️ Click-to-talk already active: $clickToTalkState');
      return;
    }

    final lp = room.localParticipant;
    if (lp == null) {
      debugPrint('⚠️ No local participant for start recording');
      return;
    }

    try {
      clickToTalkState = ClickToTalkState.listening;
      _speakingDuration = Duration.zero;

      // CRITICAL: Send interrupt command to stop any active agent speech before starting to talk
      await lp.publishData(utf8.encode('interrupt_agent'));
      debugPrint('🛑 Sent interrupt command before starting to speak');

      // Small delay to ensure interrupt is processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Enable microphone and send start_turn to begin backend audio capture
      await lp.setMicrophoneEnabled(true);
      debugPrint('🎤 Microphone enabled');

      await lp.publishData(utf8.encode('start_turn'));
      debugPrint('📤 Sent start_turn command to backend');

      // Start duration timer
      _clickToTalkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _speakingDuration = Duration(seconds: timer.tick);
        notifyListeners();
      });

      notifyListeners();
      debugPrint('✅ Click-to-talk listening started - user can speak now');
    } catch (e) {
      debugPrint('❌ Error starting click-to-talk listening: $e');
      clickToTalkState = ClickToTalkState.idle;
      notifyListeners();
    }
  }

  Future<void> stopClickToTalkListening() async {
    if (clickToTalkState != ClickToTalkState.listening) {
      debugPrint('⚠️ Click-to-talk not currently listening');
      return;
    }

    final lp = room.localParticipant;
    if (lp == null) {
      debugPrint('⚠️ No local participant for stopping');
      return;
    }

    try {
      _clickToTalkTimer?.cancel();

      // Disable microphone since user finished speaking
      await lp.setMicrophoneEnabled(false);
      debugPrint('🎤 Microphone disabled');

      clickToTalkState = ClickToTalkState.readyToSend;

      // Just stop the local recording timer - don't send to backend yet
      // The audio is still being captured until the user clicks "Send"

      debugPrint('✅ Click-to-talk listening stopped - ready to send');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error stopping click-to-talk listening: $e');
    }
  }

  Future<void> sendClickToTalkResponse() async {
    debugPrint('📤 sendClickToTalkResponse called');
    debugPrint('Current agent: ${selectedAgent.name}');
    debugPrint('Current state: $clickToTalkState');

    if (clickToTalkState != ClickToTalkState.readyToSend) {
      debugPrint(
          '⚠️ Click-to-talk not ready to send. Current state: $clickToTalkState');
      return;
    }

    final lp = room.localParticipant;
    if (lp == null) {
      debugPrint('⚠️ No local participant for sending');
      return;
    }

    try {
      clickToTalkState = ClickToTalkState.processing;
      notifyListeners();
      debugPrint('🔄 Processing state set, sending to HAAKEEM...');

      // Send end_turn to stop recording and send to HAAKEEM for processing
      await lp.publishData(utf8.encode('end_turn'));
      debugPrint('📤 Sent end_turn command to HAAKEEM backend');
      debugPrint('✅ Audio should now be processing by HAAKEEM...');

      // Reset state after a delay to allow for agent response
      Future.delayed(const Duration(seconds: 5), () {
        if (clickToTalkState == ClickToTalkState.processing) {
          debugPrint('⏰ Timeout reached, resetting click-to-talk state');
          clickToTalkState = ClickToTalkState.idle;
          _speakingDuration = Duration.zero;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('❌ Error sending click-to-talk response: $e');
      clickToTalkState = ClickToTalkState.idle;
      _speakingDuration = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> cancelClickToTalk() async {
    if (clickToTalkState == ClickToTalkState.idle) return;

    final lp = room.localParticipant;
    if (lp != null) {
      try {
        // Send cancel_turn command to clear the audio buffer
        await lp.publishData(utf8.encode('cancel_turn'));
        debugPrint('✅ Sent cancel_turn command to backend');

        await lp.setMicrophoneEnabled(false);
      } catch (e) {
        debugPrint('❌ Error canceling click-to-talk: $e');
      }
    }

    _clickToTalkTimer?.cancel();
    clickToTalkState = ClickToTalkState.idle;
    _speakingDuration = Duration.zero;
    notifyListeners();
    debugPrint('✅ Click-to-talk canceled');
  }

  /* ─────────────────────────── CHAT MESSAGE */
  Future<void> sendMessage() async {
    isSendButtonEnabled = false;
    final text = messageCtrl.text;
    messageCtrl.clear();
    notifyListeners();

    final lp = room.localParticipant;
    if (lp == null) return;

    final nowUtc = DateTime.now().toUtc();
    // Normalize brand name to HAAKEEM for common variants
    final normalizedText = text.replaceAll(
      RegExp(r'\b(ha+k[iy]e?m|hakim|hakeem)\b', caseSensitive: false),
      'HAAKEEM',
    );

    final seg = sdk.TranscriptionSegment(
      id: uuid.v4(),
      text: normalizedText,
      firstReceivedTime: nowUtc,
      lastReceivedTime: nowUtc,
      isFinal: true,
      language: 'en',
    );
    roomContext
        .insertTranscription(components.TranscriptionForParticipant(seg, lp));

    // Send message using publishData
    await lp.publishData(utf8.encode('chat:$normalizedText'));
  }

  /* ─────────────────────────── UI helpers */
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

  /* ─────────────────────────── CONNECT / DISCONNECT */
  Future<void> connect() async {
    debugPrint('🔌 Connecting to LiveKit...');
    connectionState = ConnectionState.connecting;
    notifyListeners();

    try {
      final roomName =
          'room-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';
      final participantName =
          'user-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';

      debugPrint(
          '🏠 Creating room: $roomName with participant: $participantName');

      final details = await tokenService.fetchConnectionDetails(
          roomName: roomName, participantName: participantName);

      debugPrint('🔗 Connecting to: ${details.serverUrl}');
      await room.connect(details.serverUrl, details.participantToken);
      debugPrint('✅ Connected to room: $roomName');

      connectionState = ConnectionState.connected;
      appScreenState = AppScreenState.agent;
      notifyListeners();

      // Wait a moment for the room to fully initialize
      await Future.delayed(const Duration(milliseconds: 1000));

      // Ensure we start with the selected default agent and proper mic settings
      if (selectedAgent == AgentType.clickToTalk ||
          selectedAgent == AgentType.arabicClickToTalk) {
        await room.localParticipant!.setMicrophoneEnabled(false);
        debugPrint('🎤 Microphone disabled for click-to-talk mode');
      } else {
        await room.localParticipant!.setMicrophoneEnabled(true);
        debugPrint('🎤 Microphone enabled for attorney mode');
      }

      // Send initial agent selection to backend ONLY if not already attorney (backend default)
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
        debugPrint(
            '📤 Backend already starts with attorney agent - no switch needed');
      }

      debugPrint('🎯 Room setup complete with agent: ${selectedAgent.name}');

      // Start periodic ping to keep LiveKit agent session warm
      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
        try {
          final liveKitService = LiveKitService();
          if (liveKitService.isRoomReady()) {
            await liveKitService.sendKeepAlive();
          }
        } catch (_) {
          // swallow; timer continues
        }
      });
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      connectionState = ConnectionState.disconnected;
      appScreenState = AppScreenState.welcome;
      notifyListeners();
    }
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting from LiveKit...');

    // Cancel any ongoing click-to-talk
    if (clickToTalkState != ClickToTalkState.idle) {
      cancelClickToTalk();
    }

    // Cancel keep-alive timer
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    room.disconnect();
    connectionState = ConnectionState.disconnected;
    appScreenState = AppScreenState.welcome;
    agentScreenState = AgentScreenState.visualizer;

    notifyListeners();
  }

  /* ─────────────────────────── AI ASSISTANT MANAGEMENT */
  void toggleContextualAI() {
    useContextualAI = !useContextualAI;
    notifyListeners();
  }

  /* ─────────────────────────── UTILITY */
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
