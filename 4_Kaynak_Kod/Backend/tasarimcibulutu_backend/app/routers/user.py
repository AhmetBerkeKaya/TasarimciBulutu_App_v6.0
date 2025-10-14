# app/routers/user.py

# =================== GÜNCELLENMİŞ IMPORT'LAR ===================
import shutil
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Response, UploadFile, File, Request
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

# YENİ EKLENEN IMPORT'LAR: S3 için şemaları ve yardımcı fonksiyonları ekliyoruz
from app.schemas import s3 as s3_schemas
from app.utils import s3 as s3_utils
# ================================================================

from app.crud import user as user_crud, skill as skill_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.user import User as UserSchema, UserCreate, UserUpdate, PasswordUpdate
from slowapi import Limiter
from slowapi.util import get_remote_address

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

    # app/utils/s3.py dosyanızdaki fonksiyonu çağırıyoruz.
    response = s3_utils.create_presigned_post_url(
        bucket_name="tasarimcibulutu-showcase-files-ahmet", # Bu değeri .env dosyanızdan almak daha iyidir.
        object_name=object_name,
        fields=fields,
        conditions=conditions,
        expires_in=600 # URL 10 dakika geçerli olacak
    )
    
    if response is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not create upload URL.")

    return {
        "url": response["url"],
        "fields": response["fields"],
        "file_path": object_name
    }
# ===============================================================================
# ===                         YENİ ENDPOINT BİTTİ                           ===
# ===============================================================================

@router.post("/", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/hour")
def create_user(request: Request, user: UserCreate, db: Session = Depends(get_db)):
    db_user = user_crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user_by_phone = user_crud.get_user_by_phone_number(db, phone_number=user.phone_number)
    if db_user_by_phone:
        raise HTTPException(status_code=400, detail="Bu telefon numarası zaten kayıtlı.")
    return user_crud.create_user(db=db, user=user)

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
    return user_crud.update_user(db=db, user_id=current_user.id, user_update=user_update)

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

@router.get("/{user_id}", response_model=UserSchema)
@limiter.limit("120/minute")
def read_user(request: Request, user_id: UUID, db: Session = Depends(get_db)):
    db_user = user_crud.get_user(db, user_id=str(user_id))
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user