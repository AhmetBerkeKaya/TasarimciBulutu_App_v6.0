# app/models/test_result.py
# Mevcut importlarınıza ekleyin
from sqlalchemy import Column, Numeric, ForeignKey, DateTime, String, Enum as SQLAlchemyEnum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.database import Base
from datetime import datetime

# Test durumları için bir Enum oluşturalım
import enum

class TestStatus(str, enum.Enum):
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

# Mevcut TestResult sınıfınızı bu şekilde güncelleyin:
class TestResult(Base):
    __tablename__ = "test_results"

    # Şemanızdaki sütunlar
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    test_id = Column(UUID, ForeignKey("skill_tests.id")) # SkillTest ID'si Integer olduğu için
    score = Column(Numeric, nullable=True)
    # completed_at yerine daha genel bir durum yönetimi
    status = Column(SQLAlchemyEnum(TestStatus), default=TestStatus.IN_PROGRESS)
    started_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    # YENİ EKLENECEK İLİŞKİLER
    user = relationship("User", back_populates="test_results")
    skill_test = relationship("SkillTest", back_populates="test_results")