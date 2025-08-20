# Voice Agent System Architecture

## Overview

A sophisticated multi-agent legal assistant system built with Flutter frontend and Python LiveKit Agents backend. The system provides both continuous conversation and click-to-talk modes with multi-language support (English/Arabic).

## High-Level Architecture

```mermaid
graph TB
    subgraph "Flutter App (Frontend)"
        UI[UI Widgets] --> APP[AppCtrl]
        UI --> CHAT[ChatProvider]
        UI --> VOICE[VoiceProvider]
        UI --> FILE[FileProvider]
        
        APP --> LK[LiveKitService]
        APP --> TOKEN[TokenService]
        CHAT --> CS[ChatService]
        VOICE --> VS[VoiceService]
        FILE --> FS[FileService]
        
        CS --> GEMINI[GeminiService]
        LK --> |WebRTC| LIVEKIT[LiveKit Cloud]
    end
    
    subgraph "Backend Services"
        subgraph "Token Service (FastAPI)"
            TS[Token Service<br/>Port 8080] --> |JWT Generation| LIVEKIT
        end
        
        subgraph "Agent Worker (Python)"
            WORKER[Agent Worker] --> |LiveKit Agents| LIVEKIT
            WORKER --> ATT[AttorneyAgent]
            WORKER --> CTT[ClickToTalkAgent]
            WORKER --> AR[ArabicAgent]
            WORKER --> ARCTT[ArabicCTTAgent]
        end
    end
    
    subgraph "External Services"
        DEEPGRAM[Deepgram STT]
        AZURE[Azure STT/TTS]
        GROQ[Groq LLM]
        GEMINI_API[Gemini API]
    end
    
    TOKEN --> |Fetch Token| TS
    ATT --> DEEPGRAM
    ATT --> GROQ
    ATT --> AZURE
    CTT --> DEEPGRAM
    CTT --> GROQ
    CTT --> AZURE
    AR --> AZURE
    AR --> GROQ
    ARCTT --> AZURE
    ARCTT --> GROQ
    GEMINI --> GEMINI_API
    
    style UI fill:#e1f5fe
    style WORKER fill:#f3e5f5
    style TS fill:#e8f5e8
    style LIVEKIT fill:#fff3e0
```

## Component Architecture

### Frontend Components (Flutter)

```mermaid
graph TD
    subgraph "State Management"
        AC[AppCtrl<br/>- Connection State<br/>- Agent Selection<br/>- Click-to-Talk State]
        CP[ChatProvider<br/>- Message History<br/>- AI Processing]
        VP[VoiceProvider<br/>- Voice Recording<br/>- Waveform Data]
        FP[FileProvider<br/>- File Management<br/>- Upload State]
    end
    
    subgraph "Services Layer"
        LKS[LiveKitService<br/>- Room Management<br/>- Data Channels<br/>- File Streaming]
        TS[TokenService<br/>- JWT Fetching<br/>- Connection Details]
        CS[ChatService<br/>- Message Processing<br/>- History Management]
        VS[VoiceService<br/>- STT Integration<br/>- Waveform Generation]
        FS[FileService<br/>- File Picking<br/>- Validation]
        GS[GeminiService<br/>- Fallback AI<br/>- Document Analysis]
    end
    
    subgraph "UI Layer"
        CHAT_UI[Chat Widgets]
        VOICE_UI[Voice Controls]
        FILE_UI[File Management]
        SIDEBAR[Sidebar & Navigation]
    end
    
    AC --> LKS
    AC --> TS
    CP --> CS
    CP --> LKS
    VP --> VS
    FP --> FS
    CS --> GS
    LKS --> |WebRTC| CLOUD[LiveKit Cloud]
    
    CHAT_UI --> CP
    VOICE_UI --> VP
    FILE_UI --> FP
    SIDEBAR --> AC
```

### Backend Architecture

