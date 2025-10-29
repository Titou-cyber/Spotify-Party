from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.core.config import settings
from app.core.security import create_access_token
from app.models.user import User
from app.schemas.user import UserResponse
from app.services.spotify_service import spotify_service
from app.utils.helpers import get_db
import uuid

router = APIRouter(prefix="/api/auth", tags=["auth"])

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
    """Callback OAuth2 Spotify"""
    try:
        # Échanger le code contre un access token
        token_info = spotify_service.get_access_token(code)
        if not token_info:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to exchange code for access token"
            )
            
        access_token = token_info['access_token']
        refresh_token = token_info['refresh_token']
        expires_in = token_info['expires_in']
        
        # Obtenir le profil utilisateur
        user_profile = spotify_service.get_user_profile(access_token)
        if not user_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to get user profile"
            )
        
        # Vérifier si l'utilisateur existe
        user = db.query(User).filter(User.spotify_id == user_profile['id']).first()
        
        if user:
            # Mettre à jour les tokens
            user.spotify_access_token = access_token
            user.spotify_refresh_token = refresh_token
            user.token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
            user.display_name = user_profile.get('display_name', user.display_name)
            user.email = user_profile.get('email', user.email)
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
        
        db.commit()
        db.refresh(user)
        
        # Créer un JWT token pour l'app
        jwt_token = create_access_token(
            data={"sub": user.id, "spotify_id": user.spotify_id}
        )
        
        return {
            "access_token": jwt_token,
            "token_type": "bearer",
            "user": UserResponse.from_orm(user)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Authentication failed: {str(e)}"
        )

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
        
        # Mettre à jour le refresh token si un nouveau est fourni
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
    
    return UserResponse.from_orm(user)

@router.get("/check-token")
async def check_token_validity(user_id: str, db: Session = Depends(get_db)):
    """Vérifier si le token Spotify est toujours valide"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    is_valid = True
    message = "Token is valid"
    
    # Vérifier l'expiration
    if user.token_expires_at and user.token_expires_at < datetime.utcnow():
        is_valid = False
        message = "Token has expired"
    
    return {
        "is_valid": is_valid,
        "message": message,
        "expires_at": user.token_expires_at.isoformat() if user.token_expires_at else None
    }

@router.post("/logout")
async def logout(user_id: str, db: Session = Depends(get_db)):
    """Déconnecter l'utilisateur (supprimer les tokens)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    try:
        # Supprimer les tokens Spotify
        user.spotify_access_token = None
        user.spotify_refresh_token = None
        user.token_expires_at = None
        
        db.commit()
        
        return {"message": "Successfully logged out"}
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Logout failed: {str(e)}"
        )