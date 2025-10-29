from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.session import SessionCreate, SessionResponse, SessionJoin
from app.services.session_service import SessionService
from app.utils.helpers import get_db
import shortuuid

router = APIRouter(prefix="/api/sessions", tags=["sessions"])

@router.post("/create", response_model=SessionResponse)
async def create_session(
    session_data: SessionCreate,
    user_id: str,  # Dans un vrai projet, utiliser l'auth
    db: Session = Depends(get_db)
):
    """Créer une nouvelle session"""
    session_service = SessionService(db)
    
    # Générer un code unique
    code = shortuuid.ShortUUID().random(length=6).upper()
    
    session = session_service.create_session(
        host_id=user_id,
        code=code,
        name=session_data.name,
        playlist_ids=session_data.playlist_ids
    )
    
    return SessionResponse.from_orm(session)

@router.post("/join", response_model=SessionResponse)
async def join_session(
    join_data: SessionJoin,
    user_id: str,
    db: Session = Depends(get_db)
):
    """Rejoindre une session existante"""
    session_service = SessionService(db)
    
    session = session_service.join_session(join_data.code, user_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found or inactive"
        )
    
    return SessionResponse.from_orm(session)

@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str, db: Session = Depends(get_db)):
    """Obtenir les détails d'une session"""
    session_service = SessionService(db)
    
    session = session_service.get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    return SessionResponse.from_orm(session)

@router.post("/{session_id}/leave")
async def leave_session(session_id: str, user_id: str, db: Session = Depends(get_db)):
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
async def close_session(session_id: str, user_id: str, db: Session = Depends(get_db)):
    """Fermer une session (hôte seulement)"""
    session_service = SessionService(db)
    
    success = session_service.close_session(session_id, user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only host can close session or session not found"
        )
    
    return {"message": "Session closed successfully"}