```mermaid
graph TD
    subgraph "Token Service (FastAPI)"
        MAIN[main.py]
        MAIN --> |JWT Generation| LIVEKIT_API[LiveKit API]
        MAIN --> |CORS & Health| CLIENT[Client Apps]
    end
    
    subgraph "Agent Worker"
        ENTRY[agent.py<br/>Entry Point]
        ENTRY --> SESS[Session Manager]
        SESS --> |Dynamic Switching| AGENTS[Agent Instances]
        
        subgraph "Agent Types"
            ATT[AttorneyAgent<br/>Continuous VAD]
            CTT[ClickToTalkAgent<br/>Manual Turns]
            AR[ArabicAgent<br/>Continuous VAD]
            ARCTT[ArabicCTTAgent<br/>Manual Turns]
        end
        
        AGENTS --> ATT
        AGENTS --> CTT
        AGENTS --> AR
        AGENTS --> ARCTT
        
        subgraph "Processing Pipeline"
            STT[Speech-to-Text]
            LLM[Language Model]
            TTS[Text-to-Speech]
            FILE_PROC[File Processing]
        end
        
        ATT --> STT
        CTT --> STT
        AR --> STT
        ARCTT --> STT
        
        STT --> LLM
        LLM --> TTS
        
        AGENTS --> FILE_PROC
    end
    
    ENTRY --> |LiveKit Agents| LIVEKIT_CLOUD[LiveKit Cloud]
```

## Data Flow Diagrams

### Authentication & Connection Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant TS as Token Service
    participant LK as LiveKit Cloud
    participant Worker as Agent Worker
    
    App->>TS: POST /getToken {room, identity}
    TS->>TS: Generate JWT with agent dispatch
    TS-->>App: {token, serverUrl, roomName}
    
    App->>LK: Connect with JWT
    LK->>Worker: Dispatch agent to room
    Worker->>Worker: Start AttorneyAgent (default)
    Worker-->>App: Agent ready
    
    App->>App: Configure microphone based on agent
    App-->>User: Connected & Ready
```

### Agent Switching Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Worker as Agent Worker
    participant Current as Current Agent
    participant New as New Agent
    
    App->>Worker: publishData("switch_to_click_to_talk")
    Worker->>Current: Aggressive interruption (3x)
    Worker->>Current: Disable audio input
    Worker->>Current: Clear session state
    Worker->>Current: Close session
    
    Worker->>New: Create ClickToTalkAgent
    Worker->>New: Configure manual turn detection
    Worker->>New: Start session
    
    Worker-->>App: publishData("active_agent:click_to_talk")
    App->>App: Disable microphone for CTT mode
    App-->>User: Agent switched successfully
```

### Click-to-Talk Pipeline

```mermaid
sequenceDiagram
    participant User as User
    participant App as Flutter App
    participant Worker as Agent Worker
    participant Agent as CTT Agent
    
    User->>App: Press "Start Recording"
    App->>Worker: publishData("interrupt_agent")
    App->>App: Enable microphone
    App->>Worker: publishData("start_turn")
    
    Worker->>Agent: session.interrupt()
    Worker->>Agent: session.clear_user_turn()
    Worker->>Agent: session.input.set_audio_enabled(true)
    
    Note over User,Agent: User speaks (audio streams to agent)
    
    User->>App: Press "Stop Recording"
    App->>App: Disable microphone
    App->>App: State = ReadyToSend
    
    User->>App: Press "Send"
    App->>Worker: publishData("end_turn")
    
    Worker->>Agent: session.input.set_audio_enabled(false)
    Worker->>Agent: session.commit_user_turn()
    
    Agent->>Agent: Process STT → LLM → TTS
    Agent-->>App: Response via data channel
    App-->>User: Display/Play response
```

### File Upload Pipeline

