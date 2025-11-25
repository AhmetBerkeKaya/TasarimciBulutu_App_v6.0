# app/crud/user.py (DÜZELTİLMİŞ HALİ)
import logging
from typing import Optional
from sqlalchemy.orm import Session
from app import models, schemas, security 
from passlib.context import CryptContext
from datetime import datetime, timezone, timedelta
import secrets
from app import models, schemas, security, crud
from app.models.notification import NotificationType
from sqlalchemy.dialects.postgresql import UUID as PG_UUID 
from sqlalchemy.orm import joinedload, subqueryload
from app.models.user import User
from app.models.skill import Skill
from app.config import settings
from . import audit as audit_crud

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# === LOGGER AYARI ===
logger = logging.getLogger(__name__) 
logger.setLevel(logging.INFO) 
# ======================

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_user(db: Session, user_id: PG_UUID) -> models.User | None: 
    logger.info(f"Kullanıcı (detaylı) getiriliyor: ID={user_id}") 
    return db.query(models.User).options(
        subqueryload(models.User.skills),
        subqueryload(models.User.portfolio_items),
        subqueryload(models.User.work_experiences),
        joinedload(models.User.reviews_received).joinedload(models.Review.project),
        joinedload(models.User.reviews_received).joinedload(models.Review.reviewer)
    ).filter(models.User.id == str(user_id)).first()

def get_user_by_phone_number(db: Session, phone_number: str) -> models.User | None:
    return db.query(models.User).filter(models.User.phone_number == phone_number).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

def authenticate_user(db: Session, email: str, password: str) -> models.User | None:
    logger.info(f"Kimlik doğrulama denemesi: Email='{email}'") 
    user = get_user_by_email(db, email=email)
    if not user or not security.verify_password(password, user.password_hash):
        logger.warning(f"BAŞARISIZ kimlik doğrulama: Email='{email}'") 
        return None
    
    logger.info(f"BAŞARILI kimlik doğrulama: Email='{email}', ID={user.id}") 
    return user

def create_user(db: Session, user: schemas.UserCreate) -> models.User | None: 
    logger.info(f"Yeni kullanıcı oluşturuluyor: Email='{user.email}', Rol='{user.role}'") 
    try:
        hashed_password = security.get_password_hash(user.password)
        current_time = datetime.now(timezone.utc)
        db_user = models.User(
            email=user.email,
            password_hash=hashed_password,
            role=user.role,
            name=user.name,
            phone_number=user.phone_number,
            created_at=current_time,
            updated_at=current_time
        )
        db.add(db_user)

        # Değişiklikleri veritabanına göndererek db_user.id'nin oluşmasını sağla.
        db.flush()

        # --- DÜZELTME BURADA YAPILDI ---
        # actor_id parametresi audit.py'de yoktu, kaldırıldı.
        # Yerine target_entity ve target_id eklendi.
        audit_crud.create_audit_log(
            db, 
            user_id=db_user.id, 
            action="USER_CREATED",
            target_entity="users",      # Yeni eklenen
            target_id=str(db_user.id)   # Yeni eklenen
        )
        # -------------------------------

        # --- YENİ BİLDİRİM MANTIĞI ---
        try:
            welcome_content = f"Tasarımcı Bulutu'na hoş geldin, {db_user.name}! Profilini tamamlayarak ilk projen için bir adım öne geçebilirsin."
            crud.notification.create_notification(
                db=db,
                user_id=db_user.id, 
                type=NotificationType.WELCOME,
                content=welcome_content
            )
        except Exception as e:
            logger.error(f"Hoş geldin bildirimi oluşturulurken HATA: {e}") 
        # --- BİLDİRİM MANTIĞI BİTTİ ---    

        db.commit()
        db.refresh(db_user)
        logger.info(f"Yeni kullanıcı başarıyla oluşturuldu: ID={db_user.id}, Email={db_user.email}") 

        return db_user
    
    except Exception as e:
        logger.error(f"Kullanıcı (Email={user.email}) oluşturulurken HATA: {e}") 
        db.rollback() 
        return None

    
def update_user(db: Session, user_id: PG_UUID, user_update: schemas.UserUpdate) -> Optional[models.User]:
    logger.info(f"Kullanıcı güncelleniyor: ID={user_id}") 
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        logger.warning(f"Güncellenmek istenen kullanıcı bulunamadı: ID={user_id}") 
        return None

    try:
        update_data = user_update.model_dump(exclude_unset=True)
        changes = {}

        for key, value in update_data.items():
            if hasattr(db_user, key) and getattr(db_user, key) != value:
                log_value = "********" if "password" in key else value
                changes[key] = {
                    "old": getattr(db_user, key),
                    "new": log_value 
                }
                setattr(db_user, key, value)

        if changes:
            db_user.updated_at = datetime.now(timezone.utc)
            audit_crud.create_audit_log(
                db,
                user_id=db_user.id,
                action="USER_PROFILE_UPDATE",
                details=changes
            )

        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        logger.info(f"Kullanıcı başarıyla güncellendi: ID={user_id}, Değişen Alanlar={list(changes.keys())}") 
        return db_user
    except Exception as e:
        logger.error(f"Kullanıcı (ID={user_id}) güncellenirken HATA: {e}") 
        db.rollback() 
        return None

