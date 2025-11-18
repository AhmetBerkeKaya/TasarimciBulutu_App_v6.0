# routers/auth.py

from fastapi import APIRouter, Depends, HTTPException, status, Request, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import timedelta
from jose import JWTError, jwt
import requests # <--- EKSİK OLAN IMPORT BURAYA EKLENDİ

from app import database, security
from app.crud import user as user_crud
from app.schemas.token import Token, RefreshTokenRequest, TokenData 
from app.schemas.user import PasswordRecoveryRequest, PasswordResetRequest
from app.config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.utils import email as email_utils

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
    This token has a limited scope ('viewables:read') and is safe to use on the client-side viewer.
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
