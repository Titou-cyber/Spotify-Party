from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from fastapi.responses import RedirectResponse
from urllib.parse import urlencode
from app.core.config import settings
from app.core.security import create_access_token
from app.models.user import User
from app.schemas.user import UserResponse
from app.services.spotify_service import spotify_service
from app.utils.helpers import get_db
import uuid
import os

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.get("/debug-config")
async def debug_config():
    """Debug de la configuration Spotify"""
    return {
        "spotify_client_id": os.getenv("SPOTIFY_CLIENT_ID", "NOT_SET"),
        "spotify_redirect_uri": os.getenv("SPOTIFY_REDIRECT_URI", "NOT_SET"), 
        "spotify_client_secret_set": bool(os.getenv("SPOTIFY_CLIENT_SECRET")),
        "message": "Configuration Spotify chargée"
    }

@router.get("/login")
async def login():
    """Initier le flux OAuth2 Spotify"""
    try:
        auth_url = spotify_service.get_auth_url()
        return {"auth_url": auth_url}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate auth URL: {str(e)}"
        )

@router.get("/callback")
async def callback(code: str, db: Session = Depends(get_db)):
    """Callback OAuth2 Spotify - Redirige vers le frontend après auth"""
    print(f"🎯 CALLBACK DÉCLENCHÉ - Code reçu: {code}")
    
    try:
        # Échanger le code contre un access token
        print("🔄 Échange du code contre token...")
        token_info = spotify_service.get_access_token(code)
        
        if not token_info:
            print("❌ Échec de l'échange du token")
            return RedirectResponse(url=f"{settings.FRONTEND_URL}?auth_error=token_exchange_failed")
            
        print("✅ Token obtenu avec succès!")
        
        access_token = token_info['access_token']
        refresh_token = token_info['refresh_token']
        expires_in = token_info['expires_in']
        
        # Obtenir le profil utilisateur
        print("🔄 Récupération du profil utilisateur...")
        user_profile = spotify_service.get_user_profile(access_token)
        if not user_profile:
            print("❌ Échec de la récupération du profil")
            return RedirectResponse(url=f"{settings.FRONTEND_URL}?auth_error=profile_failed")
        
        print(f"✅ Profil utilisateur: {user_profile.get('display_name', 'Unknown')}")
        
        # Vérifier si l'utilisateur existe
        user = db.query(User).filter(User.spotify_id == user_profile['id']).first()
        
        if user:
            # Mettre à jour les tokens
            user.spotify_access_token = access_token
            user.spotify_refresh_token = refresh_token
            user.token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
            user.display_name = user_profile.get('display_name', user.display_name)
            user.email = user_profile.get('email', user.email)
            print("✅ Utilisateur existant mis à jour")
        else:
            # Créer un nouvel utilisateur
            user = User(
                id=str(uuid.uuid4()),
                spotify_id=user_profile['id'],
                display_name=user_profile.get('display_name', 'Unknown User'),
                email=user_profile.get('email'),
                spotify_access_token=access_token,
                spotify_refresh_token=refresh_token,
                token_expires_at=datetime.utcnow() + timedelta(seconds=expires_in)
            )
            db.add(user)
            print("✅ Nouvel utilisateur créé")
        
        db.commit()
        db.refresh(user)
        
        # Créer un JWT token pour l'app
        jwt_token = create_access_token(
            data={"sub": user.id, "spotify_id": user.spotify_id}
        )
        
        # Rediriger vers le frontend avec le token
        frontend_url = settings.FRONTEND_URL
        params = {
            "access_token": jwt_token,
            "token_type": "bearer", 
            "user_id": user.id,
            "auth_success": "true"
        }
        
        redirect_url = f"{frontend_url}?{urlencode(params)}"
        print(f"🔀 Redirection vers: {redirect_url}")
        return RedirectResponse(url=redirect_url)
    
    except Exception as e:
        db.rollback()
        print(f"💥 Erreur dans le callback: {str(e)}")
        import traceback
        print(f"Stack trace: {traceback.format_exc()}")
        error_message = str(e).replace(' ', '_')
        return RedirectResponse(url=f"{settings.FRONTEND_URL}?auth_error={error_message}")

@router.post("/refresh")
async def refresh_token(user_id: str, db: Session = Depends(get_db)):
    """Rafraîchir le token Spotify d'un utilisateur"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not user.spotify_refresh_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No refresh token available"
        )
    
    try:
        # Utiliser le service Spotify pour rafraîchir le token
        sp_oauth = spotify_service._create_oauth_manager()
        token_info = sp_oauth.refresh_access_token(user.spotify_refresh_token)
        
        if not token_info:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to refresh token"
            )
        
        user.spotify_access_token = token_info['access_token']
        user.token_expires_at = datetime.utcnow() + timedelta(seconds=token_info['expires_in'])
        
        if 'refresh_token' in token_info:
            user.spotify_refresh_token = token_info['refresh_token']
        
        db.commit()
        db.refresh(user)
        
        return {
            "message": "Token refreshed successfully",
            "expires_in": token_info['expires_in']
        }
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Token refresh failed: {str(e)}"
        )

@router.get("/me")
async def get_current_user(user_id: str, db: Session = Depends(get_db)):
    """Obtenir les informations de l'utilisateur actuel"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return UserResponse.model_validate(user)