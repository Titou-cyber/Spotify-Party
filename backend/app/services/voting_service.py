from sqlalchemy.orm import Session
from app.models.vote import Vote
from typing import Dict, List, Optional
from collections import defaultdict

class VotingService:
    def __init__(self, db: Session):
        self.db = db
    
    def submit_vote(self, session_id: str, user_id: str, track_id: str, vote_type: str) -> Optional[Vote]:
        """Soumettre un vote"""
        try:
            existing_vote = self.db.query(Vote).filter(
                Vote.session_id == session_id,
                Vote.user_id == user_id,
                Vote.track_id == track_id
            ).first()
            
            if existing_vote:
                existing_vote.vote_type = vote_type
                vote = existing_vote
            else:
                vote = Vote(
                    session_id=session_id,
                    user_id=user_id,
                    track_id=track_id,
                    vote_type=vote_type
                )
                self.db.add(vote)
            
            self.db.commit()
            self.db.refresh(vote)
            return vote
            
        except Exception as e:
            self.db.rollback()
            print(f"Error submitting vote: {e}")
            return None
    
    def get_track_results(self, session_id: str, track_id: str) -> Dict[str, int]:
        """Obtenir les résultats pour une track spécifique"""
        votes = self.db.query(Vote).filter(
            Vote.session_id == session_id,
            Vote.track_id == track_id
        ).all()
        
        likes = sum(1 for vote in votes if vote.vote_type == 'like')
        dislikes = sum(1 for vote in votes if vote.vote_type == 'dislike')
        
        return {
            'track_id': track_id,
            'likes': likes,
            'dislikes': dislikes,
            'total_votes': len(votes)
        }
    
    def get_all_results(self, session_id: str) -> Dict[str, Dict[str, int]]:
        """Obtenir tous les résultats d'une session"""
        votes = self.db.query(Vote).filter(Vote.session_id == session_id).all()
        
        results = defaultdict(lambda: {'likes': 0, 'dislikes': 0, 'total_votes': 0})
        
        for vote in votes:
            results[vote.track_id]['likes'] += 1 if vote.vote_type == 'like' else 0
            results[vote.track_id]['dislikes'] += 1 if vote.vote_type == 'dislike' else 0
            results[vote.track_id]['total_votes'] += 1
        
        return dict(results)