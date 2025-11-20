# app/crud/audit.py

import json
from sqlalchemy.orm import Session
from uuid import UUID
from app import models

def create_audit_log(
    db: Session,
    action: str,
    user_id: UUID | None = None,
    target_entity: str | None = None,
    target_id: str | None = None,
    details: any = None, # Tipini esnek yaptık
    ip_address: str | None = None,
    user_agent: str | None = None
):
    """
    Sistemsel log kaydı oluşturur.
    Gelen details verisi sözlük (dict) ise otomatik string'e çevirir.
    Hata oluşursa ana işlemi durdurmaz.
    """
    try:
        # --- KORUMA KALKANI: Otomatik JSON Dönüşümü ---
        final_details = details
        if isinstance(details, (dict, list)):
            # UUID ve Tarih formatlarını da destekleyerek string'e çevir
            final_details = json.dumps(details, default=str)
        # ---------------------------------------------

        log_entry = models.audit.AuditLog(
            user_id=user_id,
            action=action,
            target_entity=target_entity,
            target_id=str(target_id) if target_id else None,
            details=final_details, # Dönüştürülmüş veriyi kullan
            ip_address=ip_address,
            user_agent=user_agent
        )
        db.add(log_entry)
        db.commit()
        db.refresh(log_entry)
        return log_entry
    except Exception as e:
        print(f"LOGLAMA HATASI (YUTULDU): {e}")
        # Ana işlemi bozmamak için rollback yapıp devam ediyoruz
        db.rollback()
        return None