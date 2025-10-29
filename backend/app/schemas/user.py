from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    spotify_id: str
    display_name: Optional[str]
    email: Optional[str]

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: str
    created_at: datetime
    
    class Config:
        from_attributes = True