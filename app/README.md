# Voice Agent - Flutter Multi-Agent Client

A Flutter application that provides a modern interface for interacting with the [LiveKit Agents](https://docs.livekit.io/agents/overview/) multi-agent voice system.

## 🎯 Features

This Flutter app provides a sleek interface for two distinct AI agents:

### 🏛️ Attorney Agent Mode
- **Continuous conversation** for quick legal questions
- **Real-time interaction** with immediate responses
- **Natural dialogue** flow for consultations

### 🎤 Click-to-Talk Agent Mode  
- **Long-form input** for detailed legal discussions
- **Uninterrupted recording** - speak as long as needed
- **Comprehensive responses** to complex legal matters
- **Manual control** - click to start/stop recording

## 🚀 Getting Started

### Prerequisites
- Flutter **3.22+** with Dart SDK
- A running backend service (see `../backend/README.md`)

### Quick Setup with LiveKit CLI

The easiest way to get this app running is with the [LiveKit CLI](https://docs.livekit.io/home/cli/cli-setup/):

```bash
lk app create --template voice-assistant-flutter --sandbox <token_server_sandbox_id>
```

### Manual Setup

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Configure environment:**
Create a `.env` file in the app root:
```bash
# Your backend token service endpoint
TOKEN_ENDPOINT=http://localhost:8080/getToken

# Or use LiveKit Sandbox
LIVEKIT_SANDBOX_ID=your_sandbox_id
```

3. **Run the application:**
```bash
flutter run -d chrome  # Web
flutter run             # Mobile/Desktop
```

## 🎮 How to Use

### Starting a Session
1. **Enter room details** - Choose a room name and your identity
2. **Join the room** - Click "Start Call" to connect
3. **Wait for agent connection** - The multi-agent system will join automatically

### Attorney Agent (Continuous Mode)
- Simply start speaking - the agent listens continuously
- Ask legal questions naturally
- Get immediate responses and follow-up guidance
- Perfect for quick consultations and clarifications

### Click-to-Talk Agent (Long-form Mode)
- **Start Recording**: Click and begin speaking freely
- **Speak extensively**: Share detailed legal scenarios without interruption  
- **End Recording**: Click when finished to process your input
- **Stop**: Cancel and clear recording if needed
- **Get comprehensive responses**: Detailed analysis and recommendations

### Agent Switching
- Use the agent selection interface to switch between modes
- Each agent optimizes for different interaction patterns
- State is preserved during switches

## 🏗️ Architecture

### UI Components
- **AgentSelectionWidget**: Choose between Attorney and Click-to-Talk agents
- **ClickToTalkControls**: Recording controls for long-form input mode
- **Modern Material Design**: Clean, professional interface
- **Real-time feedback**: Visual indicators for recording and processing states

### Communication
- **LiveKit SDK**: Real-time audio/video communication
- **RPC Methods**: Agent switching and control commands
- **Data Messages**: State synchronization with backend
- **Token Service**: Secure JWT-based authentication

### Supported Platforms
- ✅ **Web** (Chrome, Safari, Firefox)
- ✅ **iOS** (requires Xcode signing setup)
- ✅ **Android** 
- ✅ **macOS**
- ✅ **Windows**
- ✅ **Linux**

## 🔧 Configuration

### Environment Variables
```bash
# Backend service endpoint (preferred)
TOKEN_ENDPOINT=https://your-backend.com/getToken

# Alternative: LiveKit Sandbox ID
LIVEKIT_SANDBOX_ID=your_sandbox_id

# Optional: Custom LiveKit server
LIVEKIT_URL=wss://your-project.livekit.cloud
```

### Token Service Response Format
Your backend should return tokens in this format:
```json
{
  "token": "<jwt>",
  "serverUrl": "wss://your-project.livekit.cloud",
  "roomName": "legal-consultation",
  "participantName": "user-identity"
}
```

## 📱 Platform-Specific Notes

### iOS Development
- Configure signing certificates in Xcode for device testing
- Microphone permissions are handled automatically
- Ensure iOS 12.0+ for LiveKit support

### Android Development  
- Minimum SDK: API 21 (Android 5.0)
- Microphone permissions requested at runtime
- ProGuard/R8 rules included for release builds

### Web Development
- Requires HTTPS in production for microphone access
- WebRTC support required (modern browsers)
- Optimized for desktop and mobile web

## 🔍 Troubleshooting

### Common Issues
1. **"No backend connection"** - Verify your TOKEN_ENDPOINT is correct
2. **"Microphone not working"** - Check browser/OS permissions
3. **"Agent not responding"** - Ensure backend agents are running
4. **"Poor audio quality"** - Check network connection and microphone setup

### Debug Mode
Run with additional logging:
```bash
flutter run --debug -d chrome --web-renderer html
```

## 🤝 Contributing

This app integrates with the LiveKit Agents framework. For backend agent development, see the [LiveKit Agents documentation](https://docs.livekit.io/agents/).

---

**Built with Flutter & LiveKit** • [LiveKit Cloud](https://livekit.io/cloud) • [Flutter SDK](https://github.com/livekit/client-sdk-flutter)