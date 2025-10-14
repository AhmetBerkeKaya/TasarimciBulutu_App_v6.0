# app/models/choice.py
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
from uuid import UUID
from sqlalchemy.dialects.postgresql import UUID

class Choice(Base):
    __tablename__ = "choices"

    id = Column(UUID, primary_key=True, index=True)
    question_id = Column(UUID, ForeignKey("questions.id"))
    choice_text = Column(String, nullable=False)
    is_correct = Column(Boolean, default=False)

    question = relationship("Question", back_populates="choices")