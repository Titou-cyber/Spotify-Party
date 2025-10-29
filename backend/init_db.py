import sys
import os

# Ajouter le chemin de l'application
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.utils.helpers import engine
from app.models.user import Base
from app.models.session import Base as SessionBase
from app.models.vote import Base as VoteBase

def init_db():
    print("Création des tables de la base de données...")
    
    # Créer toutes les tables
    Base.metadata.create_all(bind=engine)
    SessionBase.metadata.create_all(bind=engine) 
    VoteBase.metadata.create_all(bind=engine)
    
    print("✅ Base de données initialisée avec succès !")
    print("📊 Tables créées : users, sessions, votes")

if __name__ == "__main__":
    init_db()