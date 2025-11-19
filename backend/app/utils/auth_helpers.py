from fastapi import Header, HTTPException, status
from jose import JWTError, jwt
from typing import Optional
from app.core.config import settings

def get_user_id_from_token(authorization: Optional[str] = Header(None)) -> str:
    """
    Extraire l'user_id du token Bearer JWT
    Remplace la version simplifiée qui retournait "user_123"
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Vérifier le format "Bearer <token>"
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Expected 'Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = parts[1]
    
    try:
        # Décoder le JWT
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        # Extraire l'user_id (stocké dans "sub")
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        print(f"✅ JWT validé - user_id: {user_id}")
        return user_id
        
    except JWTError as e:
        print(f"❌ JWT Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )