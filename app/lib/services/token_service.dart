import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Data class representing the connection details needed to join a LiveKit room
/// This includes the server URL, room name, participant info, and auth token
class ConnectionDetails {
  final String serverUrl;
  final String roomName;
  final String participantName;
  final String participantToken;

  ConnectionDetails({
    required this.serverUrl,
    required this.roomName,
    required this.participantName,
    required this.participantToken,
  });

  factory ConnectionDetails.fromJson(Map<String, dynamic> json) {
    return ConnectionDetails(
      serverUrl: json['serverUrl'],
      roomName: json['roomName'],
      participantName: json['participantName'],
      participantToken: json['participantToken'],
    );
  }
}

/// An example service for fetching LiveKit authentication tokens
///
/// To use the LiveKit Cloud sandbox (development only)
/// - Enable your sandbox here https://cloud.livekit.io/projects/p_/sandbox/templates/token-server
/// - Create .env file with your LIVEKIT_SANDBOX_ID
///
/// To use a hardcoded token (development only)
/// - Generate a token: https://docs.livekit.io/home/cli/cli-setup/#generate-access-token
/// - Set `hardcodedServerUrl` and `hardcodedToken` below
///
/// To use your own server (production applications)
/// - Add a token endpoint to your server with a LiveKit Server SDK https://docs.livekit.io/home/server/generating-tokens/
/// - Modify or replace this class as needed to connect to your new token server
/// - Rejoice in your new production-ready LiveKit application!
///
/// See https://docs.livekit.io/home/get-started/authentication for more information
class TokenService {
  // For hardcoded token usage (development only)
  final String? hardcodedServerUrl = null;
  final String? hardcodedToken = null;

  // Prefer .env during development; fall back to dart-define only if .env is empty
  String? _resolveTokenEndpoint() {
    final envValue = dotenv.env['TOKEN_ENDPOINT'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    if (Env.tokenEndpoint.isNotEmpty) {
      return Env.tokenEndpoint;
    }
    return null;
  }

  // Platform-aware localhost mapping (for Android emulator use 10.0.2.2)
  String _normalizeHostForPlatform(String endpoint) {
    try {
      final uri = Uri.parse(endpoint);
      final host = uri.host;
      // Map localhost to Android emulator host if needed
      if (defaultTargetPlatform == TargetPlatform.android &&
          (host == '127.0.0.1' || host == 'localhost')) {
        return uri.replace(host: '10.0.2.2').toString();
      }
      return endpoint;
    } catch (_) {
      return endpoint;
    }
  }

  late final String? tokenEndpoint = (() {
    final resolved = _resolveTokenEndpoint();
    if (resolved == null) return null;
    return _normalizeHostForPlatform(resolved);
  })();

  // Get the sandbox ID from environment variables
  String? get sandboxId {
    final value = dotenv.env['LIVEKIT_SANDBOX_ID'];
    if (value != null) {
      // Remove unwanted double quotes if present
      return value.replaceAll('"', '');
    }
    return null;
  }

  // LiveKit Cloud sandbox API endpoint
  final String sandboxUrl =
      'https://cloud-api.livekit.io/api/sandbox/connection-details';

  /// Main method to get connection details
  /// First tries hardcoded credentials, then falls back to sandbox
  Future<ConnectionDetails> fetchConnectionDetails({
    required String roomName,
    required String participantName,
  }) async {
    // 1. Try token endpoint if configured (and do NOT fallback silently when it exists)
    if (tokenEndpoint != null && tokenEndpoint!.isNotEmpty) {
      final uri = Uri.parse(tokenEndpoint!);
      try {
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'room': roomName, 'identity': participantName}),
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final data = jsonDecode(resp.body);
          return ConnectionDetails(
            serverUrl: data['serverUrl'] ?? hardcodedServerUrl ?? '',
            roomName: data['roomName'] ?? roomName,
            participantName: data['participantName'] ?? participantName,
            participantToken: data['token'] ?? data['participantToken'],
          );
        }
        // If server returned an error code, surface it
        throw Exception('Token endpoint error: HTTP ${resp.statusCode}');
      } catch (e) {
        // Do not fallback to sandbox if a token endpoint is explicitly configured
        debugPrint('Token endpoint error (no fallback): $e');
        rethrow;
      }
    }

    // 2. Hard-coded token (dev)
    final hardcodedDetails = fetchHardcodedConnectionDetails(
      roomName: roomName,
      participantName: participantName,
    );
    if (hardcodedDetails != null) {
      return hardcodedDetails;
    }

    // 3. Fallback to LiveKit Cloud sandbox (dev) ONLY if no token endpoint configured
    return await fetchConnectionDetailsFromSandbox(
      roomName: roomName,
      participantName: participantName,
    );
  }

  Future<ConnectionDetails> fetchConnectionDetailsFromSandbox({
    required String roomName,
    required String participantName,
  }) async {
    if (sandboxId == null) {
      throw Exception('Sandbox ID is not set');
    }

    final uri = Uri.parse(sandboxUrl).replace(queryParameters: {
      'roomName': roomName,
      'participantName': participantName,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'X-Sandbox-ID': sandboxId!},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          return ConnectionDetails.fromJson(data);
        } catch (e) {
          debugPrint(
              'Error parsing connection details from LiveKit Cloud sandbox, response: ${response.body}');
          throw Exception(
              'Error parsing connection details from LiveKit Cloud sandbox');
        }
      } else {
        debugPrint(
            'Error from LiveKit Cloud sandbox: ${response.statusCode}, response: ${response.body}');
        throw Exception('Error from LiveKit Cloud sandbox');
      }
    } catch (e) {
      debugPrint('Failed to connect to LiveKit Cloud sandbox: $e');
      throw Exception('Failed to connect to LiveKit Cloud sandbox');
    }
  }

  ConnectionDetails? fetchHardcodedConnectionDetails({
    required String roomName,
    required String participantName,
  }) {
    if (hardcodedServerUrl == null || hardcodedToken == null) {
      return null;
    }

    return ConnectionDetails(
      serverUrl: hardcodedServerUrl!,
      roomName: roomName,
      participantName: participantName,
      participantToken: hardcodedToken!,
    );
  }
}
