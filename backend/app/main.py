from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.core.config import settings
import os

# Import des routers
from app.api.auth import router as auth_router
from app.api.sessions import router as sessions_router
from app.api.votes import router as votes_router
from app.api.spotify import router as spotify_router

app = FastAPI(title="Spotify Party API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== ROUTES API (DOIVENT ÊTRE AVANT LE CATCH-ALL) =====
# Routes API de base
@app.get("/api")
async def api_root():
    return {"message": "Spotify Party API", "version": "1.0.0"}

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}

# Include routers avec préfixe /api
app.include_router(auth_router, tags=["auth"])
app.include_router(sessions_router, tags=["sessions"])
app.include_router(votes_router, tags=["votes"])
app.include_router(spotify_router, tags=["spotify"])

# ===== SERVIR LES FICHIERS STATIQUES FLUTTER (APRÈS LES API) =====
static_path = os.path.join(os.path.dirname(__file__), "../../mobile_app/build/web")

# Vérifier si le dossier build existe
if os.path.exists(static_path):
    # Monter les dossiers statiques
    app.mount("/assets", StaticFiles(directory=os.path.join(static_path, "assets")), name="assets")
    
    # Monter canvaskit si existe
    canvaskit_path = os.path.join(static_path, "canvaskit")
    if os.path.exists(canvaskit_path):
        app.mount("/canvaskit", StaticFiles(directory=canvaskit_path), name="canvaskit")
    
    # Route principale pour servir l'app Flutter
    @app.get("/")
    async def serve_app():
        return FileResponse(os.path.join(static_path, "index.html"))
    
    # Catch-all pour le routing Flutter (SPA) - DOIT ÊTRE EN DERNIER
    @app.get("/{full_path:path}")
    async def catch_all(full_path: str):
        # NE PAS intercepter les routes API
        if full_path.startswith("api/"):
            return {"error": "API route not found"}
        
        # Si c'est un fichier qui existe, le servir
        file_path = os.path.join(static_path, full_path)
        if os.path.exists(file_path) and os.path.isfile(file_path):
            return FileResponse(file_path)
        
        # Sinon, servir index.html pour le routing côté client
        return FileResponse(os.path.join(static_path, "index.html"))
else:
    # Si le build n'existe pas, servir l'API uniquement
    @app.get("/")
    async def root():
        return {
            "message": "Spotify Party API - Flutter build not found. Run 'flutter build web' first.", 
            "version": "1.0.0"
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)