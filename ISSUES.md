# Issues & Fixes (voice-agent)

## Some of the Issues I faced & How I Fixed Them

### Cartesia TTS & OpenAI LLM 402 Payment Required
- **Problem:** Cartesia API key returned 402 (Payment Required).
- **Fix:** Switched to Azure Speech TTS (free tier) and updated `.env.local` and agent config. and groq LLM

### No connection from Flutter at all 
- **Problem:** Sandbox API returned "invalid name" for all room/participant names. Room/participant names too long or invalid; sandbox ID had invalid characters.
- **Fix:** Bypassed sandbox, used direct LiveKit credentials and token server. Shortened names, cleaned up `.env`. Basically, played with @token_service.dart

### New API not resolved
- **Problem:** Groq and Azure not resolved
- **Fix:** proper requirements.txt installment

### SSL Certificates FIXED with a proper path in .env

### CORS Error (Flutter web → token server)
- **Problem:** Browser blocked token fetch due to CORS.
- **Fix:** Added CORS middleware to FastAPI token server.

### No connection from flutter with the agent
- **Problem:** Agent worked in console but not in room; turn detector crashed due to NumPy/SciPy version mismatch. Agent only joined when run in dev/console mode, not as a worker.
- **Fix:** 
  - Pinned `numpy<2.0.0`, `scipy<1.12.0`, `scikit-learn<1.4.0` in requirements.
  - Added agent dispatch to token server (`RoomConfiguration` with `agent_name="assistant"`).
  - Started agent with `python -m agent.agent start`.

### Dependency Conflicts (pip warnings)
- **Problem:** pip showed warnings about protobuf, numpy, etc.
- **Fix:** Used a clean venv for backend, only installed needed packages.

### Project Structure Messy
- **Problem:** Mixed backend/frontend files, hard to manage.
- **Fix:** organized the structure as of Jul 15, 25

---

## MULTI-AGENT SYSTEM ISSUES (July 29-30, 2025)

### Major Refactor: Single Agent → Multi-Agent Architecture
- **Problem:** Original system had one agent with three modes, causing complexity and poor UX.
- **Fix:** Complete refactor to two distinct agents in single worker:
  - `AttorneyAgent`: Continuous conversation with VAD
  - `ClickToTalkAgent`: Manual control for long-form questions
- **Result:** Clean separation of concerns, better user experience

### Agent Name & Identity Issues
- **Problem:** `TypeError: JobContext.connect() got an unexpected keyword argument 'identity'`
- **Fix:** Removed `identity` and `attributes` parameters from `ctx.connect()` as they're not accepted by `JobContext.connect()`
- **Problem:** Agent not showing in LiveKit UI
- **Fix:** Changed agent name to `"agent-HAAKEEM"` (must start with "agent-" for UI recognition)

### Frontend-Backend Communication Issues
- **Problem:** `Error: The method 'performRPC' isn't defined for the class 'LocalParticipant'`
- **Fix:** Reverted from `performRPC` (incorrect documentation) to `publishData` (data messages) for control commands
- **Problem:** Agent switching glitchy and unreliable
- **Fix:** Implemented `_isAgentSwitching` flag and proper async handling with `asyncio.create_task`

### Plugin Loading & Threading Issues
- **Problem:** `RuntimeError: Plugins must be registered on the main thread`
- **Fix:** Moved `VAD_MODEL = silero.VAD.load()` to top-level of `agent.py` to ensure main thread loading
- **Problem:** `AttributeError: Can't get attribute 'prewarm' on <module '__mp_main__'`
- **Fix:** Added `prewarm_fnc=prewarm` to `WorkerOptions` in `cli.run_app`

### Agent Session Configuration Issues
- **Problem:** `TypeError: AgentSession.__init__() got an unexpected keyword argument 'max_buffered_silence'`
- **Fix:** Removed unsupported parameters, used correct LiveKit AgentSession API
- **Problem:** `AgentSession.generate_reply() got an unexpected keyword argument 'interrupt_speech_duration'`
- **Fix:** Removed unsupported `interrupt_speech_duration` parameter

### Click-to-Talk Agent Responding Prematurely
- **Problem:** Agent responding while user still speaking, before clicking "Send to HAAKEEM"
- **Fix:** 
  - Updated `ClickToTalkAgent.on_user_turn_completed` to raise `StopResponse()` if still recording
  - Corrected frontend flow: `start_turn` on "Start Speaking", `end_turn` on "Send to HAAKEEM"
  - Added `discard_audio_if_uninterruptible=True` to prevent premature processing

