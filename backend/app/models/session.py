from sqlalchemy import Column, String, Boolean, DateTime, JSON, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import uuid

Base = declarative_base()

class Session(Base):
    __tablename__ = "sessions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    code = Column(String(6), unique=True, nullable=False, index=True)
    host_id = Column(String(36), nullable=False, index=True)
    name = Column(String(100), default="Session Spotify")
    playlist_ids = Column(JSON, default=list)
    participants = Column(JSON, default=list)
    current_track = Column(JSON, nullable=True)
    track_queue = Column(JSON, default=list)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)