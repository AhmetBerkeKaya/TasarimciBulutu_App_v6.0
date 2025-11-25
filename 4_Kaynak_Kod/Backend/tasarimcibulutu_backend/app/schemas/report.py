# app/schemas/report.py

from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from uuid import UUID
from app.models.report import ReportReason, ReportStatus

# Mobil'den gelen veri
class ReportCreate(BaseModel):
    reason: ReportReason
    description: Optional[str] = None

# Admin paneline giden veri
class ReportResponse(BaseModel):
    id: UUID
    reporter_name: str
    showcase_title: str
    showcase_id: UUID
    showcase_image: Optional[str]
    reason: ReportReason
    description: Optional[str]
    status: ReportStatus
    created_at: datetime

    class Config:
        from_attributes = True