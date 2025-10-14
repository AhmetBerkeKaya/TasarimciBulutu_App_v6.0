# app/schemas/work_experience.py
from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import date

class WorkExperienceBase(BaseModel):
    title: str
    company_name: str
    start_date: date
    end_date: Optional[date] = None
    description: Optional[str] = None

class WorkExperienceCreate(WorkExperienceBase):
    pass

# --- YENİ EKLENEN SINIF ---
class WorkExperienceUpdate(BaseModel):
    title: Optional[str] = None
    company_name: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    description: Optional[str] = None
# --- BİTTİ ---

class WorkExperience(WorkExperienceBase):
    id: UUID4
    user_id: UUID4

    class Config:
        from_attributes = True