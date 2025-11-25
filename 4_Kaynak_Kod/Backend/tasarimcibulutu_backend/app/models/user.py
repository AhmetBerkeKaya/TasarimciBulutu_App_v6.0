# app/models/user.py

import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import (Column, String, Boolean, DateTime, Enum as SQLAlchemyEnum, Text, TypeDecorator)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from .skill import user_skill_association
from app.utils import encryption 
from cryptography.fernet import InvalidToken 

# ================== CUSTOM COLUMN TYPE (AYNEN KALDI) ==================
class EncryptedString(TypeDecorator):
    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            return encryption.encrypt(str(value))
        return value

    def process_result_value(self, value, dialect):
        if value is not None:
            try:
                return encryption.decrypt(str(value))
            except InvalidToken:
                return value
        return value
# ======================================================================

class UserRole(enum.Enum):
    admin = "admin"          # <-- Zaten vardı, süper.
    freelancer = "freelancer"
    client = "client"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    
    # Rol sütunu (Enum olarak tutuluyor)
    role = Column(SQLAlchemyEnum(UserRole), nullable=False, default=UserRole.freelancer)
    
    name = Column(EncryptedString(512), nullable=False)
    bio = Column(Text, nullable=True)
    profile_picture_url = Column(String, nullable=True)
    
    # E-posta onayı
    is_verified = Column(Boolean, default=False, nullable=False)
    
    # --- YENİ EKLENEN SÜTUN: BANLAMA/PASİFE ALMA ---
    # True: Giriş yapabilir. False: Banlı/Pasif.
    is_active = Column(Boolean, default=True, nullable=False)
    # -----------------------------------------------

    phone_number = Column(EncryptedString(128), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)

    reset_password_token: str | None = Column(String, nullable=True, index=True, unique=True)
    reset_password_token_expires_at: datetime | None = Column(DateTime(timezone=True), nullable=True)

    # --- İlişkiler (Aynen Kaldı) ---
    projects = relationship("Project", back_populates="owner")
    applications = relationship("Application", back_populates="freelancer")
    notifications = relationship(
        "Notification",
        foreign_keys="[Notification.user_id]",
        back_populates="recipient",
        cascade="all, delete-orphan"
    )
    triggered_notifications = relationship(
        "Notification",
        foreign_keys="[Notification.actor_id]",
        back_populates="actor"
    )
    sent_messages = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id")
    received_messages = relationship("Message", back_populates="receiver", foreign_keys="Message.receiver_id")
    test_results = relationship("TestResult", back_populates="user", cascade="all, delete-orphan")
    skills = relationship("Skill", secondary=user_skill_association, back_populates="users")
    portfolio_items = relationship("PortfolioItem", back_populates="owner", cascade="all, delete-orphan")
    work_experiences = relationship("WorkExperience", back_populates="owner", cascade="all, delete-orphan")
    reviews_given = relationship("Review", foreign_keys="Review.reviewer_id", back_populates="reviewer", cascade="all, delete-orphan")
    reviews_received = relationship("Review", foreign_keys="Review.reviewee_id", back_populates="reviewee", cascade="all, delete-orphan")
    showcase_posts = relationship("ShowcasePost", back_populates="owner", cascade="all, delete-orphan")
    likes = relationship("PostLike", back_populates="user", cascade="all, delete-orphan")
    comments = relationship("PostComment", back_populates="author", cascade="all, delete-orphan")
    comment_likes = relationship("CommentLike", back_populates="user", cascade="all, delete-orphan")
    reports_submitted = relationship("Report", back_populates="reporter")