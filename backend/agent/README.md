# Multi-Agent Voice Assistant System

<p>
  <a href="https://cloud.livekit.io/projects/p_/sandbox"><strong>Deploy a sandbox app</strong></a>
  •
  <a href="https://docs.livekit.io/agents/overview/">LiveKit Agents Docs</a>
  •
  <a href="https://livekit.io/cloud">LiveKit Cloud</a>
</p>

A sophisticated multi-agent system powered by LiveKit Agents that provides two distinct AI legal assistants.

## 🎯 Agent Architecture

### 🏛️ AttorneyAgent
- **Purpose**: Continuous legal consultation and guidance
- **Mode**: Real-time conversation with natural turn-taking  
- **Use Case**: Quick legal questions, immediate advice, consultations
- **Features**: Voice Activity Detection (VAD), interruption handling

### 🎤 ClickToTalkAgent  
- **Purpose**: Long-form legal analysis and comprehensive responses
- **Mode**: Manual turn detection with extended input buffering
- **Use Case**: Complex legal scenarios, document review, detailed analysis
- **Features**: Uninterrupted recording, comprehensive processing

## 🚀 Development Setup

### Prerequisites
- Python **3.10+**
- Virtual environment support
- Required API keys (see Environment Setup)

### Installation

```bash
# Navigate to agent directory
cd backend/agent

# Create and activate virtual environment
python3 -m venv venv && source venv/bin/activate

# Install dependencies
pip install -r ../requirements.txt

# Download required model files (if any)
python3 agent.py download-files
```

### Environment Setup

Create `.env.local` file in the agent directory with required API keys:

```bash
# LiveKit Configuration
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=your_api_key_here
LIVEKIT_API_SECRET=your_api_secret_here

# AI Service APIs  
DEEPGRAM_API_KEY=your_deepgram_key_here
GROQ_API_KEY=your_groq_key_here
AZURE_SPEECH_KEY=your_azure_speech_key
AZURE_SPEECH_REGION=your_azure_region

# Optional: Additional service keys
OPENAI_API_KEY=your_openai_key_here
CARTESIA_API_KEY=your_cartesia_key_here
```

**Quick Setup with LiveKit CLI:**
```bash
lk app env  # Automatically configure environment
```

## Running the Agent

From the **backend** directory:
```bash
# Install dependencies first if needed
pip install -r ../requirements.txt

# Start the agent in development mode
python3 -m agent.agent dev

# Start in production mode
python3 -m agent.agent start
```

## 🎮 Running the Multi-Agent System

### Production Mode
```bash
python3 agent.py start
```
This starts the multi-agent worker ready for production use.

### Development Mode  
```bash
python3 agent.py dev
```
Development mode with enhanced logging and debugging features.

### Console Mode (Testing)
```bash
python3 agent.py console
```
Interactive console for testing agent responses without a frontend.

## 🏗️ System Architecture

### Multi-Agent Coordination
- **Shared State**: `MultiAgentState` manages agent selection and click-to-talk recording state
- **Dynamic Switching**: Users can switch between agents seamlessly through RPC calls
- **Session Management**: Each agent type creates optimized LiveKit sessions

### Communication Protocols

#### RPC Methods
- `switch_to_attorney` - Activate AttorneyAgent
- `switch_to_click_to_talk` - Activate ClickToTalkAgent  
- `click_to_talk_start` - Begin long-form recording
- `click_to_talk_end` - Process recorded input
- `click_to_talk_stop` - Cancel and clear recording

#### Data Messages
- `switch_agent:attorney` - Agent switching via data channel
- `switch_agent:click_to_talk` - Agent switching via data channel
- `click_to_talk_start` - Recording control
- `click_to_talk_end` - Recording control  
- `click_to_talk_stop` - Recording control

### Audio Processing Modes

#### AttorneyAgent Session
```python
AgentSession(
    vad=silero.VAD.load(),           # Voice Activity Detection
    min_endpointing_delay=3.0,        # Natural conversation flow
    max_endpointing_delay=5.0,        # Reasonable response delays
    userdata=multi_agent_state
)
```

#### ClickToTalkAgent Session  
```python
AgentSession(
    turn_detection="manual",          # User-controlled turns
    allow_interruptions=False,        # No interruptions during recording
    discard_audio_if_uninterruptible=False,  # Preserve all audio
    min_endpointing_delay=0.0,        # No automatic endpoints
    max_endpointing_delay=0.0,        # Complete manual control
    vad=None,                         # No voice activity detection
    userdata=multi_agent_state
)
```

## 🔧 Configuration

### Agent Personalities

Both agents are configured as **HAAKEEM**, a professional AI legal assistant:

- **Professional tone**: Legal expertise with accessible language
- **Pronunciation**: "hakeem" (not H-A-A-K-E-E-M)
- **Specialization**: Legal guidance, advice, and assistance
- **Created by**: Binfin8 for democratizing legal knowledge access

### Service Integration

- **STT**: Deepgram Nova-2 model for accurate speech recognition
- **LLM**: Groq Llama3-8b-8192 for responsive legal knowledge
- **TTS**: Azure Speech Service for natural voice synthesis

## 📊 Monitoring & Metrics

The system includes comprehensive metrics collection:

```python
@session.on("metrics_collected")  
def on_metrics_collected(agent_metrics):
    metrics.log_metrics(agent_metrics)
    usage_collector.collect(agent_metrics)
```

Monitor usage patterns, response times, and agent switching behavior.

## 🔍 Troubleshooting

### Common Issues

1. **Agent not responding**
   - Check API keys in `.env.local`
   - Verify LiveKit connection
   - Review agent logs for errors

2. **Audio quality issues**  
   - Confirm Deepgram API key
   - Check Azure Speech configuration
   - Verify microphone permissions

3. **Agent switching problems**
   - Ensure RPC methods are properly registered
   - Check data message formatting
   - Verify session state management

### Debug Logging

Enable detailed logging by setting log levels:
```python
logging.getLogger("multi-agent").setLevel(logging.DEBUG)
```

### Testing Without Frontend

Use console mode to test agent behavior:
```bash
python3 agent.py console
```

## 🚀 Deployment

### Worker Configuration
```python
WorkerOptions(
    entrypoint_fnc=entrypoint,
    prewarm_fnc=prewarm,
    agent_name="multi-assistant",    # Important: matches token service
    concurrency=1,                   # Memory-efficient
    concurrency_mode="threads",      # Thread-based execution
    num_idle_processes=0,           # No idle processes
)
```

### Production Considerations
- **Memory Management**: Thread-based execution for efficiency
- **Error Handling**: Comprehensive exception handling for robustness  
- **SSL Certificates**: Properly configured for macOS compatibility
- **Session Cleanup**: Automatic cleanup on disconnection

---

**Built with LiveKit Agents Framework** • [Documentation](https://docs.livekit.io/agents/) • [Examples](https://github.com/livekit/agents)
