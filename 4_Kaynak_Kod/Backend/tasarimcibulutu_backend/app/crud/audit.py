# app/crud/audit.py

from sqlalchemy.orm import Session
from uuid import UUID
from app import models

def create_audit_log(
    db: Session,
    action: str,
    user_id: UUID | None = None,
    target_entity: str | None = None,
    target_id: str | None = None,
    details: str | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None
):
    """
    Sistemsel log kaydı oluşturur.
    Hata oluşursa ana işlemi durdurmaz, sadece konsola hata basar.
    """
    try:
        log_entry = models.audit.AuditLog(
            user_id=user_id,
            action=action,
            target_entity=target_entity,
            target_id=str(target_id) if target_id else None,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent
        )
        db.add(log_entry)
        db.commit()
        db.refresh(log_entry)
        return log_entry
    except Exception as e:
        print(f"LOGLAMA HATASI: {e}")
        # Loglama hatası yüzünden kullanıcının işlemi yarım kalmamalı,
        # o yüzden rollback yapıp sessizce devam ediyoruz.
        db.rollback()
        return None