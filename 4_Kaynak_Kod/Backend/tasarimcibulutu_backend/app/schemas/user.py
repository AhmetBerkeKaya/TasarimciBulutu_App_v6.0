# app/schemas/user.py

import uuid
from pydantic import BaseModel, ConfigDict, EmailStr, field_validator
from typing import List, Optional
from datetime import datetime
import phonenumbers

from app.config import settings
from .skill import Skill as SkillSchema
from .portfolio import PortfolioItem as PortfolioItemSchema
from .work_experience import WorkExperience as WorkExperienceSchema
from .test_result import TestResult as TestResultSchema
from ..models.user import UserRole 

class UserSummary(BaseModel):
    id: uuid.UUID
    name: str
    profile_picture_url: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

    # EKSİK OLAN VALIDATOR'I BURAYA DA EKLİYORUZ
    @field_validator('profile_picture_url')
    def assemble_s3_url(cls, v):
        if v is None or v.startswith('http'):
            return v
        return f"https://{settings.AWS_S3_BUCKET_NAME}.s3.{settings.AWS_REGION}.amazonaws.com/{v}"

class UserBase(BaseModel):
    email: EmailStr
    name: str
    role: UserRole
    bio: Optional[str] = None
    profile_picture_url: Optional[str] = None
    phone_number: str

    @field_validator('profile_picture_url')
    def assemble_s3_url(cls, v):
        if v is None or v.startswith('http'):
            return v
        return f"https://{settings.AWS_S3_BUCKET_NAME}.s3.{settings.AWS_REGION}.amazonaws.com/{v}"

    @field_validator('phone_number')
    def validate_phone_number(cls, v):
        try:
            parsed_number = phonenumbers.parse(v, None)
            if not phonenumbers.is_valid_number(parsed_number):
                raise ValueError("Geçersiz telefon numarası formatı.")
            return phonenumbers.format_number(
                parsed_number, phonenumbers.PhoneNumberFormat.E164
            )
        except phonenumbers.phonenumberutil.NumberParseException:
            raise ValueError("Geçersiz telefon numarası formatı.")
        except Exception as e:
            raise ValueError(f"Telefon numarası doğrulanırken bir hata oluştu: {e}")

class UserCreate(UserBase):
    password: str

# ========================================================================
# ===                     DEĞİŞİKLİK BURADA                            ===
# ========================================================================
class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    phone_number: Optional[str] = None
    profile_picture_url: Optional[str] = None # <-- EKSİK ALANI EKLEDİK
# ========================================================================

class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str

class PasswordRecoveryRequest(BaseModel):
    email: EmailStr

class PasswordResetRequest(BaseModel):
    token: str
    new_password: str

class User(UserBase):
    id: uuid.UUID
    is_verified: bool
    phone_number: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    skills: List[SkillSchema] = []
    portfolio_items: List[PortfolioItemSchema] = []
    work_experiences: List[WorkExperienceSchema] = []
    test_results: List[TestResultSchema] = []
    reviews_received: List['Review'] = []
    model_config = ConfigDict(from_attributes=True)

class UserInResponse(UserSummary):
    pass

from .review import Review
User.model_rebuild()