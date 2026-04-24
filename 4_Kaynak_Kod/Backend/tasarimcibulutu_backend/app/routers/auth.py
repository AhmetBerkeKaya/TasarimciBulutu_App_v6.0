# app/routers/auth.py

from fastapi import APIRouter, Depends, HTTPException, status, Request, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import timedelta
from jose import JWTError, jwt
import requests 
from pydantic import BaseModel # 🚀 EKLENDİ (VerifyEmailRequest için)

from app import database, security
from app.crud import user as user_crud
from app.crud import audit as audit_crud
from app.schemas.token import Token, RefreshTokenRequest, TokenData 
from app.schemas.user import PasswordRecoveryRequest, PasswordResetRequest
from app.config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.utils import email as email_utils
from app.models.user import User as UserModel 
from app.dependencies import get_db, get_current_user, get_current_admin

router = APIRouter(
    tags=["authentication"]
)

limiter = Limiter(key_func=get_remote_address)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 1. STANDART GİRİŞ (MOBİL İÇİN) ---
@router.post("/token", response_model=Token)
@limiter.limit("10/15minute")
def login_for_access_token(request: Request, db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = user_crud.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    audit_crud.create_audit_log(
        db=db,
        user_id=user.id,
        action="LOGIN_SUCCESS",
        target_entity="users",
        target_id=str(user.id),
        details="Kullanıcı mobil/web giriş yaptı.",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    refresh_token = security.create_refresh_token(
        data={"sub": user.email}
    )
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}

# --- 2. ADMIN GİRİŞİ (WEB PORTAL İÇİN - YENİ) ---
@router.post("/admin/token", response_model=Token)
@limiter.limit("5/15minute")
def login_for_admin_access_token(request: Request, db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = user_crud.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Hatalı e-posta veya şifre.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    is_authorized = user.is_superuser or user.roles.get("admin_panel") in ["super_admin", "admin", "editor"]
    
    if not is_authorized:
        audit_crud.create_audit_log(
            db=db,
            user_id=user.id,
            action="ADMIN_LOGIN_FAILED_UNAUTHORIZED",
            details="Yetkisiz kullanıcı admin paneline girmeye çalıştı.",
            ip_address=request.client.host
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu panele giriş yetkiniz yok."
        )

    audit_crud.create_audit_log(
        db=db,
        user_id=user.id,
        action="ADMIN_LOGIN_SUCCESS",
        target_entity="users",
        target_id=str(user.id),
        details="Yönetici paneline giriş yapıldı.",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    refresh_token = security.create_refresh_token(
        data={"sub": user.email}
    )
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}

@router.post("/token/refresh", response_model=Token)
@limiter.limit("10/minute")
def refresh_access_token(request: Request, db: Session = Depends(get_db), token_data: RefreshTokenRequest = Depends()):
    user = user_crud.get_user_by_email(db, email=jwt.decode(token_data.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]).get("sub"))
    if not user:
         raise HTTPException(status_code=401, detail="Invalid refresh token")
    new_access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    new_access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=new_access_token_expires
    )
    new_refresh_token = security.create_refresh_token(
        data={"sub": user.email}
    )
    return {"access_token": new_access_token, "refresh_token": new_refresh_token, "token_type": "bearer"}


@router.post("/password-recovery", status_code=status.HTTP_200_OK)
@limiter.limit("5/hour")
async def password_recovery(
    request: Request,
    recovery_data: PasswordRecoveryRequest,
    background_tasks: BackgroundTasks, 
    db: Session = Depends(get_db)
):
    user = user_crud.get_user_by_email(db, email=recovery_data.email)
    
    if user:
        reset_code = user_crud.create_password_reset_token(db=db, user=user)
        background_tasks.add_task(
            email_utils.send_password_reset_email,
            recipient_email=user.email,
            reset_code=reset_code
        )

    return {"message": "If an account with that email exists, a password reset code has been sent."}


@router.post("/reset-password", status_code=status.HTTP_200_OK)
@limiter.limit("5/15minute")
def reset_password(
    request: Request,
    reset_data: PasswordResetRequest,
    db: Session = Depends(get_db)
):
    user = user_crud.get_user_by_reset_token(db, token=reset_data.token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset code."
        )
    
    user_crud.reset_user_password(db=db, user=user, new_password=reset_data.new_password)
    
    return {"message": "Password has been reset successfully."}

@router.get("/token/viewer")
@limiter.limit("60/minute")
def get_viewer_token(request: Request):
    """
    Provides a read-only access token for the Autodesk Platform Services viewer.
    """
    token_url = "https://developer.api.autodesk.com/authentication/v2/token"
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {
        'grant_type': 'client_credentials',
        'client_id': settings.APS_CLIENT_ID,
        'client_secret': settings.APS_CLIENT_SECRET,
        'scope': 'viewables:read'
    }
    try:
        response = requests.post(token_url, headers=headers, data=data)
        response.raise_for_status()
        token_info = response.json()
        return {
            "access_token": token_info["access_token"],
            "expires_in": token_info["expires_in"]
        }
    except requests.exceptions.RequestException as e:
        print(f"Autodesk token alınırken hata oluştu: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not connect to Autodesk services to get a viewer token."
        )

# ==========================================================
# 🚀 YENİ EKLENDİ: E-Posta Doğrulama Uç Noktası
# ==========================================================
class VerifyEmailRequest(BaseModel):
    token: str

@router.post("/verify-email", status_code=status.HTTP_200_OK)
@limiter.limit("5/hour")
def verify_email(
    request: Request,
    payload: VerifyEmailRequest,
    db: Session = Depends(get_db)
):
    """
    Kullanıcının mailine giden JWT token'ını çözer ve hesabını doğrular (is_verified = True).
    """
    try:
        # Token'ı çöz ve içinden emaili al
        decoded = jwt.decode(payload.token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email = decoded.get("sub")
        token_type = decoded.get("type")
        
        # Token tipi güvenlik kontrolü
        if token_type != "email_verification" or not email:
            raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş doğrulama kodu.")
            
        user = user_crud.get_user_by_email(db, email=email)
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
            
        if user.is_verified:
            return {"message": "E-posta adresiniz zaten doğrulanmış."}
            
        # Kullanıcıyı onayla
        user.is_verified = True
        db.commit()
        
        # Loglama (Admin panelinde görmek için)
        audit_crud.create_audit_log(
            db=db,
            user_id=user.id,
            action="EMAIL_VERIFIED",
            target_entity="users",
            target_id=str(user.id),
            details="Kullanıcı e-posta adresini doğruladı.",
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )
        
        return {"message": "Tebrikler! E-posta adresiniz başarıyla doğrulandı."}
        
    except JWTError:
        raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş doğrulama kodu.")