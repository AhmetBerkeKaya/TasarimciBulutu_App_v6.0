# app/crud/audit.py

from sqlalchemy.orm import Session
from app import models
from typing import Optional, Dict, Any
import uuid
import json

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

    Args:
        db: SQLAlchemy session objesi.
        user_id: İşlemden etkilenen kullanıcının ID'si.
        action: Yapılan işlemin türü (örn: 'USER_PROFILE_UPDATE').
        actor_id: İşlemi yapan kullanıcının ID'si. Eğer belirtilmezse,
                  işlemi yapan kişinin kendisi olduğu varsayılır.
        details: Değişikliğin detaylarını içeren bir dictionary
                 (örn: {'old_value': '...', 'new_value': '...'}).
    """
    # Eğer eylemi yapan kişi belirtilmemişse, kullanıcının kendi eylemi olduğu varsayılır.
    if actor_id is None:
        actor_id = user_id

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
    # Atomik işlemleri garantilemek için çağrıldığı yerdeki
    # ana işlemle birlikte commit edilecektir.
    return db_log
