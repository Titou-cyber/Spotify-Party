from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    spotify_id: str
    display_name: Optional[str] = None
    email: Optional[str] = None

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: str
    created_at: datetime
    
    model_config = {
        "from_attributes": True
    }