# app/routers/work_experience.py
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.schemas import work_experience as work_experience_schema
from app.crud import work_experience as work_experience_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel

router = APIRouter(
    prefix="/work-experiences",
    tags=["Work Experiences"]
)

@router.post("/me", response_model=work_experience_schema.WorkExperience, status_code=status.HTTP_201_CREATED)
def add_experience_for_current_user(
    experience: work_experience_schema.WorkExperienceCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    return work_experience_crud.create_user_experience(db=db, experience=experience, user_id=current_user.id)

# --- YENİ EKLENEN ENDPOINT'LER ---

@router.put("/{experience_id}", response_model=work_experience_schema.WorkExperience)
def update_user_experience(
    experience_id: UUID,
    experience_in: work_experience_schema.WorkExperienceUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    db_experience = work_experience_crud.get_experience(db, experience_id=experience_id)
    if not db_experience:
        raise HTTPException(status_code=404, detail="Experience not found")
    # Kullanıcının sadece kendi deneyimini güncelleyebildiğinden emin ol
    if db_experience.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this experience")
    
    return work_experience_crud.update_experience(db, db_experience=db_experience, experience_in=experience_in)


@router.delete("/{experience_id}", response_model=work_experience_schema.WorkExperience)
def delete_user_experience(
    experience_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    db_experience = work_experience_crud.get_experience(db, experience_id=experience_id)
    if not db_experience:
        raise HTTPException(status_code=404, detail="Experience not found")
    # Kullanıcının sadece kendi deneyimini sildiğinden emin ol
    if db_experience.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this experience")

    return work_experience_crud.delete_experience(db, db_experience=db_experience)