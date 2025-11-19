from sqlalchemy.orm import Session
from app.models.session import Session as SessionModel
from typing import List, Optional
import random
import string

class SessionService:
    def __init__(self, db: Session):
        self.db = db
    
    def generate_session_code(self) -> str:
        """
        Génère un code de session unique à 6 lettres
        Utilise uniquement des lettres majuscules (pas de chiffres pour éviter confusion)
        """
        while True:
            # Générer un code aléatoire de 6 lettres majuscules
            code = ''.join(random.choices(string.ascii_uppercase, k=6))
            
            # Vérifier que le code n'existe pas déjà
            existing = self.db.query(SessionModel).filter(SessionModel.code == code).first()
            if not existing:
                return code
    
    def create_session(
        self, 
        host_id: str, 
        name: str, 
        playlist_ids: List[str],
        votes_required: int = 5
    ) -> Optional[SessionModel]:
        """Créer une nouvelle session avec un code unique"""
        try:
            code = self.generate_session_code()
            
            session = SessionModel(
                host_id=host_id,
                code=code,
                name=name,
                playlist_ids=playlist_ids,
                participants=[host_id],
                votes_required=votes_required
            )
            
            self.db.add(session)
            self.db.commit()
            self.db.refresh(session)
            
            return session
        except Exception as e:
            self.db.rollback()
            print(f"Error creating session: {e}")
            return None
    
    def get_session(self, session_id: str) -> Optional[SessionModel]:
        """Obtenir une session par son ID"""
        return self.db.query(SessionModel).filter(SessionModel.id == session_id).first()
    
    def get_session_by_code(self, code: str) -> Optional[SessionModel]:
        """Obtenir une session par son code (insensible à la casse)"""
        return self.db.query(SessionModel).filter(
            SessionModel.code == code.upper(), 
            SessionModel.is_active == True
        ).first()
    
    def join_session(self, code: str, user_id: str) -> Optional[SessionModel]:
        """Rejoindre une session"""
        session = self.get_session_by_code(code)
        if not session:
            return None
        
        if user_id not in session.participants:
            session.participants.append(user_id)
            self.db.commit()
            self.db.refresh(session)
        
        return session
    
    def leave_session(self, session_id: str, user_id: str) -> bool:
        """Quitter une session"""
        session = self.get_session(session_id)
        if not session:
            return False
        
        if user_id in session.participants:
            session.participants.remove(user_id)
            
            # Si l'hôte quitte, fermer la session
            if user_id == session.host_id:
                session.is_active = False
            
            self.db.commit()
            return True
        
        return False
    
    def close_session(self, session_id: str, user_id: str) -> bool:
        """Fermer une session (hôte seulement)"""
        session = self.get_session(session_id)
        if not session or session.host_id != user_id:
            return False
        
        session.is_active = False
        self.db.commit()
        return True
    
    def update_votes_required(self, session_id: str, host_id: str, votes_required: int) -> bool:
        """Mettre à jour le nombre de votes requis (hôte seulement)"""
        session = self.get_session(session_id)
        if not session or session.host_id != host_id:
            return False
        
        session.votes_required = votes_required
        self.db.commit()
        return True