### Attorney Agent Not Responding or Hearing
- **Problem:** Attorney agent not responding to user input or not detecting speech
- **Fix:** 
  - Changed from `turn_detection="vad"` to using `vad=VAD_MODEL` directly
  - Added proper `min_endpointing_delay=3.3` and `max_endpointing_delay=5.0` for semantic understanding
  - Ensured `allow_interruptions=True` for proper VAD behavior

### Agent Resuming After Interruption (CRITICAL ISSUE)
- **Problem:** Agent continues speaking after being interrupted, doesn't permanently stop
- **Fix:** 
  - **Multiple Interrupt Calls**: `session.interrupt()` called twice for complete stop
  - **Buffer Clearing**: Added `discard_audio_if_uninterruptible=True` to both agents
  - **Output Buffer Clearing**: `session.output.clear()` when available
  - **State Management**: Clear pending response states and TTS buffers
  - **Aggressive Interruption**: Added `interrupt_agent` command for manual force-stop

### Transcription Publishing Errors (Persistent)
- **Problem:** `PublishTranscriptionError: failed to send transcription, room closed: channel closed`
- **Fix:** 
  - **Logging Filter**: Created `TranscriptionWarningFilter` to suppress warnings when room is closed
  - **Connection State Check**: Used correct `rtc.ConnectionState.CONN_CONNECTED` enum
  - **Error Suppression**: Filtered out "room closed", "channel closed", "engine is closed" errors
  - **Clean Logs**: Applied filter to `livekit.agents` logger

### Connection State Enum Issues
- **Problem:** `Enum ConnectionState has no value defined for name 'CONNECTED'`
- **Fix:** Changed from `CONNECTED` to `CONN_CONNECTED` (correct LiveKit enum value)

### Text Writer NoneType Errors
- **Problem:** `AttributeError: 'NoneType' object has no attribute 'write'`
- **Fix:** Removed complex method wrapping approach, used simple logging filter instead

### Agent Welcome Messages
- **Problem:** Agents not providing initial greetings when switched to
- **Fix:** Added `on_enter()` methods to both agents with welcome messages:
  ```python
  async def on_enter(self):
      await self.session.generate_reply(
          instructions="Hello! I'm HAAKEEM, your AI legal assistant. How can I assist you today?",
          allow_interruptions=True
      )
  ```

### Voice Configuration Issues
- **Problem:** Generic voice configuration not optimal for different use cases
- **Fix:** 
  - **AttorneyAgent**: `en-US-DavisNeural` (professional male voice)
  - **ClickToTalkAgent**: `en-US-OnyxTurboMultilingualNeural` (fast, clear voice)

### Memory Management for Production
- **Problem:** Multiple idle processes consuming memory on Heroku Basic dyno
- **Fix:** Added production-optimized `WorkerOptions`:
  ```python
  WorkerOptions(
      concurrency=1,
      concurrency_mode='threads',
      num_idle_processes=0,
      job_executor_type=JobExecutorType.THREAD,
  )
  ```

### Frontend State Management Issues
- **Problem:** Microphone state not properly managed during agent switches
- **Fix:** 
  - Attorney agent: microphone enabled for continuous listening
  - Click-to-talk agent: microphone disabled, controlled by buttons
  - Proper state transitions in `selectAgent()` method

### Data Message Handler Scope Issues
- **Problem:** `on_data_received` couldn't access `session`, `current_agent_type`, `room_io` from `entrypoint` scope
- **Fix:** Changed to nested function `handle_data_packet` within `create_data_handler` to capture proper scope

### Agent Response Generation Issues
- **Problem:** Agents not generating responses after user input
- **Fix:** Added explicit `await self.session.generate_reply()` calls in `on_user_turn_completed` methods

### Turn Detection Timeout Issues
- **Problem:** Click-to-talk agent taking too long to respond
- **Fix:** Reduced `transcript_timeout` from 15.0s to 3.0s for faster responses

---

## AGENT SWITCHING ISSUES (August 1st & 2nd Week, 2025)

### Backend Agent Switching Not Working
- **Problem:** Agent switching commands from frontend not being processed by backend. Backend logs showed no agent switch processing despite frontend sending commands.
- **Root Cause:** Two critical issues:
  1. **Async Callback Registration Error**: Backend was trying to register an async function directly with `.on()` which doesn't support async callbacks
  2. **Byte Stream Handler Duplication**: Multiple attempts to register the same byte stream handler causing `ValueError: byte stream handler for topic 'files' already set`

