import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class SkillTest(Base):
    __tablename__ = "skill_tests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    software = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    test_results = relationship("TestResult", back_populates="test")
    questions = relationship("Question", back_populates="skill_test", cascade="all, delete-orphan")
    test_results = relationship("TestResult", back_populates="skill_test")