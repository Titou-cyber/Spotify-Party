from pydantic import BaseModel
from datetime import datetime

class VoteBase(BaseModel):
    track_id: str
    vote_type: str  # 'like' or 'dislike'

class VoteCreate(VoteBase):
    session_id: str

class VoteResponse(VoteBase):
    id: str
    user_id: str
    session_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class VoteResults(BaseModel):
    track_id: str
    likes: int = 0
    dislikes: int = 0
    total_votes: int = 0