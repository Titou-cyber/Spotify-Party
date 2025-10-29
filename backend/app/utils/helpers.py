from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Configuration de la base de données
engine = create_engine(settings.DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def generate_session_code():
    """Générer un code de session unique"""
    import shortuuid
    return shortuuid.ShortUUID().random(length=6).upper()

def format_duration_ms(duration_ms: int) -> str:
    """Formater une durée en millisecondes en format MM:SS"""
    minutes = duration_ms // 60000
    seconds = (duration_ms % 60000) // 1000
    return f"{minutes}:{seconds:02d}"