def delete_user(db: Session, user_id: str) -> models.User | None:
    logger.info(f"Kullanıcı siliniyor: ID={user_id}") 
    db_user = get_user(db, user_id)
    if not db_user:
        logger.warning(f"Silinmek istenen kullanıcı bulunamadı: ID={user_id}") 
        return None
    
    try:
        audit_crud.create_audit_log(
            db, 
            user_id=db_user.id, 
            action="USER_DELETED",
        )
        db.delete(db_user)
        db.commit()
        logger.info(f"Kullanıcı başarıyla silindi: ID={user_id}") 
        return db_user
    except Exception as e:
        logger.error(f"Kullanıcı (ID={user_id}) silinirken HATA: {e}") 
        db.rollback() 
        return None

def update_user_password(db: Session, user: models.User, new_password: str) -> models.User | None:
    logger.info(f"Kullanıcı şifresi (profil ayarlarından) güncelleniyor: KullanıcıID={user.id}") 
    try:
        audit_crud.create_audit_log(
            db,
            user_id=user.id,
            action="USER_PASSWORD_UPDATE",
            details={"source": "profile_settings"}
        )
        
        hashed_password = security.get_password_hash(new_password)
        user.password_hash = hashed_password
        user.updated_at = datetime.now(timezone.utc) 
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Kullanıcı şifresi başarıyla güncellendi: KullanıcıID={user.id}") 
        return user
    except Exception as e:
        logger.error(f"Kullanıcı şifresi (ID={user.id}) güncellenirken HATA: {e}") 
        db.rollback() 
        return None

def create_password_reset_token(db: Session, user: models.User) -> str | None:
    logger.info(f"Şifre sıfırlama kodu oluşturuluyor: KullanıcıID={user.id}") 
    try:
        reset_code = ''.join(secrets.choice('0123456789') for _ in range(6))
        user.reset_password_token = reset_code
        user.reset_password_token_expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.RESET_TOKEN_EXPIRE_MINUTES)
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Şifre sıfırlama kodu başarıyla oluşturuldu: KullanıcıID={user.id}") 
        return reset_code
    except Exception as e:
        logger.error(f"Şifre sıfırlama kodu (ID={user.id}) oluşturulurken HATA: {e}") 
        db.rollback() 
        return None

def get_user_by_reset_token(db: Session, token: str) -> models.User | None:
    user = db.query(models.User).filter(models.User.reset_password_token == token).first()
    if not user:
        logger.warning(f"Geçersiz şifre sıfırlama kodu kullanıldı: Token={token}") 
        return None
    
    if user.reset_password_token_expires_at < datetime.now(timezone.utc):
        logger.warning(f"Süresi dolmuş şifre sıfırlama kodu kullanıldı: Token={token}, KullanıcıID={user.id}") 
        try:
            user.reset_password_token = None
            user.reset_password_token_expires_at = None
            db.commit()
        except Exception as e:
            logger.error(f"Süresi dolmuş token (KullanıcıID={user.id}) temizlenirken HATA: {e}") 
            db.rollback()
        return None
    
    logger.info(f"Geçerli şifre sıfırlama kodu kullanıldı: KullanıcıID={user.id}") 
    return user

def reset_user_password(db: Session, user: models.User, new_password: str) -> models.User | None:
    logger.info(f"Kullanıcı şifresi (unutulan şifre) sıfırlanıyor: KullanıcıID={user.id}") 
    try:
        audit_crud.create_audit_log(
            db,
            user_id=user.id,
            action="USER_PASSWORD_RESET",
            details={"source": "forgot_password"}
        )

        user.password_hash = security.get_password_hash(new_password)
        user.reset_password_token = None
        user.reset_password_token_expires_at = None
        user.updated_at = datetime.now(timezone.utc)
        
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Kullanıcı şifresi başarıyla sıfırlandı: KullanıcıID={user.id}") 
        return user
    except Exception as e:
        logger.error(f"Kullanıcı şifresi (ID={user.id}) sıfırlanırken HATA: {e}") 
        db.rollback() 
        return None

def remove_skill_from_user(db: Session, user: User, skill: Skill) -> User | None:
    logger.info(f"Kullanıcıdan yetkinlik kaldırılıyor: KullanıcıID={user.id}, YetkinlikID={skill.id}") 
    try:
        if skill in user.skills:
            user.skills.remove(skill)
            db.commit()
            db.refresh(user) 
            logger.info(f"Kullanıcıdan yetkinlik başarıyla kaldırıldı: KullanıcıID={user.id}, YetkinlikID={skill.id}") 
        else:
            logger.info(f"Kullanıcıda bu yetkinlik zaten yoktu: KullanıcıID={user.id}, YetkinlikID={skill.id}") 
        return user
    except Exception as e:
        logger.error(f"Kullanıcıdan (ID={user.id}) yetkinlik (ID={skill.id}) kaldırılırken HATA: {e}") 
        db.rollback() 
        return None