```mermaid
sequenceDiagram
    participant User as User
    participant App as Flutter App
    participant FS as FileService
    participant LKS as LiveKitService
    participant Worker as Agent Worker
    participant Agent as Current Agent
    
    User->>App: Select file
    App->>FS: pickSingleFileForAgent()
    FS->>FS: Validate size & type
    FS-->>App: AttachedFile
    
    App->>LKS: sendFileToAgent(bytes, name, ext)
    LKS->>LKS: Get MIME type
    
    alt streamBytes (preferred)
        LKS->>Worker: streamBytes(topic='files')
        LKS->>Worker: Write chunks (16KB each)
        LKS->>Worker: Close stream
    else publishData fallback
        LKS->>LKS: base64 encode
        LKS->>Worker: publishData(JSON file data)
    end
    
    Worker->>Agent: _file_received(reader, participant)
    Agent->>Agent: Process by MIME type
    Agent->>Agent: Extract text/content
    Agent->>Agent: Add to chat context
    Agent->>Agent: Generate analysis
    Agent-->>App: Response via data channel
    App-->>User: Display analysis
```

### Text Chat Flow

```mermaid
graph TD
    USER[User Types Message] --> CP[ChatProvider]
    CP --> DECISION{LiveKit Connected?}
    
    DECISION -->|Yes| LK_PATH[LiveKit Path]
    DECISION -->|No| GEMINI_PATH[Gemini Fallback]
    
    subgraph "LiveKit Path"
        LK_PATH --> LKS[LiveKitService]
        LKS --> |publishData| WORKER[Agent Worker]
        WORKER --> AGENT[Current Agent]
        AGENT --> STT_LLM[Skip STT → LLM → TTS]
        STT_LLM --> |Response| DATA_CHANNEL[Data Channel]
        DATA_CHANNEL --> CP_RESPONSE[ChatProvider.handleAgentResponse]
    end
    
    subgraph "Gemini Fallback"
        GEMINI_PATH --> CS[ChatService]
        CS --> GS[GeminiService]
        GS --> |HTTP API| GEMINI_API[Gemini API]
        GEMINI_API --> |Response| CS_RESPONSE[ChatService Response]
        CS_RESPONSE --> CP_RESPONSE
    end
    
    CP_RESPONSE --> UI[Update Chat UI]
```

## Agent Configuration Matrix

| Agent Type | Language | Mode | STT | LLM | TTS | Turn Detection |
|------------|----------|------|-----|-----|-----|----------------|
| AttorneyAgent | English | Continuous | Deepgram Nova-2 | Groq Llama3-8b | Azure Davis | VAD |
| ClickToTalkAgent | English | Manual | Deepgram Nova-2 | Groq Llama3-8b | Azure Onyx | Manual |
| ArabicAgent | Arabic | Continuous | Azure ar-SA/ar-EG | Groq allam-2-7b | Azure ar-OM-Abdullah | VAD |
| ArabicCTTAgent | Arabic | Manual | Azure ar-SA/ar-EG | Groq allam-2-7b | Azure ar-OM-Abdullah | Manual |

## Data Channel Communication

### Outbound Messages (App → Agent)

| Message | Purpose | Target Agents |
|---------|---------|---------------|
| `start_turn` | Begin click-to-talk recording | CTT, Arabic CTT |
| `end_turn` | Process recorded audio | CTT, Arabic CTT |
| `cancel_turn` | Cancel recording | CTT, Arabic CTT |
| `interrupt_agent` | Stop current agent speech | All |
| `switch_to_attorney` | Switch to continuous English | All |
| `switch_to_click_to_talk` | Switch to manual English | All |
| `switch_to_arabic` | Switch to continuous Arabic | All |
| `switch_to_arabic_click_to_talk` | Switch to manual Arabic | All |
| `chat:<text>` | Text message | All |
| `ping` | Keep-alive | All |

### Inbound Messages (Agent → App)

| Message Format | Purpose | UI Display |
|----------------|---------|------------|
| `active_agent:<type>` | Agent switch confirmation | 🤖 Active agent: {type} |
| `status_<info>` | System status | 🔔 Status: {info} |
| `session_<info>` | Session info | 🆔 {info} |
| Plain text | Agent response | Direct display |
| JSON with text field | Structured response | Extract and display text |

## File Processing Support

### Supported File Types

