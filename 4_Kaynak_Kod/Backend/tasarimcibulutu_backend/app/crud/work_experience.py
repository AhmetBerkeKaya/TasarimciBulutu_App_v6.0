# app/crud/work_experience.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
from sqlalchemy.orm import Session
from uuid import UUID

# --- DOĞRU IMPORT'LAR ---
from app.models.work_experience import WorkExperience
# İhtiyacımız olan tüm şemaları doğrudan kendi dosyasından, takma isimle alalım
from app.schemas import work_experience as work_experience_schema
# --- BİTTİ ---

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def get_experience(db: Session, experience_id: UUID) -> WorkExperience | None:
    return db.query(WorkExperience).filter(WorkExperience.id == str(experience_id)).first()

def create_user_experience(db: Session, experience: work_experience_schema.WorkExperienceCreate, user_id: UUID) -> WorkExperience | None:
    logger.info(f"Yeni iş deneyimi oluşturuluyor: KullanıcıID={user_id}, Başlık='{experience.title}'") # <-- EKLENDİ
    try:
        # **experience.dict() Pydantic v1'de kaldı, v2'de .model_dump() kullanılır.
        db_experience = WorkExperience(**experience.model_dump(), user_id=user_id)
        db.add(db_experience)
        db.commit()
        db.refresh(db_experience)
        logger.info(f"İş deneyimi başarıyla oluşturuldu: ID={db_experience.id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return db_experience
    except Exception as e:
        logger.error(f"İş deneyimi (KullanıcıID={user_id}) oluşturulurken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

def update_experience(db: Session, db_experience: WorkExperience, experience_in: work_experience_schema.WorkExperienceUpdate) -> WorkExperience | None:
    exp_id = db_experience.id # Hata loglaması için ID'yi alalım
    logger.info(f"İş deneyimi güncelleniyor: ID={exp_id}") # <-- EKLENDİ
    try:
        update_data = experience_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_experience, key, value)
        db.add(db_experience)
        db.commit()
        db.refresh(db_experience)
        logger.info(f"İş deneyimi başarıyla güncellendi: ID={exp_id}") # <-- EKLENDİ
        return db_experience
    except Exception as e:
        logger.error(f"İş deneyimi (ID={exp_id}) güncellenirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

def delete_experience(db: Session, db_experience: WorkExperience) -> WorkExperience | None:
    exp_id = db_experience.id # Hata loglaması için ID'yi alalım
    logger.info(f"İş deneyimi siliniyor: ID={exp_id}") # <-- EKLENDİ
    try:
        db.delete(db_experience)
        db.commit()
        logger.info(f"İş deneyimi başarıyla silindi: ID={exp_id}") # <-- EKLENDİ
        return db_experience
    except Exception as e:
        logger.error(f"İş deneyimi (ID={exp_id}) silinirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None # Silme başarılıysa nesneyi döndürmek yerine None döndürmek daha iyi olabilir, ancak mevcut yapıyı koruyorum.