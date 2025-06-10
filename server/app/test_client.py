#!/usr/bin/env python3
"""
Test client for Tactical Airsoft Map Server
Simulates iOS client behavior for testing
"""

import asyncio
import json
import websockets
import argparse
import random
import time
from typing import Optional, Dict, Any
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TacticalTestClient:
    def __init__(self, server_url: str, callsign: str, is_host: bool = False, session_id: Optional[str] = None):
        self.server_url = server_url
        self.callsign = callsign
        self.is_host = is_host
        self.session_id = session_id
        self.player_id = None
        self.team_id = None
        self.websocket = None
        self.running = True
        
        # Simulated position (San Francisco area)
        self.lat = 37.7749 + random.uniform(-0.01, 0.01)
        self.lon = -122.4194 + random.uniform(-0.01, 0.01)
        self.heading = random.uniform(0, 360)
        
    async def connect(self):
        """Connect to server and authenticate"""
        self.websocket = await websockets.connect(self.server_url)
        logger.info(f"Connected to {self.server_url}")
        
        # Send authentication
        auth_msg = {
            "type": "auth",
            "callsign": self.callsign,
            "is_host": self.is_host,
            "device_info": {
                "device_type": "TestClient",
                "os_version": "Test",
                "app_version": "1.0.0"
            }
        }
        
        if self.session_id:
            auth_msg["session_id"] = self.session_id
            
        await self.websocket.send(json.dumps(auth_msg))
        
        # Wait for auth response
        response = await self.websocket.recv()
        data = json.loads(response)
        
        if data["type"] == "auth_response" and data["success"]:
            self.player_id = data["player_id"]
            self.team_id = data["team_id"]
            session_state = data["session_state"]
            
            if self.is_host:
                self.session_id = session_state["session_id"]
                
            logger.info(f"Authenticated as {self.callsign} (ID: {self.player_id})")
            logger.info(f"Joined team: {self.team_id}")
            
            if self.is_host:
                logger.info(f"Created session: {self.session_id}")
                logger.info(f"Other players can join with: {self.session_id}")
                
            return True
        else:
            logger.error(f"Authentication failed: {data.get('error', 'Unknown error')}")
            return False
    
    async def listen_loop(self):
        """Listen for server messages"""
        try:
            async for message in self.websocket:
                data = json.loads(message)
                msg_type = data.get("type")
                
                if msg_type == "state_delta":
                    delta = data["delta"]
                    logger.info(f"Received delta #{delta['sequence_number']} with {len(delta['changes'])} changes")
                    
                    for change in delta["changes"]:
                        if change["entity_type"] == "message":
                            msg_data = change["data"]
                            if msg_data["type"] == "chat":
                                logger.info(f"[CHAT] {msg_data['sender_id'][:8]}: {msg_data['content']}")
                            elif msg_data["type"] == "alert":
                                logger.info(f"[ALERT] {msg_data['content']}")
                                
                elif msg_type == "error":
                    logger.error(f"Server error: {data['error']}")
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info("Connection closed")
        except Exception as e:
            logger.error(f"Listen error: {e}")
    
    async def position_update_loop(self):
        """Send periodic position updates"""
        while self.running:
            # Simulate movement
            self.lat += random.uniform(-0.0001, 0.0001)
            self.lon += random.uniform(-0.0001, 0.0001)
            self.heading = (self.heading + random.uniform(-10, 10)) % 360
            
            position_msg = {
                "type": "position_update",
                "player_id": self.player_id,
                "latitude": self.lat,
                "longitude": self.lon,
                "heading": self.heading,
                "accuracy": random.uniform(5, 15),
                "elevation": random.uniform(0, 100),
                "timestamp": time.time()
            }
            
            await self.websocket.send(json.dumps(position_msg))
            await asyncio.sleep(2)  # Update every 2 seconds
    
    async def send_chat(self, message: str, to_all: bool = False):
        """Send a chat message"""
        chat_msg = {
            "type": "chat",
            "content": message,
            "visibility": "all" if to_all else "team"
        }
        
        await self.websocket.send(json.dumps(chat_msg))
        logger.info(f"Sent chat: {message}")
    
    async def send_alert(self, alert_type: str):
        """Send a tactical alert"""
        alert_msg = {
            "type": "alert",
            "alert_type": alert_type,
            "location": {
                "latitude": self.lat,
                "longitude": self.lon
            }
        }
        
        await self.websocket.send(json.dumps(alert_msg))
        logger.info(f"Sent alert: {alert_type}")
    
    async def create_marker(self, label: str):
        """Create a map marker"""
        marker_msg = {
            "type": "marker",
            "action": "create",
            "marker_data": {
                "type": "pin",
                "visibility": "team",
                "position": {
                    "latitude": self.lat,
                    "longitude": self.lon
                },
                "properties": {
                    "label": label,
                    "description": f"Marker by {self.callsign}",
                    "icon": "pin",
                    "color": "#FF0000"
                }
            }
        }
        
        await self.websocket.send(json.dumps(marker_msg))
        logger.info(f"Created marker: {label}")
    
    async def interactive_mode(self):
        """Interactive command mode"""
        print("\nCommands:")
        print("  chat <message> - Send team chat")
        print("  chatall <message> - Send all chat")
        print("  alert <contact|danger|rally|help> - Send alert")
        print("  marker <label> - Create marker")
        print("  quit - Exit")
        print()
        
        while self.running:
            try:
                # Use asyncio for non-blocking input
                command = await asyncio.get_event_loop().run_in_executor(
                    None, input, "> "
                )
                
                parts = command.strip().split(" ", 1)
                cmd = parts[0].lower()
                
                if cmd == "quit":
                    self.running = False
                    break
                elif cmd == "chat" and len(parts) > 1:
                    await self.send_chat(parts[1])
                elif cmd == "chatall" and len(parts) > 1:
                    await self.send_chat(parts[1], to_all=True)
                elif cmd == "alert" and len(parts) > 1:
                    alert_type = parts[1].lower()
                    if alert_type in ["contact", "danger", "rally", "help"]:
                        await self.send_alert(alert_type)
                    else:
                        print("Invalid alert type")
                elif cmd == "marker" and len(parts) > 1:
                    await self.create_marker(parts[1])
                else:
                    print("Invalid command")
                    
            except EOFError:
                break
            except Exception as e:
                logger.error(f"Command error: {e}")
    
    async def run(self):
        """Main run loop"""
        try:
            # Connect and authenticate
            if not await self.connect():
                return
            
            # Start tasks
            tasks = [
                asyncio.create_task(self.listen_loop()),
                asyncio.create_task(self.position_update_loop()),
                asyncio.create_task(self.interactive_mode())
            ]
            
            # Wait for any task to complete
            done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            
            # Cancel remaining tasks
            for task in pending:
                task.cancel()
                
        except Exception as e:
            logger.error(f"Run error: {e}")
        finally:
            if self.websocket:
                await self.websocket.close()
            logger.info("Client disconnected")

