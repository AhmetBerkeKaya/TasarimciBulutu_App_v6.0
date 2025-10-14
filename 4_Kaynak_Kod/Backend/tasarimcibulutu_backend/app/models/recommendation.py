# app/models/recommendation.py

import uuid
from datetime import datetime
from sqlalchemy import Column, ForeignKey, DateTime, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class ProjectRecommendation(Base):
    __tablename__ = "project_recommendations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Bu önerinin hangi kullanıcı (freelancer) için yapıldığı
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    
    # Önerilen projenin ID'si
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False)
    
    # Öneri motorumuzun hesapladığı uygunluk puanı
    score = Column(Numeric, nullable=False)
    
    # Bu önerinin ne zaman oluşturulduğu
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    # İlişkiler, verilere kolay erişim için
    user = relationship("User")
    project = relationship("Project")