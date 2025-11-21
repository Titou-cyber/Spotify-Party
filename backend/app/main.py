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
@app.get("/api")
async def api_root():
    return {"message": "Spotify Party API", "version": "1.0.0"}

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}

# Include routers avec préfixe /api
app.include_router(auth_router)
app.include_router(sessions_router)
app.include_router(votes_router)
app.include_router(spotify_router)

# ===== SERVIR LES FICHIERS STATIQUES FLUTTER =====
# CHEMIN CORRIGÉ : utiliser frontend/ au lieu de mobile_app/build/web
static_path = os.path.join(os.path.dirname(__file__), "..", "..", "frontend")

# Vérifier si le dossier frontend existe
if os.path.exists(static_path):
    print(f"✅ Serving Flutter app from: {static_path}")
    
    # Monter les dossiers statiques
    assets_path = os.path.join(static_path, "assets")
    if os.path.exists(assets_path):
        app.mount("/assets", StaticFiles(directory=assets_path), name="assets")
    
    # Monter canvaskit si existe
    canvaskit_path = os.path.join(static_path, "canvaskit")
    if os.path.exists(canvaskit_path):
        app.mount("/canvaskit", StaticFiles(directory=canvaskit_path), name="canvaskit")
    
    # Route principale pour servir l'app Flutter
    @app.get("/")
    async def serve_app():
        index_path = os.path.join(static_path, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return {"error": "index.html not found"}
    
    # Catch-all pour le routing Flutter (SPA) - DOIT ÊTRE EN DERNIER
    @app.get("/{full_path:path}")
    async def catch_all(full_path: str):
        # NE PAS intercepter les routes API - CORRECTION ICI
        if full_path.startswith("api/") or full_path.startswith("auth/"):
            return {"error": "API route not found"}
        
        # Si c'est un fichier qui existe, le servir
        file_path = os.path.join(static_path, full_path)
        if os.path.exists(file_path) and os.path.isfile(file_path):
            return FileResponse(file_path)
        
        # Sinon, servir index.html pour le routing côté client
        index_path = os.path.join(static_path, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return {"error": "Not found"}
else:
    print(f"⚠️ Flutter build not found at: {static_path}")
    print("Build Flutter locally and copy to frontend/ folder")
    
    @app.get("/")
    async def root():
        return {
            "message": "Spotify Party API - Flutter build not found", 
            "version": "1.0.0",
            "hint": "Run 'cd mobile_app && flutter build web && cp -r build/web/* ../frontend/' to build the frontend"
        }

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=False)