async def automated_test(server_url: str, num_clients: int = 5, duration: int = 30):
    """Run automated test with multiple clients"""
    logger.info(f"Starting automated test with {num_clients} clients for {duration} seconds")
    
    clients = []
    tasks = []
    
    # Create host
    host = TacticalTestClient(server_url, "Host", is_host=True)
    await host.connect()
    session_id = host.session_id
    
    # Start host tasks
    host_tasks = [
        asyncio.create_task(host.listen_loop()),
        asyncio.create_task(host.position_update_loop())
    ]
    
    # Create other clients
    for i in range(num_clients - 1):
        client = TacticalTestClient(server_url, f"Player{i+1}", session_id=session_id)
        clients.append(client)
        
        if await client.connect():
            # Start client tasks
            tasks.extend([
                asyncio.create_task(client.listen_loop()),
                asyncio.create_task(client.position_update_loop())
            ])
    
    # Simulate some activity
    await asyncio.sleep(2)
    await host.send_chat("Welcome to the game!")
    
    await asyncio.sleep(2)
    await clients[0].send_alert("contact")
    
    await asyncio.sleep(2)
    await clients[1].create_marker("Enemy Position")
    
    # Wait for test duration
    await asyncio.sleep(duration - 6)
    
    # Clean up
    logger.info("Stopping automated test")
    for task in tasks + host_tasks:
        task.cancel()
    
    await host.websocket.close()
    for client in clients:
        if client.websocket:
            await client.websocket.close()

async def main():
    parser = argparse.ArgumentParser(description="Tactical Airsoft Test Client")
    parser.add_argument("--server", default="ws://localhost:8765", help="Server URL")
    parser.add_argument("--callsign", default="TestPlayer", help="Player callsign")
    parser.add_argument("--host", action="store_true", help="Create new session as host")
    parser.add_argument("--session", help="Session ID to join")
    parser.add_argument("--test", action="store_true", help="Run automated test")
    parser.add_argument("--test-clients", type=int, default=5, help="Number of test clients")
    parser.add_argument("--test-duration", type=int, default=30, help="Test duration in seconds")
    
    args = parser.parse_args()
    
    if args.test:
        # Run automated test
        await automated_test(args.server, args.test_clients, args.test_duration)
    else:
        # Run interactive client
        client = TacticalTestClient(
            args.server,
            args.callsign,
            is_host=args.host,
            session_id=args.session
        )
        await client.run()

if __name__ == "__main__":
    asyncio.run(main()) 