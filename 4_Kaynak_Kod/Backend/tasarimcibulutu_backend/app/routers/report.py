# app/routers/report.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import database
from app.models.report import Report, ReportStatus
from app.models.user import User, UserRole
from app.models.showcase import ShowcasePost
from app.schemas.report import ReportCreate, ReportResponse
from app.routers.auth import get_db, get_current_user # Mobildeki auth
from app.routers.admin import get_current_admin # Admindeki auth

router = APIRouter(tags=["reports"])

# --- 1. MOBİL: ŞİKAYET OLUŞTUR ---
@router.post("/showcase/{post_id}/report", status_code=201)
def report_showcase_post(
    post_id: str,
    report_data: ReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Post var mı?
    post = db.query(ShowcasePost).filter(ShowcasePost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Gönderi bulunamadı")

    new_report = Report(
        reporter_id=current_user.id,
        showcase_id=post.id,
        reason=report_data.reason,
        description=report_data.description
    )
    db.add(new_report)
    db.commit()
    return {"message": "Şikayetiniz alındı, teşekkürler."}

# --- 2. ADMIN: ŞİKAYETLERİ LİSTELE ---
@router.get("/admin/reports", response_model=List[ReportResponse])
def get_all_reports(
    status: str = "pending", # Varsayılan olarak sadece bekleyenleri getir
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    reports = db.query(Report).filter(Report.status == status).order_by(Report.created_at.desc()).all()
    
    # Manuel Response Mapping (Daha performanslı)
    return [
        ReportResponse(
            id=r.id,
            reporter_name=r.reporter.name,
            showcase_title=r.showcase_post.title if r.showcase_post else "Silinmiş İçerik",
            showcase_id=r.showcase_id,
            showcase_image=r.showcase_post.thumbnail_url if r.showcase_post else None,
            reason=r.reason,
            description=r.description,
            status=r.status,
            created_at=r.created_at
        ) for r in reports
    ]

# --- 3. ADMIN: ŞİKAYETİ ÇÖZ (IGNORE / RESOLVE) ---
@router.patch("/admin/reports/{report_id}/status")
def update_report_status(
    report_id: str,
    status: ReportStatus,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Rapor bulunamadı")
    
    report.status = status
    db.commit()
    return {"message": "Rapor durumu güncellendi."}