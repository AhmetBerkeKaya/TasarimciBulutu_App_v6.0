# app/schemas/test_result.py
import uuid
from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime
from decimal import Decimal
from app.schemas.skill_test import SkillTestSimple

# Test durumu için modelimizdeki Enum'ı burada da kullanalım
from app.models.test_result import TestStatus

# --- Answer Submission Schemas ---

# Kullanıcının tek bir soruya verdiği cevap
class AnswerSubmit(BaseModel):
    question_id: uuid.UUID
    selected_choice_id: uuid.UUID

# Kullanıcının tüm cevaplarını içeren liste
class TestSubmission(BaseModel):
    answers: List[AnswerSubmit]

# --- TestResult Schemas ---

class TestResultBase(BaseModel):
    test_id: uuid.UUID

class TestResultCreate(TestResultBase):
    pass # Sadece test_id ve (token'dan gelen) user_id yeterli

# Test sonucunu kullanıcıya göstermek için şema
class TestResult(TestResultBase):
    id: uuid.UUID
    user_id: uuid.UUID
    score: Optional[Decimal] = None
    status: TestStatus
    started_at: datetime
    completed_at: Optional[datetime] = None
    skill_test: SkillTestSimple # <-- BU İLİŞKİYİ EKLEYİN

    
    model_config = ConfigDict(from_attributes=True)