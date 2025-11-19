from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.session import SessionCreate, SessionResponse, SessionJoin
from app.services.session_service import SessionService
from app.utils.helpers import get_db
from app.utils.auth_helpers import get_user_id_from_token  # 🆕 CHANGEMENT ICI

router = APIRouter(prefix="/api/sessions", tags=["sessions"])

@router.post("/create", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    session_data: SessionCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """
    Créer une nouvelle session
    
    - **name**: Nom de la session (optionnel)
    - **playlist_ids**: Liste des IDs de playlists Spotify
    - **votes_required**: Nombre de votes positifs requis (défaut: 5)
    
    Retourne la session créée avec un code unique à 6 lettres
    """
    session_service = SessionService(db)
    
    session = session_service.create_session(
        host_id=user_id,
        name=session_data.name,
        playlist_ids=session_data.playlist_ids,
        votes_required=session_data.votes_required
    )
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create session"
        )
    
    return SessionResponse.model_validate(session)

@router.post("/join", response_model=SessionResponse)
async def join_session(
    join_data: SessionJoin,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """
    Rejoindre une session existante avec un code
    
    - **code**: Code de session à 6 lettres (insensible à la casse)
    """
    session_service = SessionService(db)
    
    session = session_service.join_session(join_data.code, user_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found or inactive"
        )
    
    return SessionResponse.model_validate(session)

@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: str, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Obtenir les détails d'une session"""
    session_service = SessionService(db)
    
    session = session_service.get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # Vérifier que l'utilisateur fait partie de la session
    if user_id not in session.participants:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not part of this session"
        )
    
    return SessionResponse.model_validate(session)

@router.post("/{session_id}/leave")
async def leave_session(
    session_id: str, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Quitter une session"""
    session_service = SessionService(db)
    
    success = session_service.leave_session(session_id, user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to leave session"
        )
    
    return {"message": "Successfully left session"}

@router.post("/{session_id}/close")
async def close_session(
    session_id: str, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Fermer une session (hôte seulement)"""
    session_service = SessionService(db)
    
    success = session_service.close_session(session_id, user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only host can close session or session not found"
        )
    
    return {"message": "Session closed successfully"}

@router.patch("/{session_id}/votes-required")
async def update_votes_required(
    session_id: str,
    votes_required: int,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id_from_token)
):
    """Mettre à jour le nombre de votes requis (hôte seulement)"""
    session_service = SessionService(db)
    
    success = session_service.update_votes_required(session_id, user_id, votes_required)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only host can update votes required or session not found"
        )
    
    return {"message": "Votes required updated successfully", "votes_required": votes_required}