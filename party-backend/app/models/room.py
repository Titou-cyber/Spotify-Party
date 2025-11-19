# app/models/room.py
from typing import Optional
from datetime import datetime
from sqlmodel import SQLModel, Field


class Room(SQLModel, table=True):
    __tablename__ = "rooms"

    id: Optional[int] = Field(default=None, primary_key=True)

    code: str = Field(index=True, unique=True)  # ex: "ABCD12"
    host_user_id: int = Field(index=True)       # id du SpotifyUser hôte

    like_threshold: int = 1                     # nombre de "j'aime" pour lancer la musique
    is_active: bool = True

    created_at: datetime = Field(default_factory=datetime.utcnow)
