#!/usr/bin/env python3
"""
Tactical Airsoft Map - Authoritative WebSocket Server
Real-time tactical coordination server for airsoft games
"""

import asyncio
import json
import uuid
import time
import logging
import qrcode
import io
import base64
from datetime import datetime, timedelta
from typing import Dict, List, Set, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum
import websockets
from websockets.server import WebSocketServerProtocol
import argparse
from collections import defaultdict
import traceback

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Constants
UPDATE_RATE = 5  # Hz
POSITION_UPDATE_THRESHOLD = 2.0  # meters
INACTIVE_TIMEOUT = 300  # seconds
MAX_MESSAGE_SIZE = 1024 * 1024  # 1MB
DEFAULT_PORT = 8765

# Enums
class ConnectionStatus(str, Enum):
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    INACTIVE = "inactive"

class MessageType(str, Enum):
    AUTH = "auth"
    AUTH_RESPONSE = "auth_response"
    POSITION_UPDATE = "position_update"
    STATE_DELTA = "state_delta"
    STATE_SNAPSHOT = "state_snapshot"
    CHAT = "chat"
    ALERT = "alert"
    MARKER = "marker"
    TEAM_UPDATE = "team_update"
    ERROR = "error"
    PING = "ping"
    PONG = "pong"

class Visibility(str, Enum):
    TEAM = "team"
    ALL = "all"

class AlertType(str, Enum):
    CONTACT = "contact"
    DANGER = "danger"
    RALLY = "rally"
    HELP = "help"

class MarkerType(str, Enum):
    PIN = "pin"
    AREA = "area"
    LINE = "line"

# Data Classes
@dataclass
class Position:
    latitude: float
    longitude: float
    heading: float = 0.0
    accuracy: float = 0.0
    elevation: float = 0.0
    updated_at: float = field(default_factory=time.time)

    def distance_to(self, other: 'Position') -> float:
        """Calculate distance in meters using Haversine formula"""
        from math import radians, sin, cos, sqrt, atan2
        
        R = 6371000  # Earth's radius in meters
        lat1, lon1 = radians(self.latitude), radians(self.longitude)
        lat2, lon2 = radians(other.latitude), radians(other.longitude)
        
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return R * c

@dataclass
class Player:
    player_id: str
    callsign: str
    team_id: Optional[str] = None
    connection_status: ConnectionStatus = ConnectionStatus.DISCONNECTED
    last_active: float = field(default_factory=time.time)
    position: Optional[Position] = None
    device_info: Dict[str, str] = field(default_factory=dict)
    websocket: Optional[WebSocketServerProtocol] = None

@dataclass
class Team:
    team_id: str
    name: str
    color: str = "#00FF00"
    players: Set[str] = field(default_factory=set)
    markers: Set[str] = field(default_factory=set)

@dataclass
class Marker:
    marker_id: str
    type: MarkerType
    created_by: str
    team_id: str
    visibility: Visibility
    position: Position
    properties: Dict[str, Any] = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    expires_at: Optional[float] = None

@dataclass
class Message:
    message_id: str
    sender_id: str
    team_id: str
    visibility: Visibility
    type: str
    content: str
    sent_at: float = field(default_factory=time.time)
    location: Optional[Position] = None

@dataclass
class Session:
    session_id: str
    created_at: float = field(default_factory=time.time)
    last_active: float = field(default_factory=time.time)
    host_id: Optional[str] = None
    teams: Dict[str, Team] = field(default_factory=dict)
    settings: Dict[str, Any] = field(default_factory=dict)
    players: Dict[str, Player] = field(default_factory=dict)
    markers: Dict[str, Marker] = field(default_factory=dict)
    messages: List[Message] = field(default_factory=list)
    sequence_number: int = 0

class StateDelta:
    """Manages state changes and delta generation"""
    
    def __init__(self):
        self.changes: List[Dict[str, Any]] = []
        
    def add_change(self, change_type: str, entity_type: str, entity_id: str, 
                   data: Dict[str, Any], path: Optional[str] = None):
        change = {
            "type": change_type,
            "entity_type": entity_type,
            "entity_id": entity_id,
            "data": data,
            "timestamp": time.time()
        }
        if path:
            change["path"] = path
        self.changes.append(change)
    
    def to_dict(self, session_id: str, sequence_number: int) -> Dict[str, Any]:
        return {
            "delta_id": str(uuid.uuid4()),
            "session_id": session_id,
            "timestamp": time.time(),
            "sequence_number": sequence_number,
            "changes": self.changes
        }

class TacticalServer:
    """Main server class managing all game sessions"""
    
    def __init__(self, host: str = "0.0.0.0", port: int = DEFAULT_PORT):
        self.host = host
        self.port = port
        self.sessions: Dict[str, Session] = {}
        self.player_connections: Dict[str, WebSocketServerProtocol] = {}
        self.update_task: Optional[asyncio.Task] = None
        
    async def start(self):
        """Start the WebSocket server"""
        logger.info(f"Starting Tactical Airsoft Server on {self.host}:{self.port}")
        
        # Start the update loop
        self.update_task = asyncio.create_task(self.update_loop())
        
        # Start WebSocket server
        async with websockets.serve(
            self.handle_connection,
            self.host,
            self.port,
            max_size=MAX_MESSAGE_SIZE
        ):
            logger.info(f"Server running on ws://{self.host}:{self.port}")
            await asyncio.Future()  # Run forever
    
    async def handle_connection(self, websocket: WebSocketServerProtocol, path: str):
        """Handle new WebSocket connections"""
        player_id = None
        session_id = None
        
        try:
            logger.info(f"New connection from {websocket.remote_address}")
            
            async for message in websocket:
                try:
                    logger.info(f"Received message: {message}")  # Add debug logging
                    data = json.loads(message)
                    msg_type = data.get("type")
                    logger.info(f"Message type: {msg_type}")  # Add debug logging
                    
                    if msg_type == MessageType.AUTH:
                        player_id, session_id = await self.handle_auth(websocket, data)
                    elif msg_type == MessageType.PING:
                        await websocket.send(json.dumps({"type": MessageType.PONG}))
                    elif player_id and session_id:
                        await self.handle_message(player_id, session_id, data)
                    else:
                        await self.send_error(websocket, "Not authenticated")
                        
                except json.JSONDecodeError:
                    logger.error(f"Invalid JSON received: {message}")  # Add debug logging
                    await self.send_error(websocket, "Invalid JSON")
                except Exception as e:
                    logger.error(f"Error handling message: {e}")
                    await self.send_error(websocket, str(e))
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Connection closed for player {player_id}")
        except Exception as e:
            logger.error(f"Connection error: {e}")
            traceback.print_exc()
        finally:
            if player_id and session_id:
                await self.handle_disconnect(player_id, session_id)
    
    async def handle_auth(self, websocket: WebSocketServerProtocol, 
                         data: Dict[str, Any]) -> Tuple[Optional[str], Optional[str]]:
        """Handle authentication request"""
        callsign = data.get("callsign", "").strip()
        session_id = data.get("session_id", "").strip()
        is_host = data.get("is_host", False)
        device_info = data.get("device_info", {})
        
        if not callsign:
            await self.send_error(websocket, "Callsign required")
            return None, None
        
        # Create or join session
        if is_host:
            session_id = str(uuid.uuid4())
            session = Session(session_id=session_id)
            
            # Create default teams
            alpha_team = Team(
                team_id=str(uuid.uuid4()),
                name="Alpha",
                color="#00FF00"
            )
            bravo_team = Team(
                team_id=str(uuid.uuid4()),
                name="Bravo", 
                color="#FF0000"
            )
            
            session.teams[alpha_team.team_id] = alpha_team
            session.teams[bravo_team.team_id] = bravo_team
            
            self.sessions[session_id] = session
            logger.info(f"Created new session: {session_id}")
        else:
            if session_id not in self.sessions:
                await self.send_error(websocket, "Session not found")
                return None, None
            session = self.sessions[session_id]
        
        # Create player
        player_id = str(uuid.uuid4())
        player = Player(
            player_id=player_id,
            callsign=callsign,
            connection_status=ConnectionStatus.CONNECTED,
            device_info=device_info,
            websocket=websocket
        )
        
        # Assign to team (simple round-robin for now)
        team_ids = list(session.teams.keys())
        if team_ids:
            # Count players in each team
            team_counts = {tid: len(session.teams[tid].players) for tid in team_ids}
            # Assign to team with fewer players
            player.team_id = min(team_counts, key=team_counts.get)
            session.teams[player.team_id].players.add(player_id)
        
        # Set host if first player
        if is_host:
            session.host_id = player_id
        
        # Add player to session
        session.players[player_id] = player
        self.player_connections[player_id] = websocket
        
        # Send auth response with full state
        await self.send_auth_response(player, session)
        
        # Broadcast player joined to team
        await self.broadcast_player_update(session, player, "add")
        
        logger.info(f"Player {callsign} ({player_id}) joined session {session_id}")
        return player_id, session_id
    
    async def handle_message(self, player_id: str, session_id: str, data: Dict[str, Any]):
        """Handle messages from authenticated players"""
        session = self.sessions.get(session_id)
        if not session:
            return
            
        player = session.players.get(player_id)
        if not player:
            return
        
        msg_type = data.get("type")
        
        if msg_type == MessageType.POSITION_UPDATE:
            await self.handle_position_update(session, player, data)
        elif msg_type == MessageType.CHAT:
            await self.handle_chat(session, player, data)
        elif msg_type == MessageType.ALERT:
            await self.handle_alert(session, player, data)
        elif msg_type == MessageType.MARKER:
            await self.handle_marker(session, player, data)
        elif msg_type == MessageType.TEAM_UPDATE and player_id == session.host_id:
            await self.handle_team_update(session, data)
    
    async def handle_position_update(self, session: Session, player: Player, data: Dict[str, Any]):
        """Handle player position updates"""
        new_position = Position(
            latitude=data["latitude"],
            longitude=data["longitude"],
            heading=data.get("heading", 0),
            accuracy=data.get("accuracy", 0),
            elevation=data.get("elevation", 0)
        )
        
        # Check if position changed significantly
        if player.position is None or \
           player.position.distance_to(new_position) > POSITION_UPDATE_THRESHOLD:
            player.position = new_position
            player.last_active = time.time()
            
            # Broadcast to team members only
            delta = StateDelta()
            delta.add_change("update", "player", player.player_id, {
                "position": asdict(new_position)
            })
            
            await self.broadcast_delta(session, delta, team_id=player.team_id)
    
    async def handle_chat(self, session: Session, player: Player, data: Dict[str, Any]):
        """Handle chat messages"""
        message = Message(
            message_id=str(uuid.uuid4()),
            sender_id=player.player_id,
            team_id=player.team_id,
            visibility=Visibility(data.get("visibility", Visibility.TEAM)),
            type="chat",
            content=data["content"][:500],  # Limit message length
            location=Position(**data["location"]) if "location" in data else None
        )
        
        session.messages.append(message)
        
        # Keep only last 100 messages
        if len(session.messages) > 100:
            session.messages = session.messages[-100:]
        
        # Broadcast based on visibility
        delta = StateDelta()
        delta.add_change("add", "message", message.message_id, asdict(message))
        
        if message.visibility == Visibility.TEAM:
            await self.broadcast_delta(session, delta, team_id=player.team_id)
        else:
            await self.broadcast_delta(session, delta)
    
    async def handle_alert(self, session: Session, player: Player, data: Dict[str, Any]):
        """Handle tactical alerts"""
        alert_type = AlertType(data["alert_type"])
        location_data = data.get("location", {})
        
        message = Message(
            message_id=str(uuid.uuid4()),
            sender_id=player.player_id,
            team_id=player.team_id,
            visibility=Visibility.TEAM,
            type="alert",
            content=f"{alert_type.value.upper()} - {player.callsign}",
            location=Position(**location_data) if location_data else player.position
        )
        
        session.messages.append(message)
        
        # Broadcast alert to team
        delta = StateDelta()
        delta.add_change("add", "message", message.message_id, asdict(message))
        await self.broadcast_delta(session, delta, team_id=player.team_id)
    
    async def handle_marker(self, session: Session, player: Player, data: Dict[str, Any]):
        """Handle marker operations"""
        action = data["action"]
        
        if action == "create":
            marker = Marker(
                marker_id=str(uuid.uuid4()),
                type=MarkerType(data["marker_data"]["type"]),
                created_by=player.player_id,
                team_id=player.team_id,
                visibility=Visibility(data["marker_data"].get("visibility", Visibility.TEAM)),
                position=Position(**data["marker_data"]["position"]),
                properties=data["marker_data"].get("properties", {})
            )
            
            session.markers[marker.marker_id] = marker
            session.teams[player.team_id].markers.add(marker.marker_id)
            
            delta = StateDelta()
            delta.add_change("add", "marker", marker.marker_id, asdict(marker))
            
            if marker.visibility == Visibility.TEAM:
                await self.broadcast_delta(session, delta, team_id=player.team_id)
            else:
                await self.broadcast_delta(session, delta)
                
        elif action == "update":
            marker_id = data["marker_id"]
            marker = session.markers.get(marker_id)
            
            if marker and marker.created_by == player.player_id:
                # Update marker properties
                if "properties" in data["marker_data"]:
                    marker.properties.update(data["marker_data"]["properties"])
                
                delta = StateDelta()
                delta.add_change("update", "marker", marker_id, {
                    "properties": marker.properties
                })
                
                if marker.visibility == Visibility.TEAM:
                    await self.broadcast_delta(session, delta, team_id=player.team_id)
                else:
                    await self.broadcast_delta(session, delta)
                    
        elif action == "delete":
            marker_id = data["marker_id"]
            marker = session.markers.get(marker_id)
            
            if marker and marker.created_by == player.player_id:
                del session.markers[marker_id]
                session.teams[marker.team_id].markers.discard(marker_id)
                
                delta = StateDelta()
                delta.add_change("remove", "marker", marker_id, {})
                
                if marker.visibility == Visibility.TEAM:
                    await self.broadcast_delta(session, delta, team_id=player.team_id)
                else:
                    await self.broadcast_delta(session, delta)
    
    async def handle_team_update(self, session: Session, data: Dict[str, Any]):
        """Handle team management (host only)"""
        action = data.get("action")
        
        if action == "assign_player":
            player_id = data["player_id"]
            new_team_id = data["team_id"]
            
            player = session.players.get(player_id)
            if player and new_team_id in session.teams:
                # Remove from old team
                if player.team_id:
                    session.teams[player.team_id].players.discard(player_id)
                
                # Add to new team
                player.team_id = new_team_id
                session.teams[new_team_id].players.add(player_id)
                
                # Broadcast update
                delta = StateDelta()
                delta.add_change("update", "player", player_id, {
                    "team_id": new_team_id
                })
                await self.broadcast_delta(session, delta)
    
    async def handle_disconnect(self, player_id: str, session_id: str):
        """Handle player disconnection"""
        session = self.sessions.get(session_id)
        if not session:
            return
            
        player = session.players.get(player_id)
        if not player:
            return
        
        player.connection_status = ConnectionStatus.DISCONNECTED
        player.websocket = None
        del self.player_connections[player_id]
        
        # Broadcast disconnection
        await self.broadcast_player_update(session, player, "update")
        
        logger.info(f"Player {player.callsign} disconnected from session {session_id}")
    
    async def broadcast_delta(self, session: Session, delta: StateDelta, 
                            team_id: Optional[str] = None):
        """Broadcast state delta to appropriate players"""
        session.sequence_number += 1
        delta_dict = delta.to_dict(session.session_id, session.sequence_number)
        
        message = json.dumps({
            "type": MessageType.STATE_DELTA,
            "delta": delta_dict
        })
        
        # Determine target players
        if team_id:
            # Team-specific broadcast
            team = session.teams.get(team_id)
            if not team:
                return
            target_players = [session.players[pid] for pid in team.players 
                            if pid in session.players]
        else:
            # Broadcast to all
            target_players = list(session.players.values())
        
        # Send to connected players
        tasks = []
        for player in target_players:
            if player.websocket and player.connection_status == ConnectionStatus.CONNECTED:
                tasks.append(player.websocket.send(message))
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
    
    async def broadcast_player_update(self, session: Session, player: Player, 
                                    change_type: str):
        """Broadcast player state changes"""
        delta = StateDelta()
        
        # Prepare player data (filter sensitive info for other teams)
        player_data = {
            "player_id": player.player_id,
            "callsign": player.callsign,
            "team_id": player.team_id,
            "connection_status": player.connection_status
        }
        
        delta.add_change(change_type, "player", player.player_id, player_data)
        
        # Broadcast to all (connection status is public info)
        await self.broadcast_delta(session, delta)
    
    async def send_auth_response(self, player: Player, session: Session):
        """Send authentication response with initial state"""
        # Prepare filtered state based on team visibility
        state = self.get_filtered_state(session, player.team_id)
        
        response = {
            "type": MessageType.AUTH_RESPONSE,
            "success": True,
            "player_id": player.player_id,
            "team_id": player.team_id,
            "session_state": state
        }
        
        await player.websocket.send(json.dumps(response))
    
    async def send_error(self, websocket: WebSocketServerProtocol, error: str):
        """Send error message"""
        await websocket.send(json.dumps({
            "type": MessageType.ERROR,
            "error": error
        }))
    
    def get_filtered_state(self, session: Session, team_id: str) -> Dict[str, Any]:
        """Get game state filtered by team visibility"""
        state = {
            "session_id": session.session_id,
            "sequence_number": session.sequence_number,
            "teams": {},
            "players": {},
            "markers": {},
            "messages": []
        }
        
        # Include all teams (public info)
        for tid, team in session.teams.items():
            state["teams"][tid] = {
                "team_id": team.team_id,
                "name": team.name,
                "color": team.color,
                "players": list(team.players)
            }
        
        # Include all players but filter position data
        for pid, player in session.players.items():
            player_data = {
                "player_id": player.player_id,
                "callsign": player.callsign,
                "team_id": player.team_id,
                "connection_status": player.connection_status
            }
            
            # Include position only for teammates
            if player.team_id == team_id and player.position:
                player_data["position"] = asdict(player.position)
            
            state["players"][pid] = player_data
        
        # Include visible markers
        for mid, marker in session.markers.items():
            if marker.visibility == Visibility.ALL or marker.team_id == team_id:
                state["markers"][mid] = asdict(marker)
        
        # Include visible messages (last 50)
        visible_messages = []
        for message in session.messages[-50:]:
            if message.visibility == Visibility.ALL or message.team_id == team_id:
                visible_messages.append(asdict(message))
        state["messages"] = visible_messages
        
        return state
    
    async def update_loop(self):
        """Main update loop for periodic tasks"""
        while True:
            try:
                await asyncio.sleep(1.0 / UPDATE_RATE)
                
                # Check for inactive players
                current_time = time.time()
                for session in list(self.sessions.values()):
                    for player in session.players.values():
                        if player.connection_status == ConnectionStatus.CONNECTED and \
                           current_time - player.last_active > INACTIVE_TIMEOUT:
                            player.connection_status = ConnectionStatus.INACTIVE
                            await self.broadcast_player_update(session, player, "update")
                
                # Clean up empty sessions
                empty_sessions = [sid for sid, session in self.sessions.items() 
                                if not session.players]
                for sid in empty_sessions:
                    del self.sessions[sid]
                    logger.info(f"Removed empty session: {sid}")
                    
            except Exception as e:
                logger.error(f"Error in update loop: {e}")
    
    def generate_qr_code(self, session_id: str) -> str:
        """Generate QR code for session connection"""
        connection_url = f"tacticalairsoft://{self.host}:{self.port}/{session_id}"
        
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(connection_url)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return f"data:image/png;base64,{img_str}"

async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Tactical Airsoft Map Server")
    parser.add_argument("--host", default="0.0.0.0", help="Host address")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Port number")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    
    args = parser.parse_args()
    
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    server = TacticalServer(args.host, args.port)
    
    try:
        await server.start()
    except KeyboardInterrupt:
        logger.info("Server shutting down...")
    except Exception as e:
        logger.error(f"Server error: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())