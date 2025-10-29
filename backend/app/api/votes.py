from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.vote import VoteCreate, VoteResponse, VoteResults
from app.services.voting_service import VotingService
from app.utils.helpers import get_db

router = APIRouter(prefix="/api/votes", tags=["votes"])

@router.post("/{session_id}/vote", response_model=VoteResponse)
async def submit_vote(
    session_id: str,
    vote_data: VoteCreate,
    user_id: str,
    db: Session = Depends(get_db)
):
    """Soumettre un vote pour une track"""
    voting_service = VotingService(db)
    
    # Vérifier que l'utilisateur est dans la session
    from app.services.session_service import SessionService
    session_service = SessionService(db)
    session = session_service.get_session(session_id)
    
    if not session or user_id not in session.participants:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User not in session"
        )
    
    vote = voting_service.submit_vote(
        session_id=session_id,
        user_id=user_id,
        track_id=vote_data.track_id,
        vote_type=vote_data.vote_type
    )
    
    if not vote:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to submit vote"
        )
    
    return VoteResponse.from_orm(vote)

@router.get("/{session_id}/track/{track_id}/results", response_model=VoteResults)
async def get_track_results(session_id: str, track_id: str, db: Session = Depends(get_db)):
    """Obtenir les résultats de vote pour une track spécifique"""
    voting_service = VotingService(db)
    
    results = voting_service.get_track_results(session_id, track_id)
    
    return VoteResults(**results)

@router.get("/{session_id}/results")
async def get_all_results(session_id: str, db: Session = Depends(get_db)):
    """Obtenir tous les résultats de vote d'une session"""
    voting_service = VotingService(db)
    
    results = voting_service.get_all_results(session_id)
    
    return results