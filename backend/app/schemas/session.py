from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

class SessionBase(BaseModel):
    name: Optional[str] = "Session Spotify"
    playlist_ids: List[str] = []

class SessionCreate(SessionBase):
    pass

class SessionResponse(SessionBase):
    id: str
    code: str
    host_id: str
    participants: List[str]
    current_track: Optional[Dict[str, Any]] = None
    track_queue: List[Dict[str, Any]]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = {
        "from_attributes": True
    }

class SessionJoin(BaseModel):
    code: str