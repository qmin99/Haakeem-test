# Voice Agent - Multi-Agent Legal Assistant

This repository contains a **Flutter** front-end and a **Python** multi-agent back-end that showcase the [LiveKit Agents](https://docs.livekit.io/agents/) framework.

## 🚀 Features

The application now features a **dual-agent architecture**:

1. **AttorneyAgent** - Continuous conversation mode for legal guidance and advice
2. **ClickToTalkAgent** - Long-form input mode where users can speak freely and get comprehensive responses

## Project layout

```
voice-agent/
├─ backend/          # Python multi-agent + FastAPI token service
│  ├─ agent/         # Multi-agent system (attorney + click-to-talk)
│  └─ token_service/ # JWT token generation service
└─ app/              # Flutter client (web, desktop, mobile)
```

## Prerequisites

* Python **3.10+**
* Flutter **3.22+** (with Dart SDK)
* A LiveKit Cloud project + API key/secret
* API keys for:
  - **Deepgram** (Speech-to-Text)
  - **Groq** (LLM)
  - **Azure Speech** (Text-to-Speech)

---

## 1. Back-end Setup (Multi-Agent + Token Service)

### Environment Configuration

Create `.env` file in the `backend` directory:

```bash
# LiveKit Configuration
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=your_api_key
LIVEKIT_API_SECRET=your_api_secret

# AI Service APIs
DEEPGRAM_API_KEY=your_deepgram_key
GROQ_API_KEY=your_groq_key
AZURE_SPEECH_KEY=your_azure_key
AZURE_SPEECH_REGION=your_azure_region
```

### Installation & Running

```bash
# One-time setup
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Start the Multi-Agent System
python3 -m agent.agent start
# OR
cd backend/agent
python3 agent.py start

# In another terminal (same venv), start the token server
cd backend/token_service
uvicorn main:app --reload --port 8080
```

### Multi-Agent Architecture

The system automatically dispatches the **multi-assistant** agent which includes:

- **AttorneyAgent**: Provides legal guidance in continuous conversation mode
- **ClickToTalkAgent**: Handles long-form user input with comprehensive responses

Users can switch between agents through the Flutter UI.

---

## 2. Front-end (Flutter)

```bash
cd app
flutter pub get           # install Dart dependencies
flutter run -d chrome     # or any connected device
```

### Using the Application

1. **Enter room details** - Room name and your identity
2. **Start the call** - The app requests a token and joins the LiveKit room
3. **Select agent mode**:
   - **Attorney Agent**: Continuous conversation for quick legal questions
   - **Click-to-Talk Agent**: Long-form input for detailed legal discussions
4. **Click-to-Talk Mode Controls**:
   - **Start Recording**: Begin speaking freely
   - **End Recording**: Stop and process your input
   - **Stop**: Cancel and clear the recording

The multi-agent system automatically handles switching between modes and appropriate audio processing.

---

## API Endpoints

### Token Service

- `POST /getToken` - Generate LiveKit JWT tokens
- `POST /voice/upload` - Process voice recordings (for testing)
- `GET /health` - Health check endpoint

---

## Architecture Notes

- **Agent Registration**: The system uses `multi-assistant` as the agent name
- **Audio Processing**: Different agents use different turn detection modes
- **State Management**: Shared state between agents for seamless switching
- **Communication**: RPC methods and data messages for real-time control

---

## License

MIT License © LiveKit Contributors
# Haakeem-test
