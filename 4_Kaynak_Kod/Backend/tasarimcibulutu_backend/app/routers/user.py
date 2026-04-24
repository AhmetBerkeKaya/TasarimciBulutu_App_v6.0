# app/routers/user.py

# =================== GÜNCELLENMİŞ IMPORT'LAR ===================
import shutil
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Response, UploadFile, File, Request, BackgroundTasks # 🚀 BackgroundTasks eklendi
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import timedelta # 🚀 Token süresi için eklendi

from app.config import settings
from app import security # 🚀 JWT Token üretmek için eklendi
from app.utils import email as email_utils # 🚀 Mail fırlatmak için eklendi

# S3 için şemaları ve yardımcı fonksiyonları ekliyoruz
from app.crud import review as review_crud
from app.schemas import review as review_schemas
from app.schemas import s3 as s3_schemas
from app.utils import s3 as s3_utils
# ================================================================

from app.crud import user as user_crud, skill as skill_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.user import User as UserSchema, UserCreate, UserUpdate, PasswordUpdate
from slowapi import Limiter
from slowapi.util import get_remote_address

# --- LOGLAMA İÇİN YENİ IMPORT ---
from app.crud import audit as audit_crud
# --------------------------------

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(
    prefix="/users",
    tags=["users"]
)

# ===============================================================================
# ===                      YENİ S3 ENDPOINT'İ                                 ===
# ===============================================================================
@router.post("/me/picture-upload-url", response_model=s3_schemas.PresignedPostResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("20/hour")
def create_picture_upload_url(
    request: Request,
    current_user: UserModel = Depends(get_current_user)
):
    """
    Kullanıcının profil resmini S3'e doğrudan yükleyebilmesi için 
    bir presigned URL oluşturur. Yüklenen dosyanın herkese açık olmasını sağlar.
    """
    object_name = f"profile-pictures/{current_user.id}/{uuid.uuid4()}.jpg"
    
    fields = {"acl": "public-read"}
    conditions = [
        {"acl": "public-read"},
        ["starts-with", "$Content-Type", "image/"]
    ]

    response = s3_utils.create_presigned_post_url(
        bucket_name="tasarimcibulutu", 
        object_name=object_name,
        fields=fields,
        conditions=conditions
    )
    
    if response is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not create upload URL.")

    cloud_name = settings.CLOUDINARY_CLOUD_NAME    
    public_id = object_name.rsplit('.', 1)[0] 
    extension = object_name.split('.')[-1]
    full_image_url = f"https://res.cloudinary.com/{cloud_name}/image/upload/{public_id}.{extension}"

    return {
        "url": response["url"],
        "fields": response["fields"],
        "file_path": full_image_url 
    }
# ===============================================================================
# ===                         YENİ ENDPOINT BİTTİ                           ===
# ===============================================================================

# 🚀 GÜNCELLENEN KAYIT OLMA (REGISTER) ENDPOINT'İ
@router.post("/", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/hour")
def create_user(
    request: Request, 
    user: UserCreate, 
    background_tasks: BackgroundTasks, # 🚀 EKLENDİ
    db: Session = Depends(get_db)
):
    db_user = user_crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user_by_phone = user_crud.get_user_by_phone_number(db, phone_number=user.phone_number)
    if db_user_by_phone:
        raise HTTPException(status_code=400, detail="Bu telefon numarası zaten kayıtlı.")
    
    # Kullanıcıyı Veritabanına Kaydet
    created_user = user_crud.create_user(db=db, user=user)

    if created_user:
        # 1. Doğrulama Token'ı Üret (24 Saat Geçerli)
        verification_token = security.create_access_token(
            data={"sub": created_user.email, "type": "email_verification"},
            expires_delta=timedelta(hours=24)
        )

        # 2. Arka Planda Mail Gönder
        # (NOT: app/utils/email.py içinde send_verification_email fonksiyonu olduğundan emin ol)
        try:
            background_tasks.add_task(
                email_utils.send_verification_email, 
                recipient_email=created_user.email,
                token=verification_token
            )
        except AttributeError:
            print("⚠️ Uyarı: email_utils.send_verification_email fonksiyonu henüz yazılmamış! Mail atılamadı.")

        # 3. Admin İçin Logla
        audit_crud.create_audit_log(
            db=db,
            user_id=created_user.id,
            action="USER_REGISTERED",
            target_entity="users",
            target_id=str(created_user.id),
            details=f"Yeni kullanıcı kayıt oldu. Rol: {created_user.role.value}",
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )
    
    return created_user

@router.get("/me", response_model=UserSchema)
@limiter.limit("120/minute")
def read_users_me(request: Request, current_user: UserModel = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserSchema)
@limiter.limit("30/minute")
def update_current_user(
    request: Request,
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    updated_user = user_crud.update_user(db=db, user_id=current_user.id, user_update=user_update)
    
    # --- LOGLAMA: PROFİL GÜNCELLENDİ ---
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="PROFILE_UPDATED",
        target_entity="users",
        target_id=str(current_user.id),
        details="Kullanıcı profil bilgilerini güncelledi.",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
    # -----------------------------------
    
    return updated_user

@router.put("/me/password", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("5/15minute")
def change_current_user_password(
    request: Request,
    password_update: PasswordUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    if not user_crud.verify_password(password_update.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    
    user_crud.update_user_password(db, user=current_user, new_password=password_update.new_password)
    
    # --- LOGLAMA: ŞİFRE DEĞİŞTİRİLDİ ---
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="PASSWORD_CHANGED",
        target_entity="users",
        target_id=str(current_user.id),
        details="Kullanıcı şifresini değiştirdi.",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
    # -----------------------------------
    
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.post("/me/skills/{skill_id}", response_model=UserSchema)
@limiter.limit("60/minute")
def add_skill_to_current_user(
    request: Request,
    skill_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    skill = skill_crud.get_skill(db, skill_id=str(skill_id))
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    return skill_crud.add_skill_to_user(db=db, user=current_user, skill=skill)

@router.delete("/me/skills/{skill_id}", response_model=UserSchema)
@limiter.limit("60/minute")
def remove_skill_from_current_user(
    request: Request,
    skill_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    skill = skill_crud.get_skill(db, skill_id=str(skill_id))
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    return user_crud.remove_skill_from_user(db=db, user=current_user, skill=skill)

@router.get("/", response_model=List[UserSchema])
@limiter.limit("60/minute")
def read_users(request: Request, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = user_crud.get_users(db, skip=skip, limit=limit)
    return users

@router.get("/{user_id}/reviews", response_model=List[review_schemas.Review])
@limiter.limit("60/minute")
def read_user_reviews(request: Request, user_id: UUID, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Belirli bir kullanıcının profiline yapılmış tüm değerlendirmeleri listeler.
    """
    db_user = user_crud.get_user(db, user_id=str(user_id))
    if db_user is None:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
    
    reviews = review_crud.get_reviews_for_user(db, user_id=user_id, skip=skip, limit=limit)
    return reviews

@router.get("/{user_id}", response_model=UserSchema)
@limiter.limit("120/minute")
def read_user(request: Request, user_id: UUID, db: Session = Depends(get_db)):
    db_user = user_crud.get_user(db, user_id=str(user_id))
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user