# app/models/report.py

import uuid
import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as EnumSQL, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class ReportReason(str, enum.Enum):
    SPAM = "Spam / Reklam"
    INAPPROPRIATE = "Uygunsuz İçerik (+18, Şiddet)"
    COPYRIGHT = "Telif Hakkı İhlali"
    FAKE = "Sahte / Yanıltıcı"
    OTHER = "Diğer"

class ReportStatus(str, enum.Enum):
    PENDING = "pending"   # İncelenmeyi bekliyor
    RESOLVED = "resolved" # Çözüldü (İçerik silindi veya işlem yapıldı)
    IGNORED = "ignored"   # Yoksayıldı (Asılsız ihbar)

class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Şikayet Eden Kullanıcı
    reporter_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Şikayet Edilen Vitrin Gönderisi
    showcase_id = Column(UUID(as_uuid=True), ForeignKey("showcase_posts.id"), nullable=False)
    
    reason = Column(EnumSQL(ReportReason), nullable=False)
    description = Column(Text, nullable=True) # Kullanıcının ek açıklaması
    
    status = Column(EnumSQL(ReportStatus), default=ReportStatus.PENDING, nullable=False)
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    # İlişkiler
    reporter = relationship("User", back_populates="reports_submitted")
    showcase_post = relationship("ShowcasePost", back_populates="reports")