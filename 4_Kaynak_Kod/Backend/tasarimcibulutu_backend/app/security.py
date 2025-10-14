# security.py

from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.config import settings # Ayarları config dosyasından import ediyoruz

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Kısa süreli access token oluşturur.
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # Ayarlardan gelen geçerlilik süresini kullanıyoruz
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    # Ayarlardan gelen SECRET_KEY ve ALGORITHM'u kullanıyoruz
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

# --- YENİ FONKSİYON ---
def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Uzun süreli refresh token oluşturur.
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # Ayarlardan gelen geçerlilik süresini kullanıyoruz (gün olarak)
        expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    to_encode.update({"exp": expire})
    # Refresh token'a özel bir belirteç ekleyebiliriz (isteğe bağlı ama iyi bir pratik)
    to_encode.update({"type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt
# --- YENİ FONKSİYON SONU ---
