# app/crud/skill.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

# --- DOĞRU IMPORT'LAR ---
from app.models.skill import Skill
from app.models.user import User
from app.schemas.skill import SkillCreate # <-- SkillCreate'i doğrudan kendi dosyasından alıyoruz
# --- BİTTİ ---

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def get_skill(db: Session, skill_id: UUID) -> Skill | None:
    return db.query(Skill).filter(Skill.id == str(skill_id)).first()

def get_skill_by_name(db: Session, name: str) -> Skill | None:
    return db.query(Skill).filter(Skill.name == name).first()

def get_skills(db: Session, skip: int = 0, limit: int = 100) -> List[Skill]:
    return db.query(Skill).offset(skip).limit(limit).all()

def create_skill(db: Session, skill: SkillCreate) -> Skill | None:
    logger.info(f"Yeni yetkinlik oluşturuluyor: İsim='{skill.name}', Kategori='{skill.category}'") # <-- EKLENDİ
    try:
        # --- DÜZELTME: db_skill iki kez tanımlanmıştı ---
        db_skill = Skill(name=skill.name, category=skill.category)
        db.add(db_skill)
        db.commit()
        db.refresh(db_skill)
        logger.info(f"Yetkinlik başarıyla oluşturuldu: ID={db_skill.id}, İsim='{db_skill.name}'") # <-- EKLENDİ
        return db_skill
    except Exception as e:
        logger.error(f"Yetkinlik (İsim='{skill.name}') oluşturulurken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

def add_skill_to_user(db: Session, user: User, skill: Skill) -> User | None:
    logger.info(f"Kullanıcıya yetkinlik ekleniyor: KullanıcıID={user.id}, YetkinlikID={skill.id}") # <-- EKLENDİ
    try:
        if skill not in user.skills:
            user.skills.append(skill)
            db.commit()
            db.refresh(user)
            logger.info(f"Kullanıcıya yetkinlik başarıyla eklendi: KullanıcıID={user.id}, YetkinlikID={skill.id}") # <-- EKLENDİ
        else:
            logger.info(f"Kullanıcıda bu yetkinlik zaten mevcut: KullanıcıID={user.id}, YetkinlikID={skill.id}") # <-- EKLENDİ
        return user
    except Exception as e:
        logger.error(f"Kullanıcıya (ID={user.id}) yetkinlik (ID={skill.id}) eklenirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None