from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.services.spotify_service import SpotifyService
from app.utils.helpers import get_db
from app.utils.auth_helpers import get_user_id_from_token  # 🆕 Import depuis auth_helpers

router = APIRouter(prefix="/api/spotify", tags=["spotify"])

@router.get("/playlists")
async def get_user_playlists(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)  # 🆕 Utilise la vraie fonction JWT
):
    """Obtenir les playlists d'un utilisateur"""
    print(f"🎵 GET /playlists - user_id: {user_id}")
    
    # 🔧 DEBUG: Vérifier l'utilisateur dans la DB
    from app.models.user import User
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        print(f"❌ Utilisateur {user_id} introuvable")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    print(f"✅ Utilisateur trouvé: {user.display_name}")
    print(f"   - Token Spotify: {'✅' if user.spotify_access_token else '❌'}")
    
    if not user.spotify_access_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not authenticated with Spotify. Please login again."
        )
    
    spotify_service = SpotifyService(db)
    
    try:
        playlists = spotify_service.get_user_playlists(user_id)
        
        if playlists is None:
            print("❌ Service returned None")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Failed to get playlists. Your Spotify token may have expired. Please login again."
            )
        
        print(f"✅ {len(playlists)} playlists récupérées")
        return {"playlists": playlists}
        
    except Exception as e:
        print(f"❌ Exception: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting playlists: {str(e)}"
        )

@router.get("/playlists/{playlist_id}/tracks")
async def get_playlist_tracks(
    playlist_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Obtenir les tracks d'une playlist"""
    spotify_service = SpotifyService(db)
    
    tracks = spotify_service.get_playlist_tracks(user_id, playlist_id)
    if tracks is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to get playlist tracks. Please login again."
        )
    
    return {"tracks": tracks}

@router.get("/tracks/{track_id}")
async def get_track(
    track_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Obtenir les détails d'une track"""
    spotify_service = SpotifyService(db)
    
    track = spotify_service.get_track(user_id, track_id)
    if track is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to get track. Please login again."
        )
    
    return track

@router.get("/search")
async def search_tracks(
    query: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Rechercher des tracks"""
    spotify_service = SpotifyService(db)
    
    tracks = spotify_service.search_tracks(user_id, query)
    if tracks is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Search failed. Please login again."
        )
    
    return {"tracks": tracks}