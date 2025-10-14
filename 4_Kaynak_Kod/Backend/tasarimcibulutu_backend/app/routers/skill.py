from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.crud import skill as skill_crud
from app.schemas import skill as skill_schema
from app.dependencies import get_db, get_current_user # <-- Doğru import
from app.models.user import User as UserModel
from app.models.user import UserRole # Rol kontrolü için import

router = APIRouter(
    prefix="/skills",
    tags=["skills"]
)

@router.get("/", response_model=List[skill_schema.Skill])
def read_skills(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    # Artık yetenekleri görmek için giriş yapmak zorunlu
    current_user: UserModel = Depends(get_current_user)
):
    skills = skill_crud.get_skills(db, skip=skip, limit=limit)
    return skills

@router.post("/", response_model=skill_schema.Skill, status_code=status.HTTP_201_CREATED)
def create_new_skill(
    skill: skill_schema.SkillCreate, 
    db: Session = Depends(get_db),
    # Yeni yetenek oluşturmak için de giriş yapmak zorunlu
    current_user: UserModel = Depends(get_current_user)
):
    # Güvenlik önlemi: Sadece admin'ler yeni yetenek ekleyebilsin
    if current_user.role != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create new skills."
        )

    db_skill = skill_crud.get_skill_by_name(db, name=skill.name)
    if db_skill:
        raise HTTPException(status_code=400, detail="Skill already exists")
    return skill_crud.create_skill(db=db, skill=skill)