from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Spotify API Configuration
    SPOTIFY_CLIENT_ID: str
    SPOTIFY_CLIENT_SECRET: str
    SPOTIFY_REDIRECT_URI: str = "https://spotify-party.onrender.com/api/auth/callback"
    
    # Frontend URL
    FRONTEND_URL: str = "https://spotify-party.onrender.com"
    
    # JWT Configuration
    JWT_SECRET_KEY: str = "your-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    DATABASE_URL: str = "sqlite:///./spotify_party.db"
    
    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "https://spotify-party.onrender.com",
        "http://localhost:3000", 
        "http://127.0.0.1:3000",
        "http://localhost:8000"
    ]
    
    class Config:
        env_file = ".env"

settings = Settings()