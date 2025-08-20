import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'package:flutter_gemini/flutter_gemini.dart';


// Load environment variables before starting the app
// This is used to configure the LiveKit sandbox ID for development
void main() async {
  await dotenv.load(fileName: ".env");
  Gemini.init(apiKey: 'AIzaSyBLyqPegGYNLSzJfsloawazBxU1bgnF-0Q');

  // Disable Provider's strict type checking for LiveKit RoomContext compatibility
  Provider.debugCheckInvalidValueType = null;

  runApp(const VoiceAssistantApp());
}
