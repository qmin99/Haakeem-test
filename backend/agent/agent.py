import logging
import os
import certifi
import asyncio
import json
from pathlib import Path
from dotenv import load_dotenv

# Fix SSL certificate issues on macOS
os.environ['SSL_CERT_FILE'] = certifi.where()
os.environ['REQUESTS_CA_BUNDLE'] = certifi.where()
BASE_DIR = Path(__file__).resolve().parents[1]  # This points to /backend/

load_dotenv(BASE_DIR / ".env")  # Load /backend/.env

from livekit import rtc
from livekit.agents import AgentSession, JobContext, JobExecutorType, JobRequest, JobProcess, RoomIO, WorkerOptions, cli
from livekit.plugins import silero

# Load VAD model on main thread
VAD_MODEL = silero.VAD.load()

logger = logging.getLogger("multi-agent-ptt")
logger.setLevel(logging.INFO)

# Set up logging filter to suppress transcription warnings when room is closed
class TranscriptionWarningFilter(logging.Filter):
    """Filter to suppress transcription warnings when room connection is closed"""
    def filter(self, record):
        # Suppress specific transcription-related warnings that occur during cleanup
        if record.levelname == 'WARNING' and 'failed to publish transcription' in record.getMessage():
            return False
        if 'room closed' in record.getMessage().lower() and 'transcription' in record.getMessage().lower():
            return False
        if 'channel closed' in record.getMessage().lower() and 'transcription' in record.getMessage().lower():
            return False
        if 'engine is closed' in record.getMessage().lower():
            return False
        return True

# Apply the filter to the livekit.agents logger
livekit_logger = logging.getLogger("livekit.agents")
livekit_logger.addFilter(TranscriptionWarningFilter())

from .agents import AttorneyAgent, ClickToTalkAgent, ArabicAgent, ArabicClickToTalkAgent


# Agents implement their own file handlers and fallback methods


def prewarm(proc: JobProcess):
    """Preload models and initialize shared data"""
    # This function is called once when the worker starts up
    # Use it to preload any models or data that should be shared across requests
    logger.info("Prewarming agent - loading models...")

