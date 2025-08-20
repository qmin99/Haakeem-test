import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from livekit import api

# Load environment variables first
BASE_DIR = Path(__file__).resolve().parents[1]  # This points to /backend/
load_dotenv(BASE_DIR / ".env", override=False)  # Load /backend/.env

# Environment variables
API_KEY = os.getenv("LIVEKIT_API_KEY")
API_SECRET = os.getenv("LIVEKIT_API_SECRET")
SERVER_URL = os.getenv("LIVEKIT_URL")
AGENT_NAME = os.getenv("LIVEKIT_AGENT_NAME", "agent-HAAKEEM")

if not (API_KEY and API_SECRET):
    raise RuntimeError("LIVEKIT_API_KEY/LIVEKIT_API_SECRET env vars must be set")

print(f"✓ Token service starting - LiveKit URL: {SERVER_URL}")
print(f"✓ Agent name: {AGENT_NAME}")
print(f"✓ BASE_DIR: {BASE_DIR}")

# FastAPI app
app = FastAPI(title="LiveKit Token Service", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Data models
class TokenRequest(BaseModel):
    room: str
    identity: str
    name: str | None = None

class TokenResponse(BaseModel):
    token: str
    serverUrl: str
    roomName: str
    participantName: str

class FlutterTokenRequest(BaseModel):
    room: str
    identity: str

def _build_token(room: str, identity: str, name: str | None = None) -> str:
    """Build LiveKit access token with agent dispatch"""
    at_builder = (
        api.AccessToken(API_KEY, API_SECRET)
        .with_identity(identity)
        .with_name(name or identity)
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=room,
                can_publish=True,
                can_subscribe=True,
            )
        )
    )

    # Dispatch the configured agent automatically into the room
    at_builder = at_builder.with_room_config(
        api.RoomConfiguration(
            agents=[
                api.RoomAgentDispatch(agent_name=AGENT_NAME)
            ]
        )
    )

    return at_builder.to_jwt()

@app.post("/getToken", response_model=TokenResponse)
def get_token(req: TokenRequest):
    """Generate LiveKit access token for the specified room and participant"""
    token = _build_token(req.room, req.identity, req.name)
    return TokenResponse(
        token=token,
        serverUrl=SERVER_URL or "",
        roomName=req.room,
        participantName=req.identity,
    )

@app.post("/")
def get_token_flutter(req: FlutterTokenRequest):
    """Generate LiveKit access token - Flutter app compatible endpoint"""
    token = _build_token(req.room, req.identity, req.identity)
    print(f"✓ Generated token for Flutter app - room '{req.room}', identity '{req.identity}', agent '{AGENT_NAME}'")
    
    return {
        "token": token,
        "serverUrl": SERVER_URL or "",
        "roomName": req.room,
        "participantName": req.identity,
        "participantToken": token  # Flutter expects this field name too
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "livekit-token-service", "agent_name": AGENT_NAME}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
