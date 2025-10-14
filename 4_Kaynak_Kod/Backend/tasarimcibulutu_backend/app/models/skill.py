# app/models/skill.py
import uuid
from sqlalchemy import Column, String, Table, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

# Ara tablo (user_skill_association) aynı kalıyor...
user_skill_association = Table(
    'user_skills', Base.metadata,
    Column('user_id', UUID(as_uuid=True), ForeignKey('users.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('skills.id'), primary_key=True)
)

class Skill(Base):
    __tablename__ = "skills"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, unique=True, index=True, nullable=False)
    
    # --- YENİ EKLENECEK SATIR ---
    category = Column(String, index=True, nullable=False)

    # İlişki (users) aynı kalıyor...
    users = relationship(
        "User",
        secondary=user_skill_association,
        back_populates="skills"
    )