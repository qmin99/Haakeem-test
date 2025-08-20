# Click-to-Talk Feature Documentation

## Overview

The Click-to-Talk feature provides manual voice interaction control for both English and Arabic languages in the HAAKEEM voice agent application. This feature allows users to speak for extended periods without interruption and manually control when their speech is processed by the AI assistant.

## Table of Contents

1. [Feature Description](#feature-description)
2. [Architecture](#architecture)
3. [English Click-to-Talk Agent](#english-click-to-talk-agent)
4. [Arabic Click-to-Talk Agent](#arabic-click-to-talk-agent)
5. [User Interface](#user-interface)
6. [Implementation Details](#implementation-details)
7. [State Management](#state-management)
8. [Data Flow](#data-flow)
9. [File Processing](#file-processing)
10. [Configuration](#configuration)

## Feature Description

Click-to-Talk mode provides:

- **Manual Turn Detection**: Users control when recording starts and stops
- **Extended Speaking**: Users can speak for as long as needed without interruption
- **Multi-language Support**: Available in both English and Arabic
- **Professional UI**: Visual feedback for different states (idle, recording, ready to send, processing)
- **File Support**: Document upload and analysis capabilities

### Key Benefits

1. **No Interruptions**: Users can speak freely without the AI interrupting mid-sentence
2. **Complete Thoughts**: Ideal for complex legal questions or detailed explanations
3. **User Control**: Full control over when the recording starts and stops
4. **Clear Feedback**: Visual indicators show the current state of the interaction

## Architecture

### Backend Components

```
backend/agent/
├── agent.py                     # Main orchestrator with session management
├── agents/
│   ├── click_to_talk_agent.py          # English click-to-talk agent
│   └── arabic_click_to_talk_agent.py   # Arabic click-to-talk agent
```

### Frontend Components

```
app/lib/
├── controllers/
│   └── app_ctrl.dart           # State management and LiveKit integration
├── widgets/
│   └── click_to_talk_controls.dart    # UI controls and visual feedback
└── screens/
    └── main_screen.dart        # Main UI integration
```

## English Click-to-Talk Agent

### Configuration

```python
class ClickToTalkAgent(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions=(
            ),
            stt=deepgram.STT(
                model="nova-2",
                language="en",
                keywords=[
                    ("HAAKEEM", 9.0),
                    ("Haakeem", 6.0),
                    ("Binfin8", 9.0),
                ],
            ),
            llm=groq.LLM(model="llama3-8b-8192"),
            tts=AzureTTS(
                voice="en-US-OnyxTurboMultilingualNeural",
                language="en-US",
            ),
        )
```

### Features

- **STT**: Deepgram Nova-2 model with English language support
- **LLM**: Groq Llama3-8B-8192 for response generation
- **TTS**: Azure Neural Voice (Onyx Turbo Multilingual)
- **Keyword Recognition**: Enhanced recognition for "HAAKEEM" and "Binfin8"
- **Brand Normalization**: Automatic correction of brand name variants

## Arabic Click-to-Talk Agent

### Configuration

```python
class ArabicClickToTalkAgent(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions=(
            ),
            stt=AzureSTT(language=["ar-SA", "ar-EG"]),
            llm=groq.LLM(model="allam-2-7b"),
            tts=AzureTTS(voice="ar-OM-AbdullahNeural", language="ar-OM"),
        )
```

### Features

- **STT**: Azure Speech-to-Text with Arabic support (Saudi and Egyptian dialects)
- **LLM**: Groq Allam-2-7B specialized for Arabic
- **TTS**: Azure Gulf Arabic voice (Abdullah Neural)
- **Dialect Adaptation**: Responds in user's dialect when detected, defaults to Gulf Arabic
- **Localized File Processing**: All file-related messages in Arabic

### Arabic Instructions Summary

The Arabic agent:
- Introduces itself as "حَكيم" (HAAKEEM)
- Adapts to the user's dialect when recognizable
- Defaults to Gulf Arabic (Saudi/Qatari) instead of formal Arabic
- Provides concise, practical responses suitable for click-to-talk interaction
- Offers brief summaries followed by direct legal points for document analysis

## User Interface

### State Indicators

The UI provides clear visual feedback for all interaction states:

#### 1. **Idle State** (Ready)
- **Color**: Gray
- **Icon**: Radio button (unchecked)
- **Message**: "Click 'Start Speaking' to begin. Speak for as long as you need, then click 'End' to get HAAKEEM's response."
- **Button**: "Start Speaking" (Blue)

#### 2. **Listening State** (Recording)
- **Color**: Red
- **Icon**: Recording dot
- **Message**: "Recording... Speak freely for as long as you need."
- **Timer**: Shows speaking duration
- **Buttons**: "Cancel" (Red outline) + "End Speaking" (Red)

#### 3. **Ready to Send State**
- **Color**: Green
- **Icon**: Check circle
- **Message**: "Recording complete! Click 'Send' for HAAKEEM to process your message."
- **Buttons**: "Discard" (Gray outline) + "Send to HAAKEEM" (Green)

#### 4. **Processing State**
- **Color**: Blue
- **Icon**: Loading spinner
- **Message**: "HAAKEEM is processing your message..."
- **Button**: "Processing..." (Disabled)

### Visual Design

```dart
// Color Scheme
static const Color primaryGreen = Color(0xFF153F1E);
static const Color cardBackground = Color(0xFFFFFFFF);
static const Color textPrimary = Color(0xFF1A1A1A);
static const Color textSecondary = Color(0xFF6B7280);
static const Color accentBlue = Color(0xFF3B82F6);
static const Color accentRed = Color(0xFFEF4444);
static const Color accentGreen = Color(0xFF10B981);
static const Color borderColor = Color(0xFFE5E7EB);
```

## Implementation Details

### Backend Session Management

```python
# Click-to-talk sessions use manual turn detection
if agent_type in ("click_to_talk", "arabic_click_to_talk"):
    session = AgentSession(
        turn_detection="manual", 
        discard_audio_if_uninterruptible=True
    )
```

### Turn Control Commands

The system uses three key commands for turn management:

#### 1. **start_turn**
```python
session.interrupt()                    # Stop any current agent speech
session.clear_user_turn()             # Clear previous input
session.input.set_audio_enabled(True) # Start listening
```

#### 2. **end_turn**
```python
session.input.set_audio_enabled(False)        # Stop listening
session.commit_user_turn(transcript_timeout=3.0)  # Process input
```

#### 3. **cancel_turn**
```python
session.input.set_audio_enabled(False)  # Stop listening
session.clear_user_turn()              # Clear input buffer
```

### Frontend State Management

```dart
enum ClickToTalkState {
  idle,         // Ready to start recording
  listening,    // Currently recording user speech
  readyToSend,  // Recording complete, ready to send
  processing,   // AI is processing the input
}
```

## State Management

### State Transitions

```
idle → listening → readyToSend → processing → idle
  ↑        ↓              ↓
  ←--------cancel---------←
```

### Duration Tracking

During the listening state, the system tracks speaking duration:

```dart
// Start timer when listening begins
_clickToTalkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  _speakingDuration = Duration(seconds: timer.tick);
  notifyListeners();
});
```

## Data Flow

### 1. **Start Recording**
```
User clicks "Start Speaking"
    ↓
Frontend sends interrupt_agent command
    ↓
Frontend enables microphone
    ↓
Frontend sends start_turn command
    ↓
Backend starts audio capture
    ↓
UI shows recording state with timer
```

### 2. **Stop Recording**
```
User clicks "End Speaking"
    ↓
Frontend disables microphone
    ↓
UI shows "Ready to Send" state
```

### 3. **Send for Processing**
```
User clicks "Send to HAAKEEM"
    ↓
Frontend sends end_turn command
    ↓
Backend processes audio and generates response
    ↓
Agent speaks response
    ↓
UI returns to idle state
```

### 4. **Cancel Recording**
```
User clicks "Cancel" or "Discard"
    ↓
Frontend sends cancel_turn command
    ↓
Backend clears audio buffer
    ↓
UI returns to idle state
```

## File Processing

Both English and Arabic click-to-talk agents support file upload and analysis:

### Supported File Types

1. **Text Files** (.txt)
2. **PDF Documents** (.pdf)
3. **Images** (jpg, png, etc.)
4. **Word Documents** (.doc, .docx)
5. **JSON Files** (.json)

### Processing Workflow

```python
async def _file_received(self, reader, participant_identity):
    # Read file bytes
    file_bytes = bytearray()
    async for chunk in reader:
        file_bytes.extend(chunk)
    
    # Process based on MIME type
    file_content = await self._process_file(bytes(file_bytes), stream_info)
    
    # Generate AI analysis
    if file_content:
        analysis_prompt = f"Analyze this document: {file_content}"
        await self.session.generate_reply(instructions=analysis_prompt)
```

### Language-Specific Responses

- **English Agent**: Provides analysis in English
- **Arabic Agent**: All file processing messages and analysis in Arabic

## Configuration

### Environment Variables

The system requires these environment variables for proper operation:

```bash
# Azure Speech Services
AZURE_SPEECH_KEY=your_azure_speech_key
AZURE_SPEECH_REGION=your_azure_region

# Groq API
GROQ_API_KEY=your_groq_api_key

# Deepgram API (for English STT)
DEEPGRAM_API_KEY=your_deepgram_api_key

# LiveKit
LIVEKIT_URL=your_livekit_url
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
```

### Agent Selection

Users can switch between agents using the frontend selection interface:

```dart
// Agent types
enum AgentType {
  attorney,              // Continuous English conversation
  clickToTalk,          // Manual English conversation
  arabic,               // Continuous Arabic conversation
  arabicClickToTalk,    // Manual Arabic conversation
}
```

### Language Filtering

The UI provides language-based filtering:
- **English**: Shows Attorney and Click-to-Talk agents
- **Arabic**: Shows Arabic and Arabic Click-to-Talk agents
- **All**: Shows all available agents

## Best Practices

### For Users

1. **Clear Speech**: Speak clearly and at a normal pace
2. **Complete Thoughts**: Take advantage of the uninterrupted speaking time
3. **Wait for Processing**: Allow the system to process before starting a new interaction
4. **Use Cancel Wisely**: Use cancel/discard if you want to re-record

### For Developers

1. **Memory Management**: Monitor memory usage, especially on constrained environments like Heroku Basic dynos
2. **Session Cleanup**: Ensure proper cleanup when switching between agents
3. **Error Handling**: Implement robust error handling for network interruptions
4. **State Synchronization**: Keep frontend and backend states synchronized


### Debug Logging

The system includes comprehensive logging for troubleshooting:

```python
logger.info(f"🎤 Starting click-to-talk recording...")
logger.info(f"🛑 Ending click-to-talk recording and processing...")
logger.info(f"❌ Canceling click-to-talk...")
```

Frontend debug logging:

```dart
debugPrint('🎤 startClickToTalkListening called');
debugPrint('🛑 Sent interrupt command before starting to speak');
debugPrint('📤 Sent start_turn command to backend');
```

## Future Enhancements

### Planned Features

1. **Voice Activity Detection**: Optional VAD during recording for better user experience
2. **Transcription Preview**: Show real-time transcription during recording
3. **Audio Visualization**: Waveform display during recording
4. **Custom Timeouts**: User-configurable timeout settings
5. **Recording Quality Indicators**: Signal strength and quality feedback

### Technical Improvements

1. **WebRTC Optimization**: Better audio quality and reduced latency
2. **Offline Support**: Limited offline functionality for basic operations
3. **Multi-format Export**: Export conversations in various formats
4. **Advanced Analytics**: Usage patterns and performance metrics

---

*This documentation covers the current implementation of the Click-to-Talk feature as of the latest version. For updates and changes, refer to the project's changelog and commit history.*

Last Updated: Aug 14, 2025
