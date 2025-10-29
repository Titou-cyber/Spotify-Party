from sqlalchemy import Column, String, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import uuid

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    spotify_id = Column(String(100), unique=True, nullable=False, index=True)
    display_name = Column(String(200))
    email = Column(String(200))
    spotify_access_token = Column(Text)
    spotify_refresh_token = Column(Text)
    token_expires_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)