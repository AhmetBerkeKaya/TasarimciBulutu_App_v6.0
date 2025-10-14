from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

# --- DOĞRU IMPORT'LAR ---
from app.models.skill import Skill
from app.models.user import User
from app.schemas.skill import SkillCreate # <-- SkillCreate'i doğrudan kendi dosyasından alıyoruz
# --- BİTTİ ---

def get_skill(db: Session, skill_id: UUID) -> Skill | None:
    return db.query(Skill).filter(Skill.id == str(skill_id)).first()

def get_skill_by_name(db: Session, name: str) -> Skill | None:
    return db.query(Skill).filter(Skill.name == name).first()

def get_skills(db: Session, skip: int = 0, limit: int = 100) -> List[Skill]:
    return db.query(Skill).offset(skip).limit(limit).all()

def create_skill(db: Session, skill: SkillCreate) -> Skill: # <-- Artık SkillCreate'i tanıyor
    db_skill = Skill(name=skill.name)
    db_skill = Skill(name=skill.name, category=skill.category)
    db.add(db_skill)
    db.commit()
    db.refresh(db_skill)
    return db_skill

def add_skill_to_user(db: Session, user: User, skill: Skill) -> User:
    if skill not in user.skills:
        user.skills.append(skill)
        db.commit()
        db.refresh(user)
    return user