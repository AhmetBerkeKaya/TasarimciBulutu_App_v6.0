# app/models/project.py

import enum
import uuid
from datetime import datetime
# Table importunu ekliyoruz
from sqlalchemy import Column, String, DateTime, Numeric, Enum, ForeignKey, Text, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy import Enum as SQLAlchemyEnum
from .application import ApplicationStatus

# ================== YENİ ARA TABLO ==================
# Projeler ve Yetenekler arasındaki ilişki için ara tablo
project_skill_association = Table(
    'project_required_skills', Base.metadata,
    Column('project_id', UUID(as_uuid=True), ForeignKey('projects.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('skills.id'), primary_key=True)
)
# ====================================================

class ProjectStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    PENDING_REVIEW = "pending_review"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Project(Base):
    __tablename__ = "projects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=True)
    budget_min = Column(Numeric, nullable=True)
    budget_max = Column(Numeric, nullable=True)
    deadline = Column(DateTime(timezone=True), nullable=True)
    status = Column(
        SQLAlchemyEnum(ProjectStatus, name="projectstatus", native_enum=False, length=20),
        default=ProjectStatus.OPEN.value,
        nullable=False
    )
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), onupdate=datetime.utcnow)

    owner = relationship("User", back_populates="projects")
    applications = relationship("Application", back_populates="project", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="project", cascade="all, delete-orphan")

    # ================== YENİ İLİŞKİ ==================
    # Bir projenin gerektirdiği yeteneklerin listesi
    required_skills = relationship("Skill", secondary=project_skill_association)
    # ================================================

    @property
    def accepted_freelancer_id(self):
        # Bu property'de değişiklik yok, olduğu gibi kalabilir.
        for app in self.applications:
            if app.status == 'accepted' or app.status == ApplicationStatus.accepted:
                return app.freelancer_id
        return None