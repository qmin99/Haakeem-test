import 'dart:async';
import 'package:flutter/foundation.dart';

import '../constants/enums.dart';
import '../services/voice_service.dart';
import '../controllers/app_ctrl.dart' as app_ctrl;

/// Provider for managing voice state and operations
class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();

  // Voice state
  bool _isVoiceMode = false;
  bool _isLiveVoiceActive = false;
  bool _showWaveform = false;
  VoiceState _voiceState = VoiceState.idle;
  String _liveTranscription = '';
  List<double> _waveformData = [];

  // Voice settings
  bool _hasMicPermission = false;

  // Callbacks
  Function(String)? _onFinalTranscription;
  Function(String)? _onError;

  // Getters
  bool get isVoiceMode => _isVoiceMode;
  bool get isLiveVoiceActive => _isLiveVoiceActive;
  bool get showWaveform => _showWaveform;
  VoiceState get voiceState => _voiceState;
  String get liveTranscription => _liveTranscription;
  List<double> get waveformData => List.unmodifiable(_waveformData);
  bool get hasMicPermission => _hasMicPermission;
  bool get isListening => _voiceState == VoiceState.listening;
  bool get isRecording => isListening;

  /// Initialize the voice provider
  Future<bool> initialize({
    Function(String)? onFinalTranscription,
    Function(String)? onError,
  }) async {
    _onFinalTranscription = onFinalTranscription;
    _onError = onError;

    final success = await _voiceService.initialize(
      onStateChanged: _onStateChanged,
      onTranscriptionChanged: _onTranscriptionChanged,
      onFinalTranscription: _onFinalTranscriptionReceived,
      onError: _onErrorReceived,
      onWaveformUpdate: _onWaveformUpdate,
    );

    _hasMicPermission = success;
    notifyListeners();
    
    return success;
  }

  /// Toggle voice mode on/off
  Future<void> toggleVoiceMode({
    required app_ctrl.AppCtrl appCtrl,
    String? newChatId,
    VoidCallback? onVoiceModeActivated,
    VoidCallback? onVoiceModeDeactivated,
  }) async {
    if (!_isVoiceMode) {
      await _activateVoiceMode(appCtrl, newChatId, onVoiceModeActivated);
    } else {
      await _deactivateVoiceMode(appCtrl, onVoiceModeDeactivated);
    }
  }

  /// Activate voice mode
  Future<void> _activateVoiceMode(
    app_ctrl.AppCtrl appCtrl,
    String? newChatId,
    VoidCallback? onVoiceModeActivated,
  ) async {
    // Clean up any existing voice sessions first
    await cleanup();

    // Connect to LiveKit if needed
    if (appCtrl.connectionState == app_ctrl.ConnectionState.disconnected) {
      await appCtrl.connect();
    }

    _isVoiceMode = true;
    
    // Start live voice for appropriate agents
    if (appCtrl.selectedAgent == app_ctrl.AgentType.attorney ||
        appCtrl.selectedAgent == app_ctrl.AgentType.arabic) {
      startLiveVoice();
    }

    onVoiceModeActivated?.call();
    notifyListeners();
  }

  /// Deactivate voice mode
  Future<void> _deactivateVoiceMode(
    app_ctrl.AppCtrl appCtrl,
    VoidCallback? onVoiceModeDeactivated,
  ) async {
    await cleanup();
    
    _isVoiceMode = false;
    _isLiveVoiceActive = false;
    _showWaveform = false;
    
    appCtrl.disconnect();
    
    onVoiceModeDeactivated?.call();
    notifyListeners();
  }

  /// Start listening for speech input
  Future<bool> startListening({app_ctrl.AgentType? agentType}) async {
    if (!_hasMicPermission) {
      _onError?.call('Microphone permission required');
      return false;
    }

    return await _voiceService.startListening(
      agentType: agentType,
      isVoiceMode: _isVoiceMode,
    );
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  /// Toggle listening state
  Future<bool> toggleListening({app_ctrl.AgentType? agentType}) async {
    return await _voiceService.toggleListening(
      agentType: agentType,
      isVoiceMode: _isVoiceMode,
    );
  }

  /// Start live voice mode
  void startLiveVoice() {
    _voiceService.startLiveVoice();
    _isLiveVoiceActive = true;
    _showWaveform = true;
    notifyListeners();
  }

  /// Stop live voice mode
  void stopLiveVoice() {
    _voiceService.stopLiveVoice();
    _isLiveVoiceActive = false;
    _showWaveform = false;
    notifyListeners();
  }

  /// Clean up all voice resources
  Future<void> cleanup() async {
    await _voiceService.cleanup();
    _liveTranscription = '';
    _waveformData.clear();
    notifyListeners();
  }

  /// Perform safe agent switch with voice cleanup
  Future<void> performSafeAgentSwitch(
    app_ctrl.AgentType targetAgent,
    app_ctrl.AppCtrl appCtrl,
  ) async {
    debugPrint('🔄 Starting safe agent switch from ${appCtrl.selectedAgent.name} to ${targetAgent.name}');

    try {
      // Phase 1: Comprehensive voice cleanup if needed
      if (_isVoiceMode) {
        debugPrint('🧹 Phase 1: Comprehensive voice mode cleanup before agent switch');
        await cleanup();
        
        _isVoiceMode = false;
        _isLiveVoiceActive = false;
        _showWaveform = false;
        stopLiveVoice();
        
        debugPrint('✅ Voice mode safely deactivated for agent switch');
      }

      // Phase 2: Additional cleanup for any remaining voice resources
      await cleanup();
      debugPrint('✅ Additional voice resource cleanup completed');

      // Phase 3: Wait for all cleanup to settle
      await Future.delayed(const Duration(milliseconds: 200));

      // Phase 4: Perform the agent switch
      debugPrint('🔄 Phase 4: Executing agent switch');
      await appCtrl.selectAgent(targetAgent);

      // Phase 5: Re-enable voice mode if it was previously active and switching was successful
      if (!_isVoiceMode && appCtrl.connectionState == app_ctrl.ConnectionState.connected) {
        debugPrint('🔄 Phase 5: Re-activating voice mode with new agent');

        // Brief delay to ensure agent switch has completed
        await Future.delayed(const Duration(milliseconds: 300));

        _isVoiceMode = true;
        if (appCtrl.selectedAgent == app_ctrl.AgentType.attorney ||
            appCtrl.selectedAgent == app_ctrl.AgentType.arabic) {
          startLiveVoice();
        }

        debugPrint('✅ Voice mode re-activated with new agent');
      }

      debugPrint('✅ Safe agent switch completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error during safe agent switch: $e');
      
      // Recovery: Ensure we're in a clean state
      await cleanup();
      _isVoiceMode = false;
      _isLiveVoiceActive = false;
      _showWaveform = false;
      
      _onError?.call('Agent switch failed. Please try again.');
      notifyListeners();
    }
  }

  /// Handle voice state changes from service
  void _onStateChanged(VoiceState newState) {
    _voiceState = newState;
    
    if (newState == VoiceState.listening) {
      _showWaveform = true;
    } else if (newState == VoiceState.idle) {
      if (!_isLiveVoiceActive) {
        _showWaveform = false;
      }
    }
    
    notifyListeners();
  }

  /// Handle transcription changes from service
  void _onTranscriptionChanged(String transcription) {
    _liveTranscription = transcription;
    notifyListeners();
  }

  /// Handle final transcription from service
  void _onFinalTranscriptionReceived(String transcription) {
    debugPrint('🎤 Final transcription received: "$transcription"');
    if (transcription.trim().isNotEmpty) {
      debugPrint('🎤 Calling onFinalTranscription callback');
      _onFinalTranscription?.call(transcription);
    } else {
      debugPrint('🎤 Skipping empty transcription');
    }
  }

  /// Handle errors from service
  void _onErrorReceived(String error) {
    _onError?.call(error);
  }

  /// Handle waveform updates from service
  void _onWaveformUpdate(List<double> data) {
    _waveformData = data;
    notifyListeners();
  }

  /// Request microphone permission
  Future<void> requestMicrophonePermission() async {
    final success = await initialize();
    if (success) {
      _onError?.call('Microphone permission granted');
    } else {
      _onError?.call('Microphone permission denied');
    }
  }

  @override
  void dispose() {
    cleanup();
    _voiceService.dispose();
    super.dispose();
  }
}
