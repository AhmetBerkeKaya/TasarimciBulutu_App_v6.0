# app/models/audit.py

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from app.database import JSONB_or_JSON
class AuditLog(Base):
    """
    Uygulama içinde gerçekleşen önemli olayları ve veri değişikliklerini
    kaydeden genel amaçlı denetim tablosu.
    """
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Değişiklikten etkilenen kullanıcının ID'si
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Eylemi gerçekleştiren kullanıcının ID'si (örn: admin veya kullanıcının kendisi)
    actor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True, index=True)
    
    # Yapılan işlemin türü (örn: 'USER_PASSWORD_UPDATE', 'USER_PROFILE_UPDATE')
    action = Column(String(100), nullable=False, index=True)
    
    # Değişikliğin detayları (örn: eski ve yeni değerler)
    # JSONB kullanarak esnek bir yapı sağlıyoruz.
    details = Column(JSONB_or_JSON, nullable=True)    
    # İşlemin yapıldığı zaman damgası
    timestamp = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)

    # İlişkiler
    user = relationship("User", foreign_keys=[user_id])
    actor = relationship("User", foreign_keys=[actor_id])

