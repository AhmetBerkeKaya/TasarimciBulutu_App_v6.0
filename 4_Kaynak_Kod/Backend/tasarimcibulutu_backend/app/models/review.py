# app/models/review.py

import uuid
from sqlalchemy import Column, Integer, Text, ForeignKey, DateTime # <-- DateTime buraya eklendi
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class Review(Base):
    __tablename__ = "reviews"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False)
    reviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    reviewee_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    
    # DÜZELTİLMİŞ SATIR: "sa." ön eki kaldırıldı
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    # İlişkiler
    project = relationship("Project", back_populates="reviews")
    reviewer = relationship("User", foreign_keys=[reviewer_id], back_populates="reviews_given")
    reviewee = relationship("User", foreign_keys=[reviewee_id], back_populates="reviews_received")
