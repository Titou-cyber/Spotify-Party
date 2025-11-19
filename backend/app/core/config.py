from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Spotify API Configuration
    SPOTIFY_CLIENT_ID: str
    SPOTIFY_CLIENT_SECRET: str
    SPOTIFY_REDIRECT_URI: str = "https://oauth.pstmn.io/v1/callback"
    
    # JWT Configuration - Augmenté pour le développement
    JWT_SECRET_KEY: str = "your-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200  # 30 jours au lieu de 30 minutes
    
    DATABASE_URL: str = "sqlite:///./spotify_party.db"
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "http://127.0.0.1:3000"]
    
    class Config:
        env_file = ".env"

settings = Settings()