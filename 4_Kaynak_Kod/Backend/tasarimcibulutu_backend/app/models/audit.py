# app/models/audit.py

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # İşlemi yapan kullanıcı (Eğer giriş başarısızsa null olabilir)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    
    # Yapılan işlem (Örn: "LOGIN", "PROJECT_CREATED", "PROJECT_DELETED")
    action = Column(String, index=True, nullable=False)
    
    # İşlemin yapıldığı tablo veya varlık (Örn: "projects", "users")
    target_entity = Column(String, nullable=True)
    
    # Etkilenen kaydın ID'si (Örn: Silinen projenin ID'si)
    target_id = Column(String, nullable=True)
    
    # Detaylı açıklama veya eski/yeni veri farkları
    details = Column(Text, nullable=True)
    
    # Güvenlik ve İzleme Verileri
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True) # Kullanıcının tarayıcı/cihaz bilgisi
    
    timestamp = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))