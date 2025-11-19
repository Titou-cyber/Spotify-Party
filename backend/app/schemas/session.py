from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class SessionCreate(BaseModel):
    """Schéma pour créer une session"""
    name: Optional[str] = "Session Spotify"
    playlist_ids: List[str] = Field(..., min_items=1, description="Au moins une playlist requise")
    votes_required: int = Field(default=5, ge=1, description="Nombre de votes positifs requis pour jouer une musique")

class SessionJoin(BaseModel):
    """Schéma pour rejoindre une session"""
    code: str = Field(..., min_length=6, max_length=6, description="Code de session à 6 caractères")

class SessionResponse(BaseModel):
    """Schéma de réponse pour une session"""
    id: str
    code: str
    host_id: str
    name: str
    playlist_ids: List[str]
    participants: List[str]
    current_track: Optional[dict] = None
    track_queue: List[dict] = []
    votes_required: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Pour SQLAlchemy
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }