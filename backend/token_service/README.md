# LiveKit Token Service - Multi-Agent Support

A FastAPI-based token generation service that provides secure JWT tokens for connecting to LiveKit rooms with automatic multi-agent dispatch.

## 🎯 Features

- **Secure JWT Generation**: Server-side token signing with LiveKit API credentials
- **Multi-Agent Dispatch**: Automatically dispatches the `multi-assistant` agent to rooms
- **Voice Processing**: Direct audio upload and processing endpoints
- **Health Monitoring**: Built-in health check endpoints
- **Serverless Ready**: Deploy to any serverless platform

---

## 🚀 Local Development

### Prerequisites
- Python **3.10+**
- Required API keys (see Environment Setup)

### Quick Start

```bash
# Navigate to token service directory
cd backend/token_service 

# Create virtual environment (if not already created)
python3 -m venv venv && source venv/bin/activate
# OR reuse existing environment
source venv/bin/activate

# Install dependencies
pip install -r ../requirements.txt

# Set environment variables
export LIVEKIT_API_KEY=your_api_key_here
export LIVEKIT_API_SECRET=your_api_secret_here  
export LIVEKIT_URL=wss://your-project.livekit.cloud

# Optional: AI service keys for voice processing
export DEEPGRAM_API_KEY=your_deepgram_key
export GROQ_API_KEY=your_groq_key
export AZURE_SPEECH_KEY=your_azure_key
export AZURE_SPEECH_REGION=your_azure_region

# Start the service
uvicorn main:app --reload --port 8080
```

### Environment Configuration

Create a `.env` file in the backend directory:

```bash
# Required: LiveKit Configuration
LIVEKIT_API_KEY=your_api_key_here
LIVEKIT_API_SECRET=your_api_secret_here
LIVEKIT_URL=wss://your-project.livekit.cloud

# Optional: AI Services (for voice processing endpoint)
DEEPGRAM_API_KEY=your_deepgram_key
GROQ_API_KEY=your_groq_key  
AZURE_SPEECH_KEY=your_azure_key
AZURE_SPEECH_REGION=your_azure_region

# Optional: CORS configuration
ALLOWED_ORIGINS=*  # Restrict in production
```

---

## 📡 API Endpoints

### `POST /getToken` - Generate Room Access Token

Creates a JWT token for joining LiveKit rooms with automatic multi-agent dispatch.

**Request:**
```bash
curl -X POST http://localhost:8080/getToken \
  -H "Content-Type: application/json" \
  -d '{
    "room": "legal-consultation", 
    "identity": "user-alice",
    "name": "Alice Johnson"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "serverUrl": "wss://your-project.livekit.cloud",
  "roomName": "legal-consultation", 
  "participantName": "Alice Johnson"
}
```

**Features:**
- Automatically dispatches `multi-assistant` agent to the room
- Grants publish/subscribe permissions
- Configures room with agent dispatch settings

### `POST /voice/upload` - Process Voice Recording

Upload and process audio files directly through the token service.

**Request:**
```bash
curl -X POST http://localhost:8080/voice/upload?room=legal-room \
  -F "file=@recording.webm"
```

**Response:**
```json
{
  "ok": true,
  "transcript": "I need help with a contract review",
  "reply": "I'd be happy to help you with contract review...",
  "speech_audio": "base64_encoded_audio_data",
  "agent_notified": true,
  "room": "legal-room"
}
```

**Supported Formats:**
- WebM (browser recordings)
- M4A (iOS recordings)
- WAV, MP3 (standard audio formats)

### `GET /health` - Health Check

Monitor service status and configuration.

**Response:**
```json
{
  "status": "healthy",
  "deepgram_configured": true,
  "groq_configured": true, 
  "azure_tts_configured": true,
  "livekit_configured": true
}
```

---

## 🔧 Multi-Agent Integration

### Automatic Agent Dispatch

The token service automatically configures rooms with the multi-agent system:

```python
# Dispatch multi-assistant agent automatically  
at_builder = at_builder.with_room_config(
    api.RoomConfiguration(
        agents=[
            api.RoomAgentDispatch(agent_name="multi-assistant")
        ]
    )
)
```

### Agent Communication

The service works seamlessly with the multi-agent backend:
- **AttorneyAgent**: Continuous conversation mode
- **ClickToTalkAgent**: Long-form input processing
- **Dynamic Switching**: Users can switch between agents via the Flutter UI

---

## 🏗️ Flutter Integration

### Environment Configuration

Add to your Flutter app's `.env` file:

```bash
# Primary: Token service endpoint
TOKEN_ENDPOINT=http://localhost:8080/getToken

# Alternative: LiveKit Sandbox (development)
LIVEKIT_SANDBOX_ID=your_sandbox_id
```

### Token Service Usage

The Flutter app automatically:
1. Calls `/getToken` with room details
2. Receives JWT token and server URL
3. Connects to LiveKit room
4. Multi-agent system joins automatically

### Expected Response Format

Flutter expects tokens in this format:
```json
{
  "token": "<jwt_token>",
  "serverUrl": "wss://project.livekit.cloud", 
  "roomName": "room_name",
  "participantName": "user_identity"
}
```

---

## 🚀 Deployment Options

### Serverless Platforms

**Vercel:**
```bash
vercel --env LIVEKIT_API_KEY=xxx --env LIVEKIT_API_SECRET=xxx
```

**Railway:**
```bash
railway deploy --env LIVEKIT_API_KEY=xxx --env LIVEKIT_API_SECRET=xxx
```

**Heroku:**
```bash
heroku config:set LIVEKIT_API_KEY=xxx LIVEKIT_API_SECRET=xxx
git push heroku main
```

### Production Configuration

```bash
# Security: Restrict CORS origins
ALLOWED_ORIGINS=https://yourapp.com,https://yourdomain.com

# Performance: Set appropriate port
PORT=8080

# Monitoring: Configure logging level
LOG_LEVEL=INFO
```

---

## 🔍 Troubleshooting

### Common Issues

1. **"Invalid API credentials"**
   - Verify `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET`
   - Check LiveKit project status

2. **"CORS policy error"** 
   - Update `ALLOWED_ORIGINS` to include your domain
   - Use `*` for development only

3. **"Agent not joining room"**
   - Ensure multi-agent backend is running
   - Verify agent name matches `multi-assistant`

4. **"Voice upload failing"**
   - Check Deepgram, Groq, and Azure API keys
   - Verify audio file format is supported

### Debug Mode

Run with enhanced logging:
```bash
uvicorn main:app --reload --log-level debug --port 8080
```

### Testing Without Frontend

Test token generation:
```bash
curl -X POST http://localhost:8080/getToken \
  -H "Content-Type: application/json" \
  -d '{"room":"test","identity":"debug-user"}'
```

---

## 📊 Architecture Notes

- **Stateless Design**: No server-side session storage required
- **Security**: API secrets never exposed to client
- **Scalability**: Serverless-friendly, auto-scaling capable  
- **Monitoring**: Built-in health checks and error handling
- **Integration**: Seamless multi-agent dispatch and room configuration

---

**Built for LiveKit Multi-Agent System** • [LiveKit Docs](https://docs.livekit.io/) • [FastAPI](https://fastapi.tiangolo.com/)