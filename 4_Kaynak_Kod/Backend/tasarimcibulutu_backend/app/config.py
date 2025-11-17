# app/config.py

import os
from pydantic import EmailStr
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=dotenv_path)

class Settings(BaseSettings):
    """
    Uygulama genelindeki ayarları .env dosyasından okuyan Pydantic modeli.
    """
    # Veritabanı Ayarları
    DATABASE_URL: str

    # JWT Ayarları
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    RESET_TOKEN_EXPIRE_MINUTES: int = 60

    # ================== YENİ ALAN EKLENDİ ==================
    # Veri şifreleme için kullanılacak 32 byte'lık URL-safe base64 kodlu anahtar.
    ENCRYPTION_KEY: str
    # =======================================================

    # E-posta Ayarları
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: EmailStr
    MAIL_PORT: int
    MAIL_SERVER: str
    MAIL_STARTTLS: bool = True
    MAIL_SSL_TLS: bool = False

    # --- YENİ CLOUDINARY AYARLARI (EKLENDİ) ---
    CLOUDINARY_CLOUD_NAME: str
    CLOUDINARY_API_KEY: str
    CLOUDINARY_API_SECRET: str
    
    # API BASE URL (Frontend için proxy URL oluşturulurken kullanılıyor)
    SUPABASE_URL: str
    SUPABASE_KEY: str
    API_BASE_URL: str = "http://10.0.2.2:8000"
    # AWS S3 AYARLARI
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_S3_BUCKET_NAME: str
    AWS_REGION: str
    
    # Autodesk Platform Services (APS) AYARLARI
    APS_CLIENT_ID: str
    APS_CLIENT_SECRET: str

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
