# app/crud/work_experience.py
from sqlalchemy.orm import Session
from uuid import UUID

# --- DOĞRU IMPORT'LAR ---
from app.models.work_experience import WorkExperience
# İhtiyacımız olan tüm şemaları doğrudan kendi dosyasından, takma isimle alalım
from app.schemas import work_experience as work_experience_schema
# --- BİTTİ ---

def get_experience(db: Session, experience_id: UUID) -> WorkExperience | None:
    return db.query(WorkExperience).filter(WorkExperience.id == str(experience_id)).first()

def create_user_experience(db: Session, experience: work_experience_schema.WorkExperienceCreate, user_id: UUID) -> WorkExperience:
    # **experience.dict() Pydantic v1'de kaldı, v2'de .model_dump() kullanılır.
    db_experience = WorkExperience(**experience.model_dump(), user_id=user_id)
    db.add(db_experience)
    db.commit()
    db.refresh(db_experience)
    return db_experience

def update_experience(db: Session, db_experience: WorkExperience, experience_in: work_experience_schema.WorkExperienceUpdate) -> WorkExperience:
    update_data = experience_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_experience, key, value)
    db.add(db_experience)
    db.commit()
    db.refresh(db_experience)
    return db_experience

def delete_experience(db: Session, db_experience: WorkExperience) -> WorkExperience:
    db.delete(db_experience)
    db.commit()
    return db_experience