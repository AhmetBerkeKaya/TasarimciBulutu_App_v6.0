# app/schemas/project.py

import uuid
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.models.project import ProjectStatus

# İlişkili şemaları import ediyoruz
from app.schemas.user import UserSummary
from app.schemas.skill import Skill 

# ==============================================================
# ===            YENİ: PROJE REVIZYON ŞEMASI                 ===
# ==============================================================
class ProjectRevision(BaseModel):
    id: uuid.UUID
    request_reason: str
    requested_at: datetime

    model_config = ConfigDict(from_attributes=True)
# ==============================================================

class ProjectBase(BaseModel):
    title: str
    description: str
    category: str
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    deadline: Optional[datetime] = None

class ProjectCreate(ProjectBase):
    # Flutter'dan gelen yetenek ID'lerinin listesi
    required_skill_ids: List[uuid.UUID] = []

class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    deadline: Optional[datetime] = None
    status: Optional[ProjectStatus] = None

class ProjectInReview(BaseModel):
    id: uuid.UUID
    title: str
    
    model_config = ConfigDict(from_attributes=True)
    
class Project(ProjectBase):
    id: uuid.UUID
    status: str # Enum yerine string dönmesi serialize açısından daha güvenlidir
    created_at: datetime
    updated_at: datetime
    owner: UserSummary
    
    # Projenin gerektirdiği yeteneklerin detaylı listesi
    required_skills: List[Skill] = []

    # Circular Import hatasını önlemek için 'Application' string olarak belirtildi
    applications: List['Application'] = [] 

    # === YENİ ALAN: REVIZYON GEÇMİŞİ ===
    revisions: List[ProjectRevision] = [] 
    # ===================================

    model_config = ConfigDict(from_attributes=True)