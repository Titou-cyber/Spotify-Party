from fastapi import WebSocket
from typing import Dict, List
import json

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, session_id: str, user_id: str):
        await websocket.accept()
        
        if session_id not in self.active_connections:
            self.active_connections[session_id] = []
        
        self.active_connections[session_id].append(websocket)
        
        await self.broadcast_to_session(
            session_id,
            {
                "type": "user_joined",
                "user_id": user_id,
                "message": f"User {user_id} joined the session"
            },
            exclude_websocket=websocket
        )
    
    def disconnect(self, websocket: WebSocket, session_id: str, user_id: str):
        if session_id in self.active_connections:
            self.active_connections[session_id].remove(websocket)
            
            if not self.active_connections[session_id]:
                del self.active_connections[session_id]
    
    async def broadcast_to_session(self, session_id: str, message: dict, exclude_websocket: WebSocket = None):
        """Diffuser un message à tous les clients d'une session"""
        if session_id not in self.active_connections:
            return
        
        disconnected_connections = []
        
        for connection in self.active_connections[session_id]:
            if connection != exclude_websocket:
                try:
                    await connection.send_text(json.dumps(message))
                except Exception:
                    disconnected_connections.append(connection)
        
        for connection in disconnected_connections:
            self.active_connections[session_id].remove(connection)
    
    async def handle_websocket_message(self, websocket: WebSocket, session_id: str, user_id: str, data: dict):
        """Traiter les messages WebSocket entrants"""
        message_type = data.get("type")
        
        if message_type == "vote":
            await self.broadcast_to_session(
                session_id,
                {
                    "type": "vote_update",
                    "user_id": user_id,
                    "track_id": data.get("track_id"),
                    "vote_type": data.get("vote_type")
                },
                exclude_websocket=websocket
            )
        
        elif message_type == "track_change":
            await self.broadcast_to_session(
                session_id,
                {
                    "type": "track_change",
                    "track": data.get("track"),
                    "changed_by": user_id
                }
            )

websocket_manager = ConnectionManager()