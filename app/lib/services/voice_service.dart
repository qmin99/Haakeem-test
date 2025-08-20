import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../constants/enums.dart';
import '../constants/app_constants.dart';
import '../controllers/app_ctrl.dart' as app_ctrl;

/// Service class to handle all voice-related functionality
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Speech to text instance
  late stt.SpeechToText _speech;
  
  // Voice state management
  VoiceState _currentState = VoiceState.idle;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  String _liveTranscription = '';
  
  // Timers for voice operations
  Timer? _speechTimer;
  Timer? _waveTimer;
  Timer? _liveVoiceTimer;
  Timer? _transcriptionTimer;
  
  // Waveform data
  List<double> _waveformData = List.generate(VoiceConstants.waveformDataPoints, (index) => 0.0);
  
  // Callbacks
  Function(VoiceState)? _onStateChanged;
  Function(String)? _onTranscriptionChanged;
  Function(String)? _onFinalTranscription;
  Function(String)? _onError;
  Function(List<double>)? _onWaveformUpdate;

  // Getters
  VoiceState get currentState => _currentState;
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get liveTranscription => _liveTranscription;
  List<double> get waveformData => List.unmodifiable(_waveformData);

  /// Initialize the speech recognition service
  Future<bool> initialize({
    Function(VoiceState)? onStateChanged,
    Function(String)? onTranscriptionChanged,
    Function(String)? onFinalTranscription,
    Function(String)? onError,
    Function(List<double>)? onWaveformUpdate,
  }) async {
    _onStateChanged = onStateChanged;
    _onTranscriptionChanged = onTranscriptionChanged;
    _onFinalTranscription = onFinalTranscription;
    _onError = onError;
    _onWaveformUpdate = onWaveformUpdate;

    _speech = stt.SpeechToText();
    
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      
      if (_speechEnabled) {
        _updateState(VoiceState.idle);
        return true;
      } else {
        _updateState(VoiceState.error);
        _onError?.call('Failed to initialize speech recognition');
        return false;
      }
    } catch (e) {
      _updateState(VoiceState.error);
      _onError?.call('Speech initialization error: $e');
      return false;
    }
  }

  /// Start listening for speech input
  Future<bool> startListening({
    app_ctrl.AgentType? agentType,
    bool isVoiceMode = false,
  }) async {
    if (!_speechEnabled) {
      _onError?.call('Speech recognition not available');
      return false;
    }

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _lastWords = '';
    _liveTranscription = '';
    _updateState(VoiceState.listening);

    try {
      final localeId = _getLocaleForAgent(agentType);
      
      bool started = await _speech.listen(
        onResult: (result) => _onSpeechResult(result, isVoiceMode),
        listenFor: VoiceConstants.listenDuration,
        pauseFor: VoiceConstants.pauseDuration,
        partialResults: true,
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
      );

      if (started) {
        _isListening = true;
        _startWaveformGeneration();
        _startSpeechTimer();
        return true;
      } else {
        _updateState(VoiceState.error);
        _onError?.call('Failed to start listening');
        return false;
      }
    } catch (e) {
      _updateState(VoiceState.error);
      _onError?.call('Start listening error: $e');
      return false;
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    _speechTimer?.cancel();
    _waveTimer?.cancel();

    if (_speech.isListening) {
      await _speech.stop();
    }

    _isListening = false;
    _updateState(VoiceState.idle);

    if (_lastWords.isNotEmpty) {
      _onFinalTranscription?.call(_lastWords);
    }
  }

  /// Toggle listening state
  Future<bool> toggleListening({
    app_ctrl.AgentType? agentType,
    bool isVoiceMode = false,
  }) async {
    if (_isListening) {
      await stopListening();
      return false;
    } else {
      return await startListening(agentType: agentType, isVoiceMode: isVoiceMode);
    }
  }

  /// Start live voice mode with continuous waveform generation
  void startLiveVoice() {
    _updateState(VoiceState.speaking);
    _startLiveVoiceWaveform();
  }

  /// Stop live voice mode
  void stopLiveVoice() {
    _liveVoiceTimer?.cancel();
    _updateState(VoiceState.idle);
  }

  /// Clean up all voice-related resources
  Future<void> cleanup() async {
    _speechTimer?.cancel();
    _waveTimer?.cancel();
    _liveVoiceTimer?.cancel();
    _transcriptionTimer?.cancel();

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        debugPrint('Error stopping speech during cleanup: $e');
      }
    }

    _isListening = false;
    _lastWords = '';
    _liveTranscription = '';
    _updateState(VoiceState.idle);
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    _isListening = status == 'listening';
    
    if (status == 'done' || status == 'notListening') {
      _speechTimer?.cancel();
      if (_lastWords.isNotEmpty) {
        _onFinalTranscription?.call(_lastWords);
      }
      _updateState(VoiceState.idle);
    } else if (status == 'listening') {
      _updateState(VoiceState.listening);
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    _speechTimer?.cancel();
    _isListening = false;
    _updateState(VoiceState.error);
    _onError?.call('Speech recognition error: $error');
  }

  /// Handle speech recognition results
  void _onSpeechResult(dynamic result, bool isVoiceMode) {
    String text = result.recognizedWords;
    
    // Normalize brand name variants
    final brandRegex = RegExp(r'\b(ha+k[iy]e?m|hakim|hakeem)\b', caseSensitive: false);
    text = text.replaceAll(brandRegex, 'HAAKEEM');
    
    _lastWords = text;
    _liveTranscription = text;
    
    _onTranscriptionChanged?.call(text);
  }

  /// Start waveform generation for recording visualization
  void _startWaveformGeneration() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(VoiceConstants.waveformUpdateInterval, (timer) {
      if (_isListening) {
        _generateWaveformData();
        _onWaveformUpdate?.call(_waveformData);
      }
    });
  }

  /// Start live voice waveform generation
  void _startLiveVoiceWaveform() {
    _liveVoiceTimer?.cancel();
    _liveVoiceTimer = Timer.periodic(VoiceConstants.liveVoiceUpdateInterval, (timer) {
      if (_currentState == VoiceState.speaking) {
        _generateWaveformData();
        _onWaveformUpdate?.call(_waveformData);
      }
    });
  }

  /// Start speech timeout timer
  void _startSpeechTimer() {
    _speechTimer?.cancel();
    _speechTimer = Timer(VoiceConstants.speechTimeout, () {
      if (_isListening) stopListening();
    });
  }

  /// Generate random waveform data for visualization
  void _generateWaveformData() {
    for (int i = 0; i < _waveformData.length; i++) {
      _waveformData[i] = math.Random().nextDouble();
    }
  }

  /// Get locale string for agent type
  String _getLocaleForAgent(app_ctrl.AgentType? agentType) {
    if (agentType == app_ctrl.AgentType.arabic || 
        agentType == app_ctrl.AgentType.arabicClickToTalk) {
      return VoiceConstants.localeArabic;
    }
    return VoiceConstants.localeEnglish;
  }

  /// Update current state and notify listeners
  void _updateState(VoiceState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _onStateChanged?.call(newState);
    }
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    cleanup();
    _onStateChanged = null;
    _onTranscriptionChanged = null;
    _onFinalTranscription = null;
    _onError = null;
    _onWaveformUpdate = null;
  }
}
