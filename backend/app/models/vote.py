from sqlalchemy import Column, String, DateTime, Integer, Enum
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import uuid

Base = declarative_base()

class Vote(Base):
    __tablename__ = "votes"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String(36), nullable=False, index=True)
    user_id = Column(String(36), nullable=False, index=True)
    track_id = Column(String(100), nullable=False)
    vote_type = Column(String(10), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)