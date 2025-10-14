# app/models/user.py

import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import (Column, String, Boolean, DateTime, Enum as SQLAlchemyEnum, Text, TypeDecorator)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from .skill import user_skill_association
from app.utils import encryption # Yeni şifreleme yardımcımızı import ediyoruz
from cryptography.fernet import InvalidToken # Hata yakalamak için

# ================== YENİ CUSTOM COLUMN TYPE ==================
class EncryptedString(TypeDecorator):
    """
    Veritabanına yazarken veriyi şifreleyen ve okurken çözen
    özel bir SQLAlchemy kolon tipi.
    """
    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        # Veritabanına bir değer yazılırken bu fonksiyon çalışır.
        if value is not None:
            return encryption.encrypt(str(value))
        return value

    def process_result_value(self, value, dialect):
        # Veritabanından bir değer okunurken bu fonksiyon çalışır.
        if value is not None:
            try:
                return encryption.decrypt(str(value))
            except InvalidToken:
                # Eğer veri şifreli değilse (eski veriler için),
                # olduğu gibi döndür. Bu, geçiş sürecini kolaylaştırır.
                return value
        return value
# =============================================================

class UserRole(enum.Enum):
    admin = "admin"
    freelancer = "freelancer"
    client = "client"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    role = Column(SQLAlchemyEnum(UserRole), nullable=False, default=UserRole.freelancer)
    
    # ================== ANA DEĞİŞİKLİK BURADA ==================
    # 'name' alanının tipini 'String' yerine 'EncryptedString' olarak değiştiriyoruz.
    # Şifrelenmiş veri daha uzun olacağı için karakter limitini artırıyoruz.
    name = Column(EncryptedString(512), nullable=False)
    # =============================================================
    
    bio = Column(Text, nullable=True) # İstersen bio gibi alanları da EncryptedString yapabilirsin.
    profile_picture_url = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False, nullable=False)
    phone_number = Column(EncryptedString(128), nullable=True) # Telefon numarasını da şifreleyelim.
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)

    reset_password_token: str | None = Column(String, nullable=True, index=True, unique=True)
    reset_password_token_expires_at: datetime | None = Column(DateTime(timezone=True), nullable=True)

    # --- İlişkiler (Değişiklik Yok) ---
    projects = relationship("Project", back_populates="owner")
    applications = relationship("Application", back_populates="freelancer")
    # Bu kullanıcının ALDIĞI bildirimler (notifications.user_id üzerinden bağlanır)
    notifications = relationship(
        "Notification",
        foreign_keys="[Notification.user_id]",
        back_populates="recipient",
        cascade="all, delete-orphan"
    )
    # Bu kullanıcının SEBEP OLDUĞU/TETİKLEDİĞİ bildirimler (notifications.actor_id üzerinden bağlanır)
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