### Async Callback Registration Error
- **Problem:** `ValueError: Cannot register an async callback with .on(). Use asyncio.create_task within your synchronous callback instead.`
- **Fix:** Created a synchronous wrapper that creates async tasks:
  ```python
  def sync_data_handler(data):
      """Synchronous wrapper that creates a task for the async handler"""
      import asyncio
      loop = asyncio.get_event_loop()
      loop.create_task(data_handler(data))
  
  ctx.room.on("data_received", sync_data_handler)
  ```

### Byte Stream Handler Duplication Error
- **Problem:** `ValueError: byte stream handler for topic 'files' already set` causing backend crashes
- **Fix:** Added `byte_stream_handler_registered` flag to prevent duplicate registration:
  ```python
  def ensure_byte_stream_handler():
      nonlocal byte_stream_handler_registered
      if not byte_stream_handler_registered:
          # Only register if not already registered
          ctx.room.register_byte_stream_handler("files", _file_received_handler)
          byte_stream_handler_registered = True
  ```

### Room.sid Coroutine Warning
- **Problem:** `RuntimeWarning: coroutine 'Room.sid' was never awaited` - `ctx.room.sid` is a coroutine that wasn't being awaited properly
- **Fix:** Properly await the coroutine:
  ```python
  room_sid = await ctx.room.sid() if hasattr(ctx.room, 'sid') else 'unknown'
  ```

### Agent Default Mismatch
- **Problem:** Backend was starting with `click_to_talk` agent by default, but frontend expected `attorney` agent as default, causing confusion
- **Fix:** Synchronized both frontend and backend to start with `attorney` agent as default

### Frontend Agent Switch Optimization
- **Problem:** Frontend was sending unnecessary agent switch commands and had redundant interrupt calls
- **Fix:** 
  - Removed redundant interrupt calls in click-to-talk flow
  - Added proper delays for backend processing
  - Improved agent switch timing based on agent type
  - Skip initial agent switch if backend already starts with attorney (default)

### Enhanced Debugging and Logging
- **Problem:** Insufficient logging to debug agent switching issues
- **Fix:** Added comprehensive logging for:
  - Current agent type and session state
  - Switching state and message processing
  - Byte stream handler registration status
  - Data message decoding and processing

### Result
- **Before:** Agent switching appeared to work in UI but backend remained on attorney agent
- **After:** Proper agent switching with backend processing all commands correctly
- **Logs now show:** `🔄 Switching to click-to-talk agent... (current: attorney)` → `✅ Successfully switched to click-to-talk agent (now: click_to_talk)`

---

## PRODUCTION DEPLOYMENT ISSUES

### LiveKit API Credentials Missing
- **Problem:** `ConnectError: engine: signal failure: failed to retrieve region info`
- **Fix:** Created `backend/.env` template and instructed user to populate with actual LiveKit API Key, API Secret, and Server URL

### Environment Variable Loading
- **Problem:** LiveKit environment variables not loaded properly
- **Fix:** Added `dotenv.load_dotenv()` before reading LiveKit env vars in `token_service/main.py`

---

## CURRENT STATUS

### ✅ RESOLVED ISSUES
- Multi-agent architecture fully functional
- Agent switching working smoothly
- Click-to-talk manual control implemented
- Attorney agent VAD and interruption working
- Transcription error suppression implemented
- Production deployment configuration optimized
- All communication issues resolved
- **Backend async callback registration fixed**
- **Byte stream handler duplication errors resolved**
- **Agent switching commands now properly processed**
- **Frontend-backend agent synchronization working**

---

## DEPLOYMENT CHECKLIST

- [x] Set up `.env` files in `backend/` and `app/` with proper credentials
- [x] Deploy token server to public endpoint for production
- [x] Update `TOKEN_ENDPOINT` in `app/.env` for production
- [x] Ensure LiveKit server is running and accessible
- [x] Test multi-agent switching functionality
- [x] Verify click-to-talk manual control
- [x] Confirm attorney agent VAD and interruption behavior
- [x] Check transcription error suppression
- [x] Monitor memory usage on production dynos


### Local Agent Connection Issues
- **Problem:** Flutter app connected to Heroku agent instead of local
- **Fix:** 
  - Set `LIVEKIT_AGENT_NAME=agent-HAAKEEM-local` in backend/.env
  - Ensure token service dispatches correct agent name
  - Fixed missing trailing slash in `TOKEN_ENDPOINT`
  - Added proper worker process management

### Environment Variable Loading Order
- **Problem:** LiveKit credentials not loaded before agent initialization
- **Fix:** 
  - Added `dotenv.load_dotenv(BASE_DIR / ".env")` 
  - Verified loading sequence in both agent and token service

  