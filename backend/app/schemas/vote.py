from pydantic import BaseModel
from datetime import datetime

class VoteBase(BaseModel):
    track_id: str
    vote_type: str

class VoteCreate(VoteBase):
    session_id: str

class VoteResponse(VoteBase):
    id: str
    user_id: str
    session_id: str
    created_at: datetime
    
    model_config = {
        "from_attributes": True
    }

class VoteResults(BaseModel):
    track_id: str
    likes: int = 0
    dislikes: int = 0
    total_votes: int = 0