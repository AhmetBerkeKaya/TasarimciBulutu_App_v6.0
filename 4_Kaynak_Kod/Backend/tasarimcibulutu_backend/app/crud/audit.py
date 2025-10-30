# app/crud/audit.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
from sqlalchemy.orm import Session
from app import models
from typing import Optional, Dict, Any
import uuid
import json

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def create_audit_log(
    db: Session,
    *,
    user_id: uuid.UUID,
    action: str,
    actor_id: Optional[uuid.UUID] = None,
    details: Optional[Dict[str, Any]] = None
):
    """
    Denetim kaydı (audit log) tablosuna yeni bir girdi oluşturur.
    ... (docstring'in kalanı aynı) ...
    """
    # Eğer eylemi yapan kişi belirtilmemişse, kullanıcının kendi eylemi olduğu varsayılır.
    if actor_id is None:
        actor_id = user_id
    
    # === YENİ LOG MESAJI ===
    # Not: Güvenlik nedeniyle 'details' bölümünü loglamıyoruz, 
    # çünkü bu, şifre değişikliği gibi hassas veriler içerebilir.
    # Sadece eylemin kendisini logluyoruz.
    logger.info(f"Denetim kaydı oluşturuluyor: Eylem='{action}', EtkilenenKullanıcı={user_id}, EylemiYapan={actor_id}")
    # =======================

    # JSONB uyumluluğu için Pydantic modellerini veya diğer karmaşık
    # nesneleri string'e dönüştürmek gerekebilir.
    sanitized_details = json.loads(json.dumps(details, default=str)) if details else None

    db_log = models.audit.AuditLog(
        user_id=user_id,
        actor_id=actor_id,
        action=action,
        details=sanitized_details
    )
    db.add(db_log)
    # Not: Bu fonksiyon kendi başına commit yapmaz.
    # ... (kalan yorumlar aynı) ...
    return db_log