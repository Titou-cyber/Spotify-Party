from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

# Import des routers
from app.api.auth import router as auth_router
from app.api.sessions import router as sessions_router
from app.api.votes import router as votes_router
from app.api.spotify import router as spotify_router

app = FastAPI(title="Spotify Party API", version="1.0.0")

# CORS middleware - CONFIGURATION CORRIGÉE
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Autoriser toutes les origines pour le développement
    allow_credentials=True,
    allow_methods=["*"],  # Autoriser toutes les méthodes
    allow_headers=["*"],  # Autoriser tous les headers
)

# Include routers
app.include_router(auth_router)
app.include_router(sessions_router)
app.include_router(votes_router)
app.include_router(spotify_router)

@app.get("/")
async def root():
    return {"message": "Spotify Party API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)