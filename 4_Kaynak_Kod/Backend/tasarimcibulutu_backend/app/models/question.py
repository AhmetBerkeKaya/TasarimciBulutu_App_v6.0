# app/models/question.py
import uuid
from sqlalchemy import Column, String, Text, ForeignKey, Integer, Boolean
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy.dialects.postgresql import UUID

class Question(Base):
    __tablename__ = "questions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    test_id = Column(UUID, ForeignKey("skill_tests.id"))
    question_text = Column(Text, nullable=False)
    # Gelecekte farklı soru tipleri eklemek için (örn: pratik görev)
    question_type = Column(String, default="multiple_choice") 

    skill_test = relationship("SkillTest", back_populates="questions")
    choices = relationship("Choice", back_populates="question", cascade="all, delete-orphan")
