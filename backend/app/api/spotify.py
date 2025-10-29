from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.services.spotify_service import SpotifyService
from app.utils.helpers import get_db

router = APIRouter(prefix="/api/spotify", tags=["spotify"])

@router.get("/playlists")
async def get_user_playlists(user_id: str, db: Session = Depends(get_db)):
    """Obtenir les playlists d'un utilisateur"""
    spotify_service = SpotifyService(db)
    
    playlists = spotify_service.get_user_playlists(user_id)
    if playlists is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to get playlists"
        )
    
    return {"playlists": playlists}

@router.get("/playlists/{playlist_id}/tracks")
async def get_playlist_tracks(playlist_id: str, user_id: str, db: Session = Depends(get_db)):
    """Obtenir les tracks d'une playlist"""
    spotify_service = SpotifyService(db)
    
    tracks = spotify_service.get_playlist_tracks(user_id, playlist_id)
    if tracks is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to get playlist tracks"
        )
    
    return {"tracks": tracks}

@router.get("/tracks/{track_id}")
async def get_track(track_id: str, user_id: str, db: Session = Depends(get_db)):
    """Obtenir les détails d'une track"""
    spotify_service = SpotifyService(db)
    
    track = spotify_service.get_track(user_id, track_id)
    if track is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to get track"
        )
    
    return track

@router.get("/search")
async def search_tracks(query: str, user_id: str, db: Session = Depends(get_db)):
    """Rechercher des tracks"""
    spotify_service = SpotifyService(db)
    
    tracks = spotify_service.search_tracks(user_id, query)
    if tracks is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search failed"
        )
    
    return {"tracks": tracks}