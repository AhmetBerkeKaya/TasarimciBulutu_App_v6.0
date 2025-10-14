# app/schemas/application.py

from pydantic import BaseModel, UUID4, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum

# ... (ProjectInApplication ve ApplicationStatus sınıfları aynı)
class ProjectInApplication(BaseModel):
    id: UUID4
    title: str
    owner: 'UserSummary'
    model_config = ConfigDict(from_attributes=True)

class ApplicationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

class ApplicationBase(BaseModel):
    cover_letter: Optional[str] = None
    proposed_budget: Optional[float] = None
    proposed_duration: Optional[int] = None
    
class ApplicationCreate(ApplicationBase):
    project_id: UUID4

# --- EKSİK OLAN VE GERİ EKLENEN SINIF ---
class ApplicationUpdate(BaseModel):
    # Bu şema, bir başvurunun gelecekte farklı alanlarının güncellenmesi için kullanılabilir.
    # Şimdilik sadece status içeriyor ama yapı olarak kalması önemli.
    status: Optional[ApplicationStatus] = None
# --- BİTTİ ---

class ApplicationStatusUpdate(BaseModel):
    status: ApplicationStatus

class Application(ApplicationBase):
    id: UUID4
    freelancer: 'UserSummary'
    project: ProjectInApplication
    status: ApplicationStatus
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)