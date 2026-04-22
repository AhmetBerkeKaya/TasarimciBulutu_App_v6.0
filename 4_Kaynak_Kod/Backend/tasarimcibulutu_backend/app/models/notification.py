# app/models/notification.py - GÜNCELLENMİŞ HALİ

import enum
import uuid
from datetime import datetime

from sqlalchemy import (Boolean, Column, DateTime, Enum, ForeignKey, String,
                        Text)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship # <-- YENİ İMPORT

# Projenizdeki Base'i doğru yerden import ettiğinizden emin olun
from app.database import Base 

# --- Bildirim Türlerini Tanımlayan Enum ---
class NotificationType(str, enum.Enum):
    # Mesajlaşma
    NEW_MESSAGE = "new_message"
    
    # Başvurular
    APPLICATION_SUBMITTED = "application_submitted"
    APPLICATION_ACCEPTED = "application_accepted"
    APPLICATION_REJECTED = "application_rejected"

    # ================== YENİ EKLENEN TÜRLER ==================
    # Proje Teslimat ve Onay Süreci
    PROJECT_DELIVERED = "project_delivered"     # Freelancer teslim etti -> Proje sahibine
    DELIVERY_ACCEPTED = "delivery_accepted"     # Proje sahibi kabul etti -> Freelancer'a
    REVISION_REQUESTED = "revision_requested"   # Proje sahibi revizyon istedi -> Freelancer'a
    # =======================================================
    
    # Projeler
    PROJECT_COMPLETED = "project_completed"
    PROJECT_CANCELLED = "project_cancelled"
    
    # Değerlendirmeler
    NEW_REVIEW = "new_review"

    # Vitrin (Showcase) Etkileşimleri
    POST_LIKED = "post_liked"
    POST_COMMENTED = "post_commented"
    COMMENT_LIKED = "comment_liked"
    COMMENT_REPLIED = "comment_replied"

    # Sistem ve Yapay Zeka
    WELCOME = "welcome"
    SKILL_TEST_RESULT = "skill_test_result"
    NEW_PROJECT_RECOMMENDATION = "new_project_recommendation"



# --- Notification Veritabanı Modeli (Tablosu) ---
class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True) 
    actor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True) 
    type = Column(Enum(NotificationType, name="notification_type_enum", create_type=True), nullable=False)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    related_entity_id = Column(UUID(as_uuid=True), nullable=True) 
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    # Bu bildirim kime ait? (User.notifications ile eşleşir)
    recipient = relationship(
        "User",
        foreign_keys=[user_id],
        back_populates="notifications"
    )
    # Bu bildirimi kim tetikledi? (User.triggered_notifications ile eşleşir)
    actor = relationship(
        "User",
        foreign_keys=[actor_id],
        back_populates="triggered_notifications"
    )