```mermaid
graph LR
    FILES[File Upload] --> DECISION{File Type}
    
    DECISION --> PDF[PDF Files]
    DECISION --> DOC[Word Documents]
    DECISION --> TXT[Text Files]
    DECISION --> IMG[Images]
    DECISION --> JSON[JSON Files]
    
    PDF --> PDF_PROC[PyPDF2 Extraction]
    DOC --> DOC_PROC[python-docx Extraction]
    TXT --> TXT_PROC[UTF-8 Decode]
    IMG --> IMG_PROC[Base64 + Vision Analysis]
    JSON --> JSON_PROC[Parse & Format]
    
    PDF_PROC --> ANALYSIS[Agent Analysis]
    DOC_PROC --> ANALYSIS
    TXT_PROC --> ANALYSIS
    IMG_PROC --> ANALYSIS
    JSON_PROC --> ANALYSIS
    
    ANALYSIS --> RESPONSE[Legal Analysis Response]
```

### File Size & Validation

- **Max Size**: 50MB (configurable in `FileTypeConstants.maxFileSize`)
- **Chunk Size**: 16KB for streaming uploads
- **Extensions**: pdf, doc, docx, txt, jpg, png, jpeg
- **Validation**: Size, extension, MIME type verification

## Deployment Architecture

### Process Types (Procfile)

```yaml
web: cd backend && uvicorn token_service.main:app --host 0.0.0.0 --port $PORT
worker: cd backend && python3 -m agent.agent start
```

### Environment Configuration

#### Frontend (.env)
```bash
TOKEN_ENDPOINT=http://localhost:8080/getToken  # Primary
LIVEKIT_SANDBOX_ID=your_sandbox_id            # Fallback
```

#### Backend (.env)
```bash
# Required: LiveKit Configuration
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=your_api_key_here
LIVEKIT_API_SECRET=your_api_secret_here
LIVEKIT_AGENT_NAME=agent-HAAKEEM

# AI Services
DEEPGRAM_API_KEY=your_deepgram_key
GROQ_API_KEY=your_groq_key
AZURE_SPEECH_KEY=your_azure_key
AZURE_SPEECH_REGION=your_azure_region
```

### Memory Optimization

```python
WorkerOptions(
    entrypoint_fnc=entrypoint,
    prewarm_fnc=prewarm,
    agent_name=agent_name,
    job_executor_type=JobExecutorType.THREAD,  # Thread-based
    num_idle_processes=0,                      # No idle processes
    concurrency=1,                             # Single worker
    concurrency_mode="threads"                 # Thread mode
)
```

## Performance Characteristics

### Latency Targets

| Operation | Target Latency | Notes |
|-----------|----------------|-------|
| Agent Switch | < 2 seconds | Includes session cleanup |
| CTT Start | < 200ms | Microphone enable + start_turn |
| CTT Process | < 5 seconds | Full STT → LLM → TTS pipeline |
| File Upload | < 10 seconds | Depends on file size |
| Text Response | < 3 seconds | LLM processing time |

### Resource Usage

- **Frontend**: Client-side STT for local feedback, minimal processing
- **Backend**: 
  - Token Service: Stateless, minimal memory
  - Agent Worker: Single-threaded, ~200-500MB RAM per session
  - Model Loading: Silero VAD preloaded, other models on-demand

## Security Considerations

### Authentication
- JWT tokens signed server-side with LiveKit credentials
- Client never sees API secrets
- Tokens include room-specific permissions

### Data Privacy
- Audio streams directly to LiveKit infrastructure
- No persistent storage of voice data
- File uploads processed in memory only
- Chat history stored locally in app only

### CORS Configuration
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Monitoring & Observability

### Health Checks
- Token Service: `GET /health` - API key validation, service status
- Agent Worker: Logging with structured events
- LiveKit Cloud: Built-in monitoring and metrics

### Key Metrics
- Connection success rate
- Agent switch completion time
- File processing success rate
- Audio quality metrics (from LiveKit)
- Response generation latency

### Logging Strategy
- **Frontend**: Debug prints for state changes and API calls
- **Backend**: Structured logging with correlation IDs
- **LiveKit**: Built-in WebRTC metrics and connection stats


*This architecture documentation covers the complete system design, data flows, and operational characteristics of the Voice Agent system as of the current implementation.*
