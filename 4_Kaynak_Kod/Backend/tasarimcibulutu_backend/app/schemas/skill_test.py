# app/schemas/skill_test.py
import uuid
from pydantic import BaseModel, ConfigDict
from typing import List, Optional

# --- Choice Schemas ---

class ChoiceBase(BaseModel):
    choice_text: str

class ChoiceCreate(ChoiceBase):
    is_correct: bool = False

# Kullanıcıya gönderilecek Choice şeması (doğru cevabı içermez)
class Choice(ChoiceBase):
    id: uuid.UUID
    
    model_config = ConfigDict(from_attributes=True)

# --- Question Schemas ---

class QuestionBase(BaseModel):
    question_text: str
    question_type: str = "multiple_choice"

class QuestionCreate(QuestionBase):
    choices: List[ChoiceCreate]

# Kullanıcıya gönderilecek Question şeması
class Question(QuestionBase):
    id: uuid.UUID
    choices: List[Choice] # Cevapları gizlenmiş şıkları içerir

    model_config = ConfigDict(from_attributes=True)

# --- SkillTest Schemas ---

class SkillTestBase(BaseModel):
    title: str
    description: Optional[str] = None
    software: str

class SkillTestCreate(SkillTestBase):
    questions: List[QuestionCreate]

# Test listesinde gösterilecek temel test bilgisi
class SkillTestSimple(SkillTestBase):
    id: uuid.UUID
    
    model_config = ConfigDict(from_attributes=True)
    
# Bir testi başlatmak için kullanıcıya gönderilecek tam test şeması
class SkillTest(SkillTestSimple):
    questions: List[Question]
    
    model_config = ConfigDict(from_attributes=True)