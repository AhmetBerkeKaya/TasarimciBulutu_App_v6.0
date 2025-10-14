# app/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

# --- DEĞİŞEN/EKLENEN IMPORT'LAR ---
from app import database
from app.crud import user as user_crud
from app.schemas.token import TokenData
from app.config import settings # YENİ: Ayarları okumak için settings'i import ediyoruz
# --- BİTTİ ---

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # --- DEĞİŞEN SATIR ---
        # Artık SECRET_KEY ve ALGORITHM'u 'security' modülünden değil,
        # merkezi 'settings' nesnesinden alıyoruz.
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        # --- DEĞİŞİMİN SONU ---

        email: str | None = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception

    user = user_crud.get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception
    return user