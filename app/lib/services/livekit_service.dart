import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;

import '../constants/app_constants.dart';
import '../models/file_models.dart';

/// Service class to handle LiveKit agent communication
class LiveKitService {
  static final LiveKitService _instance = LiveKitService._internal();
  factory LiveKitService() => _instance;
  LiveKitService._internal();

  sdk.Room? _room;
  sdk.EventsListener? _eventsListener;
  
  // Getters
  sdk.Room? get room => _room;
  bool get isConnected => _room != null;

  /// Set the LiveKit room instance
  void setRoom(sdk.Room? room) {
    // Cleanup existing listener
    _eventsListener?.dispose();
    _eventsListener = null;
    
    _room = room;
    debugPrint('📡 LiveKit room set: ${room != null ? 'connected' : 'disconnected'}');
  }

  /// Send file to LiveKit agent using byte streams
  Future<void> sendFileToAgent(
    Uint8List fileBytes,
    String fileName,
    String fileExtension,
  ) async {
    if (_room == null) {
      throw Exception('No LiveKit room available');
    }

    try {
      debugPrint('📤 STARTING FILE UPLOAD - Name: $fileName, Size: ${fileBytes.length} bytes');
      
      String mimeType = _getMimeTypeFromExtension(fileExtension);
      debugPrint('📤 MIME Type: $mimeType');

      final localParticipant = _room!.localParticipant;
      debugPrint('📤 Local participant: ${localParticipant?.identity ?? "null"}');
      
      if (localParticipant == null) {
        throw Exception('No local participant available');
      }

      // Method 1: Use streamBytes (recommended for binary data)
      try {
        final writer = await localParticipant.streamBytes(
          sdk.StreamBytesOptions(
            topic: 'files',
            mimeType: mimeType,
            name: fileName,
          ),
        );

        debugPrint('📤 Opened byte stream: ${writer.info.id}');

        // Write the file data in chunks for better performance
        const chunkSize = FileTypeConstants.chunkSize;
        for (int i = 0; i < fileBytes.length; i += chunkSize) {
          int end = (i + chunkSize < fileBytes.length) ? i + chunkSize : fileBytes.length;
          final chunk = fileBytes.sublist(i, end);
          await writer.write(chunk);
        }

        // IMPORTANT: Must close the stream when done
        await writer.close();

        debugPrint('📤 File sent via streamBytes: $fileName (${fileBytes.length} bytes, $mimeType)');
      } catch (streamError) {
        debugPrint('⚠️ streamBytes failed: $streamError');

        // Method 2: Fallback using publishData with base64 encoding
        final fileData = {
          'type': 'file_upload',
          'fileName': fileName,
          'mimeType': mimeType,
          'data': base64Encode(fileBytes),
          'size': fileBytes.length,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await localParticipant.publishData(
          utf8.encode(jsonEncode(fileData)),
          reliable: true,
          topic: 'files',
        );

        debugPrint('📤 File sent via publishData fallback: $fileName');
      }
    } catch (e) {
      debugPrint('❌ Error sending file to agent: $e');
      rethrow;
    }
  }

  /// Send text message to LiveKit agent
  Future<void> sendTextToAgent(String message) async {
    if (_room == null) {
      throw Exception('No LiveKit room available');
    }

    try {
      final localParticipant = _room!.localParticipant;
      if (localParticipant == null) {
        throw Exception('No local participant available');
      }

      final messageData = {
        'type': 'text_request',
        'message': message,  // legacy
        'text': message,     // common alternative
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await localParticipant.publishData(
        utf8.encode(jsonEncode(messageData)),
        reliable: true,
        topic: 'chat',
      );

      debugPrint('📤 Text message sent to agent: $message');
    } catch (e) {
      debugPrint('❌ Error sending text to agent: $e');
      rethrow;
    }
  }

  /// Send voice data to LiveKit agent
  Future<void> sendVoiceToAgent(Uint8List audioData) async {
    if (_room == null) {
      throw Exception('No LiveKit room available');
    }

    try {
      final localParticipant = _room!.localParticipant;
      if (localParticipant == null) {
        throw Exception('No local participant available');
      }

      final writer = await localParticipant.streamBytes(
        sdk.StreamBytesOptions(
          topic: 'voice',
          mimeType: 'audio/wav',
          name: 'voice_input_${DateTime.now().millisecondsSinceEpoch}.wav',
        ),
      );

      await writer.write(audioData);
      await writer.close();

      debugPrint('📤 Voice data sent to agent: ${audioData.length} bytes');
    } catch (e) {
      debugPrint('❌ Error sending voice to agent: $e');
      rethrow;
    }
  }

  /// Get MIME type from file extension
  String _getMimeTypeFromExtension(String extension) {
    return FileTypeConstants.mimeTypes[extension.toLowerCase()] ?? 
           'application/octet-stream';
  }

  /// Listen for data from LiveKit agent
  void setupDataListener({
    Function(String)? onTextReceived,
    Function(String)? onError,
  }) {
    try {
      if (_room == null) {
        debugPrint('❌ Room is null, cannot set up data listener');
        return;
      }

      // Dispose existing listener if any
      _eventsListener?.dispose();
      
      // Create new events listener using correct LiveKit v2.5.0 API
      _eventsListener = _room!.createListener();
      
      // Register handler for data received events
      _eventsListener!.on<sdk.DataReceivedEvent>((event) {
        try {
          final rawBytes = event.data;
          final dataString = String.fromCharCodes(rawBytes);
          final topic = event.topic ?? '';
          debugPrint('📥 Data [topic=$topic]: $dataString');

          if (dataString.trim().isEmpty) {
            debugPrint('⚠️ Received empty data, skipping');
            return;
          }

          // --- Map internal/system signals into human-readable chat lines ---
          if (dataString.startsWith('status_')) {
            final human = dataString.replaceFirst('status_', '').replaceAll('_', ' ').trim();
            onTextReceived?.call('🔔 Status: $human');
            return;
          }
          if (dataString.startsWith('active_agent:')) {
            final agent = dataString.split(':').skip(1).join(':').trim();
            onTextReceived?.call(agent.isEmpty ? '🤖 Active agent changed' : '🤖 Active agent: $agent');
            return;
          }
          if (dataString.startsWith('session_')) {
            onTextReceived?.call('🆔 ${dataString.replaceAll('_', ' ').trim()}');
            return;
          }
          if (dataString.startsWith('debug_')) {
            debugPrint('🔧 $dataString');
            return;
          }

          // --- Try JSON first; if not JSON, surface as plain text ---
          Map<String, dynamic>? data;
          try {
            data = jsonDecode(dataString) as Map<String, dynamic>;
          } catch (_) {
            // Non-JSON → treat as plain text message from agent
            onTextReceived?.call(dataString.trim());
            return;
          }

          // Best-effort extraction of the actual text from many common shapes
          String? msg;
          String type = (data['type'] ?? data['event'] ?? '').toString();

          // common locations
          if (data['message'] is String) msg = data['message'] as String;
          else if (data['text'] is String) msg = data['text'] as String;
          else if (data['content'] is String) msg = data['content'] as String;
          else if (data['transcript'] is String) msg = data['transcript'] as String;
          // nested payloads seen in some SDKs
          else if (data['payload'] is Map && (data['payload']['text'] is String)) {
            msg = data['payload']['text'] as String;
          } else if (data['data'] is Map && (data['data']['text'] is String)) {
            msg = data['data']['text'] as String;
          }

          // detect partial vs final transcripts
          final isPartial =
              (data['partial'] == true) ||
              (data['is_final'] == false) ||
              (data['final'] == false) ||
              (data['delta'] is Map && (data['delta']['final'] == false));

          // Prefer final messages; still allow assistant text even if no explicit "final" flag
          final looksLikeAssistant =
              type.contains('assistant') || type.contains('reply') || type.contains('response') || type.contains('text') || type.contains('chat');

          if (msg != null && msg.trim().isNotEmpty) {
            if (!isPartial || looksLikeAssistant) {
              onTextReceived?.call(msg.trim());
              return;
            } else {
              // ignore partials
              return;
            }
          }

          // Switch on known types as a fallback
          switch (type) {
            case 'text_response':
            case 'assistant':
            case 'assistant_message':
            case 'chat':
            case 'chat_text':
            case 'response':
            case 'reply':
            case 'text':
            case 'transcript':
            case 'final_transcription':
            case 'asr_final':
              if (msg != null && msg.trim().isNotEmpty) {
                onTextReceived?.call(msg.trim());
              }
              break;

            case 'error':
              final err = (data['message'] ?? data['error'] ?? 'Unknown error').toString();
              debugPrint('📥 Error response received: $err');
              onError?.call(err);
              break;

            default:
              // Unknown JSON shape: surface any text-like value; otherwise log
              final fallback = (data['message'] ?? data['text'] ?? data['content'] ?? '').toString().trim();
              if (fallback.isNotEmpty) {
                onTextReceived?.call(fallback);
              } else {
                debugPrint('📥 Unhandled agent data: $data');
              }
          }
        } catch (e) {
          debugPrint('❌ Error processing received data: $e');
          onError?.call('Error processing agent response: $e');
        }
      });

      debugPrint('✅ LiveKit data listener setup complete');
    } catch (e) {
      debugPrint('❌ Error setting up LiveKit data listener: $e');
      onError?.call('Failed to setup data listener: $e');
    }
  }

  /// Check if room is connected and ready
  bool isRoomReady() {
    return _room != null && 
           _room!.localParticipant != null && 
           _room!.connectionState == sdk.ConnectionState.connected;
  }

  /// Get room connection state
  sdk.ConnectionState? getConnectionState() {
    return _room?.connectionState;
  }

  /// Get local participant identity
  String? getLocalParticipantIdentity() {
    return _room?.localParticipant?.identity;
  }

  /// Get remote participants count
  int getRemoteParticipantsCount() {
    return _room?.remoteParticipants.length ?? 0;
  }

  /// Send keep-alive ping to maintain connection
  Future<void> sendKeepAlive() async {
    if (!isRoomReady()) return;

    try {
      final localParticipant = _room!.localParticipant!;
      
      final pingData = {
        'type': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await localParticipant.publishData(
        utf8.encode(jsonEncode(pingData)),
        reliable: false,
        topic: 'ping',
      );
    } catch (e) {
      debugPrint('Error sending keep-alive ping: $e');
    }
  }

  /// Cleanup LiveKit resources
  void cleanup() {
    _eventsListener?.dispose();
    _eventsListener = null;
    _room = null;
  }

  /// Get room statistics
  Map<String, dynamic> getRoomStats() {
    if (_room == null) {
      return {'connected': false};
    }

    return {
      'connected': isRoomReady(),
      'connectionState': _room!.connectionState.toString(),
      'localParticipant': _room!.localParticipant?.identity,
      'remoteParticipants': _room!.remoteParticipants.length,
      'roomName': _room!.name,
      'roomSid': _room!.name, // Using name instead of sid for now
    };
  }
}