async def entrypoint(ctx: JobContext):
    """Main entrypoint following LiveKit push-to-talk example exactly"""
    
    # State variables to track current agent and session
    current_agent = None
    session = None
    room_io = None
    current_agent_type = "attorney"  # Start with attorney as the default
    is_switching = False
    byte_stream_handler_registered = False
    
    # Register byte stream handler for file uploads
    def _file_received_handler(reader, participant_info):
        """Handler for incoming byte streams"""
        logger.info("📄 Byte stream handler called: topic=%s, participant=%s", 
                   reader.info.topic, participant_info)
        
        # Check if current_agent is available
        if current_agent is None:
            logger.error("❌ No current_agent available to handle file upload")
            return
            
        # Create async task to handle the file
        async def handle_file_upload():
            try:
                await current_agent._file_received(reader, participant_info)
                logger.info("✅ File processing completed successfully")
            except Exception as e:
                logger.error(f"❌ Error in file processing task: {e}", exc_info=True)
        
        task = asyncio.create_task(handle_file_upload())
        # Optional: Track tasks if needed for cleanup
        # task.add_done_callback(lambda t: logger.info("📄 File processing task completed"))
    
    async def start_agent_session(agent_type: str):
        """Start or restart agent session with the specified agent type"""
        nonlocal current_agent, session, room_io, current_agent_type
        
        # CRITICAL: Ensure byte stream handler is registered only once
        def ensure_byte_stream_handler():
            nonlocal byte_stream_handler_registered
            try:
                if not byte_stream_handler_registered:
                    # Check if handler is already registered by inspecting room
                    existing_handlers = getattr(ctx.room, '_byte_stream_handlers', {})
                    if 'files' not in existing_handlers:
                        ctx.room.register_byte_stream_handler("files", _file_received_handler)
                        byte_stream_handler_registered = True
                        logger.info("📄 Registered byte stream handler for topic 'files'")
                    else:
                        byte_stream_handler_registered = True
                        logger.info("📄 Byte stream handler for 'files' already exists")
                    
                    # Log current registered topics for debugging
                    existing_handlers = getattr(ctx.room, '_byte_stream_handlers', {})
                    logger.info(f"📄 Currently registered byte stream topics: {list(existing_handlers.keys())}")
                else:
                    logger.info("📄 Byte stream handler already marked as registered")
            except ValueError as e:
                if "already set" in str(e):
                    byte_stream_handler_registered = True
                    logger.info("📄 Byte stream handler already exists (caught ValueError)")
                else:
                    logger.error(f"❌ ValueError registering byte stream handler: {e}")
            except Exception as e:
                logger.error(f"❌ Failed to register byte stream handler: {e}")
        
        ensure_byte_stream_handler()
        
        # Comprehensive session cleanup before starting new session
        await _cleanup_session(session, current_agent_type)
        session = None
        room_io = None
        
        # Create session with appropriate turn detection based on agent type
        if agent_type == "attorney":
            # Attorney uses simple VAD session - following standard LiveKit pattern
            session = AgentSession(
                vad=VAD_MODEL,  # Use pre-loaded VAD model from main thread
                min_endpointing_delay=3.3,      # Standard endpointing delay
                max_endpointing_delay=5.0,      # Standard max delay
                allow_interruptions=True,        # Enable interruptions
                discard_audio_if_uninterruptible=True,  # Prevent resume after interruption
            )
            current_agent = AttorneyAgent()
            logger.info("Starting AttorneyAgent session with standard VAD pattern")
        elif agent_type == "arabic":
            # Arabic agent uses continuous VAD session
            session = AgentSession(
                vad=VAD_MODEL,
                min_endpointing_delay=3.3,
                max_endpointing_delay=5.0,
                allow_interruptions=True,
                discard_audio_if_uninterruptible=True,
            )
            current_agent = ArabicAgent()
            logger.info("Starting ArabicAgent session with standard VAD pattern")
        elif agent_type == "arabic_click_to_talk":
            # Arabic click-to-talk: manual turn detection
            session = AgentSession(turn_detection="manual", discard_audio_if_uninterruptible=True)
            current_agent = ArabicClickToTalkAgent()
            logger.info("Starting ArabicClickToTalkAgent session")
        else:
            # English click-to-talk as default for unspecified ctt
            session = AgentSession(turn_detection="manual", discard_audio_if_uninterruptible=True)
            current_agent = ClickToTalkAgent()
            logger.info("Starting ClickToTalkAgent session")
        
        # Configure RoomIO 
        room_io = RoomIO(session, room=ctx.room)
        await room_io.start()
        
        await session.start(agent=current_agent)
        current_agent_type = agent_type
        
        # Note: Byte stream handler is registered globally, not per session
        
        logger.info(f"✅ {agent_type} agent session started successfully")
        logger.info(f"🎯 CURRENT ACTIVE AGENT TYPE: {current_agent_type}")
        logger.info(f"🎯 CURRENT AGENT CLASS: {current_agent.__class__.__name__}")
        # Broadcast active agent state to clients for synchronization
        # Also log for verification; Flutter client may not receive data messages from agent
        try:
            try:
                await ctx.room.local_participant.publish_data(
                    f"active_agent:{current_agent_type}".encode("utf-8")
                )
            except Exception:
                pass
            logger.info(f"📣 Broadcasted active agent: {current_agent_type}")
        except Exception as e:
            logger.warning(f"⚠️ Failed to broadcast active agent: {e}")
        
        # Configure audio input based on agent type
        if agent_type in ("click_to_talk", "arabic_click_to_talk"):
            # Disable input audio at the start - key for push-to-talk functionality
            session.input.set_audio_enabled(False)
            logger.info("CLICK-TO-TALK MODE: Audio disabled until start_turn")
        else:
            # Attorney agent uses continuous conversation
            session.input.set_audio_enabled(True)
            logger.info("CONTINUOUS MODE: Audio enabled for continuous conversation")
            
    async def _cleanup_session(session_to_cleanup, agent_type):
        """Comprehensive session cleanup to ensure clean agent switching"""
        if not session_to_cleanup:
            return
            
        try:
            logger.info(f"🔄 Starting comprehensive cleanup for {agent_type} agent...")
            
            # CRITICAL: Extra aggressive cleanup for continuous agents with VAD (attorney, arabic)
            if agent_type in ("attorney", "arabic"):
                logger.info("🔄 Extra aggressive cleanup for continuous agent with VAD...")
                
                # First, disable audio input to stop VAD processing immediately
                try:
                    session_to_cleanup.input.set_audio_enabled(False)
                    logger.info("🛑 DISABLED continuous agent audio input before cleanup")
                    await asyncio.sleep(0.15)  # Allow VAD to process the disable
                except Exception as e:
                    logger.warning(f"Failed to disable audio input: {e}")

                # Clear any partial user turn if available
                try:
                    if hasattr(session_to_cleanup, "clear_user_turn"):
                        session_to_cleanup.clear_user_turn()
                        logger.info("🛑 CLEARED user turn state for continuous agent")
                except Exception as e:
                    logger.warning(f"Failed to clear user turn: {e}")
            
            # CRITICAL: Triple aggressive interrupt calls to ensure complete stop
            for i in range(3):
                try:
                    session_to_cleanup.interrupt()
                    logger.info(f"🛑 FORCED session interrupt #{i+1}")
                    await asyncio.sleep(0.1)  # Wait between interrupts
                except Exception as e:
                    logger.warning(f"Interrupt #{i+1} failed: {e}")
            
            # Clear any pending response states
            if hasattr(session_to_cleanup, '_current_response'):
                session_to_cleanup._current_response = None
                logger.info("🛑 CLEARED pending response state")
            
            # Clear output buffer and stop TTS
            if hasattr(session_to_cleanup, 'output'):
                try:
                    if hasattr(session_to_cleanup.output, 'clear'):
                        session_to_cleanup.output.clear()
                        logger.info("🛑 CLEARED output buffer")
                    if hasattr(session_to_cleanup.output, 'stop'):
                        session_to_cleanup.output.stop()
                        logger.info("🛑 FORCED TTS output stop")
                except Exception as e:
                    logger.warning(f"Output cleanup failed: {e}")
            
            # Clear audio pipeline if available
            if hasattr(session_to_cleanup, '_audio_pipeline'):
                try:
                    session_to_cleanup._audio_pipeline.clear()
                    logger.info("🛑 CLEARED audio pipeline")
                except Exception as e:
                    logger.warning(f"Audio pipeline cleanup failed: {e}")
            
            # Wait for cleanup to fully complete based on agent type
            cleanup_delay = 0.4 if agent_type in ("attorney", "arabic") else 0.2
            await asyncio.sleep(cleanup_delay)
            logger.info(f"🛑 Waited {cleanup_delay}s for {agent_type} agent cleanup to complete")
            
            # Close the session properly
            await session_to_cleanup.close()
            logger.info(f"✅ {agent_type} agent session successfully cleaned up and closed")
            
        except Exception as e:
            logger.error(f"❌ Session cleanup error for {agent_type}: {e}")
            # Force continue despite cleanup errors
    
    # Register the byte stream handler ONCE at the beginning
    try:
        if not byte_stream_handler_registered:
            ctx.room.register_byte_stream_handler("files", _file_received_handler)
            byte_stream_handler_registered = True
            logger.info("📄 Initial byte stream handler registered for topic 'files'")
        else:
            logger.info("📄 Byte stream handler already registered")
    except ValueError as e:
        if "already set" in str(e):
            byte_stream_handler_registered = True
            logger.info("📄 Byte stream handler was already registered (caught ValueError)")
        else:
            logger.error(f"❌ ValueError during initial registration: {e}")
    except Exception as e:
        logger.error(f"❌ Error during initial byte stream handler registration: {e}")
    
    # Start with attorney agent by default and broadcast state
    await start_agent_session("attorney")
    logger.info("✅ Initial attorney agent session started")

    @ctx.room.local_participant.register_rpc_method("start_turn")
    async def start_turn(data: rtc.RpcInvocationData):
        """Called when user presses the Start Recording button"""
        if current_agent_type in ("click_to_talk", "arabic_click_to_talk") and session:
            logger.info(f"🎤 start_turn called by {data.caller_identity}")
            
            # CORRECT LiveKit pattern for manual turn control
            session.interrupt()       # Stop any current agent speech (permanent)
            session.clear_user_turn() # Clear any previous input
            
            # Listen to the caller if multi-user
            room_io.set_participant(data.caller_identity)
            session.input.set_audio_enabled(True)  # Start listening
            
            logger.info("✅ Click-to-talk recording started")
            logger.info("CLICK-TO-TALK: Audio enabled, user can speak")

    @ctx.room.local_participant.register_rpc_method("end_turn")
    async def end_turn(data: rtc.RpcInvocationData):
        """Called when user presses the End Recording button"""
        if current_agent_type in ("click_to_talk", "arabic_click_to_talk") and session:
            logger.info(f"🛑 end_turn called by {data.caller_identity}")
            
            # CORRECT LiveKit pattern for manual turn control
            session.input.set_audio_enabled(False)  # Stop listening
            session.commit_user_turn(               # Process input and generate response
                transcript_timeout=3.0,  # Reduced timeout for faster processing
            )
            
            logger.info("✅ Click-to-talk processing user input...")

    @ctx.room.local_participant.register_rpc_method("cancel_turn")
    async def cancel_turn(data: rtc.RpcInvocationData):
        """Called when user cancels their recording"""
        if current_agent_type in ("click_to_talk", "arabic_click_to_talk") and session:
            logger.info(f"❌ cancel_turn called by {data.caller_identity}")
            
            # CORRECT LiveKit pattern for manual turn control
            session.input.set_audio_enabled(False)  # Stop listening
            session.clear_user_turn()               # Discard the input
            
            logger.info("✅ Click-to-talk turn cancelled")

    # Create a data handler that has access to the session variables
    def create_data_handler():
        async def handle_data_packet(data):
            """Handle incoming data packets from participants"""
            nonlocal current_agent, session, room_io, current_agent_type, is_switching
            try:
                logger.info(f"📩 RAW DATA RECEIVED: {data}")
                
                # Try different ways to decode the message
                message = None
                participant_identity = "unknown"
                
                # Method 1: Direct data access
                if hasattr(data, 'data'):
                    message = data.data.decode('utf-8')
                    if hasattr(data, 'participant') and data.participant:
                        participant_identity = data.participant.identity
                # Method 2: Event-style access
                elif hasattr(data, 'payload'):
                    message = data.payload.decode('utf-8')
                # Method 3: Direct bytes
                elif isinstance(data, bytes):
                    message = data.decode('utf-8')
                
                if not message:
                    logger.warning(f"❌ Could not decode message from data: {type(data)}")
                    return
                
                logger.info(f"📩 Decoded message from {participant_identity}: '{message}'")
                logger.info(f"🎯 Processing with current_agent_type: {current_agent_type}")
                logger.info(f"🎯 Current agent instance: {current_agent.__class__.__name__ if current_agent else 'None'}")
                logger.info(f"🎯 Session exists: {session is not None}")
                logger.info(f"🎯 Is switching: {is_switching}")
                
                # Process the message based on content
                if message == "start_turn":
                    logger.info(f"🔄 Processing start_turn command... (current agent: {current_agent_type})")
                    logger.info(f"🎯 Current session agent class: {current_agent.__class__.__name__ if current_agent else 'None'}")
                    if current_agent_type in ("click_to_talk", "arabic_click_to_talk") and session:
                        logger.info("🎤 Starting click-to-talk recording...")
                        
                        # CORRECT LiveKit pattern for manual turn control
                        session.interrupt()       # Stop any current agent speech (permanent)
                        session.clear_user_turn() # Clear any previous input
                        session.input.set_audio_enabled(True)  # Start listening
                        
                        logger.info("✅ Click-to-talk recording started")
                
                elif message == "end_turn":
                    logger.info(f"🔄 Processing end_turn command... (current agent: {current_agent_type})")
                    logger.info(f"🎯 Current session agent class: {current_agent.__class__.__name__ if current_agent else 'None'}")
                    if current_agent_type in ("click_to_talk", "arabic_click_to_talk") and session:
                        logger.info("🛑 Ending click-to-talk recording and processing...")
                        # CORRECT LiveKit pattern for manual turn control
                        session.input.set_audio_enabled(False)  # Stop listening
                        session.commit_user_turn(transcript_timeout=3.0)
                        logger.info("✅ Click-to-talk processing user input...")
                
                elif message == "cancel_turn":
                    logger.info("🔄 Processing cancel_turn command...")
                    if current_agent_type in ("click_to_talk", "arabic_click_to_talk") and session:
                        logger.info("❌ Canceling click-to-talk...")
                        
                        # CORRECT LiveKit pattern for manual turn control
                        session.input.set_audio_enabled(False)  # Stop listening
                        session.clear_user_turn()               # Discard the input
                        
                        logger.info("✅ Click-to-talk cancelled")
                
                elif message == "switch_to_attorney":
                    logger.info(f"🔄 Switching to attorney agent... (current: {current_agent_type})")
                    if is_switching:
                        logger.info("⏳ Switch already in progress, ignoring request")
                        return
                    is_switching = True
                    
                    try:
                        # Clean immediate interruption before switching
                        if session:
                            if current_agent_type in ("attorney", "arabic"):
                                try:
                                    session.input.set_audio_enabled(False)
                                except Exception:
                                    pass
                            session.interrupt()
                            logger.info("🛑 Pre-switch interrupt for immediate stop")
                            await asyncio.sleep(0.15 if current_agent_type in ("attorney", "arabic") else 0.1)
                        
                        await start_agent_session("attorney")
                        logger.info(f"✅ Successfully switched to attorney agent (now: {current_agent_type})")
                    except Exception as e:
                        logger.error(f"❌ Failed to switch to attorney agent: {e}")
                        logger.error(f"Error details: {type(e).__name__}: {str(e)}")
                        # Attempt recovery by ensuring we have a working session
                        try:
                            await start_agent_session("attorney")  # Retry once
                            logger.info(f"✅ Recovery successful - attorney agent started (now: {current_agent_type})")
                        except Exception as recovery_error:
                            logger.error(f"❌ Recovery failed: {recovery_error}")
                    finally:
                        is_switching = False
                
                elif message == "switch_to_click_to_talk":
                    logger.info(f"🔄 Switching to click-to-talk agent... (current: {current_agent_type})")
                    if is_switching:
                        logger.info("⏳ Switch already in progress, ignoring request")
                        return
                    is_switching = True
                    
                    try:
                        # Clean immediate interruption before switching
                        if session:
                            # Aggressive stop for continuous agents
                            if current_agent_type in ("attorney", "arabic"):
                                try:
                                    session.input.set_audio_enabled(False)
                                except Exception:
                                    pass
                            session.interrupt()
                            logger.info("🛑 Pre-switch interrupt for immediate stop")
                            await asyncio.sleep(0.15 if current_agent_type in ("attorney", "arabic") else 0.1)
                        
                        await start_agent_session("click_to_talk")
                        logger.info(f"✅ Successfully switched to click-to-talk agent (now: {current_agent_type})")
                    except Exception as e:
                        logger.error(f"❌ Failed to switch to click-to-talk agent: {e}")
                        logger.error(f"Error details: {type(e).__name__}: {str(e)}")
                        # Attempt recovery by ensuring we have a working session
                        try:
                            await start_agent_session("click_to_talk")  # Retry once
                            logger.info(f"✅ Recovery successful - click-to-talk agent started (now: {current_agent_type})")
                        except Exception as recovery_error:
                            logger.error(f"❌ Recovery failed: {recovery_error}")
                    finally:
                        is_switching = False
                
                elif message == "switch_to_arabic":
                    logger.info(f"🔄 Switching to arabic agent... (current: {current_agent_type})")
                    if is_switching:
                        logger.info("⏳ Switch already in progress, ignoring request")
                        return
                    is_switching = True
                    try:
                        # Clean immediate interruption before switching
                        if session:
                            if current_agent_type in ("attorney", "arabic"):
                                try:
                                    session.input.set_audio_enabled(False)
                                except Exception:
                                    pass
                            session.interrupt()
                            logger.info("🛑 Pre-switch interrupt for immediate stop")
                            await asyncio.sleep(0.15 if current_agent_type in ("attorney", "arabic") else 0.1)

                        await start_agent_session("arabic")
                        logger.info(f"✅ Successfully switched to arabic agent (now: {current_agent_type})")
                    except Exception as e:
                        logger.error(f"❌ Failed to switch to arabic agent: {e}")
                    finally:
                        is_switching = False

                elif message == "switch_to_arabic_click_to_talk":
                    logger.info(f"🔄 Switching to arabic click-to-talk agent... (current: {current_agent_type})")
                    if is_switching:
                        logger.info("⏳ Switch already in progress, ignoring request")
                        return
                    is_switching = True
                    try:
                        if session:
                            if current_agent_type in ("attorney", "arabic"):
                                try:
                                    session.input.set_audio_enabled(False)
                                except Exception:
                                    pass
                            session.interrupt()
                            logger.info("🛑 Pre-switch interrupt for immediate stop")
                            await asyncio.sleep(0.15 if current_agent_type in ("attorney", "arabic") else 0.1)

                        await start_agent_session("arabic_click_to_talk")
                        logger.info(f"✅ Successfully switched to arabic click-to-talk agent (now: {current_agent_type})")
                    except Exception as e:
                        logger.error(f"❌ Failed to switch to arabic click-to-talk agent: {e}")
                    finally:
                        is_switching = False
                
                elif message == "interrupt_agent":
                    logger.info("🔄 Processing interrupt_agent command...")
                    if session:
                        async def do_aggressive_interrupt():
                            # CRITICAL: Aggressive triple interrupt for immediate stop
                            session.interrupt()
                            logger.info("🛑 FORCED agent interruption #1 via user command")
                            
                            # Brief pause to let first interrupt register
                            await asyncio.sleep(0.05)
                            
                            session.interrupt()
                            logger.info("🛑 FORCED agent interruption #2 - ensuring complete stop")
                            
                            # Another brief pause
                            await asyncio.sleep(0.05)
                            
                            session.interrupt()
                            logger.info("🛑 FORCED agent interruption #3 - triple interrupt for complete stop")
                            
                            # Also clear any pending TTS if possible
                            if hasattr(session, 'output') and hasattr(session.output, 'clear'):
                                try:
                                    session.output.clear()
                                    logger.info("🛑 CLEARED output buffer during interrupt")
                                except:
                                    pass
                                    
                            # Clear any audio pipeline if available
                            if hasattr(session, '_audio_pipeline'):
                                try:
                                    session._audio_pipeline.clear()
                                    logger.info("🛑 CLEARED audio pipeline during interrupt")
                                except:
                                    pass
                                    
                            # Force stop any ongoing TTS synthesis
                            if hasattr(session, 'output') and hasattr(session.output, 'stop'):
                                try:
                                    session.output.stop()
                                    logger.info("🛑 FORCED TTS output stop during interrupt")
                                except:
                                    pass
                        
                        # Run the interrupt asynchronously
                        loop = asyncio.get_event_loop()
                        loop.create_task(do_aggressive_interrupt())
                    else:
                        logger.warning("⚠️ No active session to interrupt")
                
                elif message.startswith("chat:"):
                    chat_text = message[5:]
                    logger.info(f"Chat message: {chat_text}")
                    # Normalize brand name variants for English agents before LLM
                    try:
                        import re
                        def normalize_brand(text: str) -> str:
                            pattern = re.compile(r"(?i)(h\s*a\s*a\s*k\s*(?:i|e)?\s*e\s*e\s*m|ha+\s*k[iy]e?m|hakim|hakeem|haakeem|hakem|akim)")
                            return pattern.sub("HAAKEEM", text)

                        normalized = normalize_brand(chat_text)
                        if current_agent and session:
                            chat_ctx = current_agent.chat_ctx.copy()
                            chat_ctx.add_message(role="user", content=normalized)
                            await current_agent.update_chat_ctx(chat_ctx)
                            await session.generate_reply(
                                instructions="Please respond helpfully and concisely.",
                                allow_interruptions=True,
                            )
                    except Exception as e:
                        logger.error(f"❌ Failed to process chat message: {e}")
                else:
                    # Try to parse as JSON for file upload fallback
                    try:
                        file_data = json.loads(message)
                        if isinstance(file_data, dict) and file_data.get('type') == 'file_upload':
                            logger.info("📄 Received file upload via publishData fallback")
                            
                            # Process the base64 encoded file
                            async def process_file_upload():
                                try:
                                    import base64
                                    file_bytes = base64.b64decode(file_data.get('data', ''))
                                    file_name = file_data.get('fileName', 'unknown.txt')
                                    mime_type = file_data.get('mimeType', 'application/octet-stream')
                                    
                                    logger.info(f"📄 Processing file: {file_name} ({len(file_bytes)} bytes, {mime_type})")
                                    
                                    # Create a mock stream info object
                                    class MockStreamInfo:
                                        def __init__(self, name, mime_type, size):
                                            self.name = name
                                            self.mime_type = mime_type
                                            self.size = size
                                            self.topic = 'files'
                                    
                                    stream_info = MockStreamInfo(file_name, mime_type, len(file_bytes))
                                    
                                    # Process using the same logic as byte streams
                                    if current_agent:
                                        await current_agent._file_received_fallback(file_bytes, stream_info, participant_identity)
                                    else:
                                        logger.warning("📄 No active agent to handle file upload")
                                        
                                except Exception as e:
                                    logger.error(f"❌ Error processing file upload fallback: {e}")
                            
                            loop = asyncio.get_event_loop()
                            loop.create_task(process_file_upload())
                        else:
                            logger.warning(f"❓ Unknown command: '{message}'")
                    except json.JSONDecodeError:
                        logger.warning(f"❓ Unknown command: '{message}'")
            except Exception as e:
                logger.error(f"❌ Error processing data: {e}")
                logger.error(f"Data type: {type(data)}")
                if hasattr(data, '__dict__'):
                    logger.error(f"Data attributes: {data.__dict__}")
        
        return handle_data_packet



    # Byte stream handler is already registered above
    # Note: ctx.room.sid is async, so we'll get it properly
    try:
        room_sid = await ctx.room.sid() if hasattr(ctx.room, 'sid') else 'unknown'
        logger.info("📄 Room ID: %s", room_sid)
    except:
        logger.info("📄 Room ID: unable to fetch")

    # Register the data handler - fix async callback issue
    data_handler = create_data_handler()
    
    # Create a synchronous wrapper for the async data handler
    def sync_data_handler(data):
        """Synchronous wrapper that creates a task for the async handler"""
        loop = asyncio.get_event_loop()
        loop.create_task(data_handler(data))
    
    ctx.room.on("data_received", sync_data_handler)
    logger.info("✅ Data handler registered successfully (with async wrapper)")

async def handle_request(request: JobRequest) -> None:
    """Handle incoming job requests"""
    # Use env-configured identity so local worker can be uniquely targeted
    agent_identity = os.getenv("LIVEKIT_AGENT_NAME", "agent-HAAKEEM")
    await request.accept(
        identity=agent_identity,  # Must start with "agent-" for UI recognition
        name="HAAKEEM Assistant",  # Clear name for UI display
        # This attribute tells the frontend we support push-to-talk
        attributes={"push-to-talk": "1", "multi-agent": "1"},
    )

if __name__ == "__main__":
    # Use env-configured agent name so local worker can be uniquely targeted
    agent_name = os.getenv("LIVEKIT_AGENT_NAME", "agent-HAAKEEM")
    cli.run_app(WorkerOptions(
        entrypoint_fnc=entrypoint,
        prewarm_fnc=prewarm,
        request_fnc=handle_request,
        agent_name=agent_name,
        # Memory-efficient settings for deployment
        job_executor_type=JobExecutorType.THREAD,
        num_idle_processes=0
    ))
