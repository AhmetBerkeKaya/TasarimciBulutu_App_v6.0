# app/models/project.py

import uuid
import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Float, Text, Table, Enum as EnumSQL
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from .skill import Skill # Skill modelini import ediyoruz

# Proje Durumları
class ProjectStatus(enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    PENDING_REVIEW = "pending_review"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

# Proje-Yetenek İlişkisi (Many-to-Many)
project_skill_association = Table(
    'project_required_skills', Base.metadata,
    Column('project_id', UUID(as_uuid=True), ForeignKey('projects.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('skills.id'), primary_key=True)
)

# === YENİ SINIF: PROJE REVIZYONU ===
class ProjectRevision(Base):
    __tablename__ = "project_revisions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False)
    
    request_reason = Column(Text, nullable=False) # Revizyon sebebi
    requested_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # İlişki: Hangi projeye ait?
    project = relationship("Project", back_populates="revisions")
# ===================================

class Project(Base):
    __tablename__ = "projects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    title = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String, index=True, nullable=False)
    
    budget_min = Column(Integer, nullable=True)
    budget_max = Column(Integer, nullable=True)
    
    deadline = Column(DateTime(timezone=True), nullable=True)
    
    status = Column(String, default=ProjectStatus.OPEN.value)
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # İlişkiler
    owner = relationship("User", back_populates="projects")
    applications = relationship("Application", back_populates="project", cascade="all, delete-orphan")
    required_skills = relationship("Skill", secondary=project_skill_association, backref="projects")
    reviews = relationship("Review", back_populates="project")
    
    # === YENİ İLİŞKİ: REVIZYONLAR ===
    revisions = relationship("ProjectRevision", back_populates="project", order_by="desc(ProjectRevision.requested_at)", cascade="all, delete-orphan")
    # ================================

    @property
    def accepted_application(self):
        for app in self.applications:
            if str(app.status) == "accepted": # Enum string karşılaştırması
                return app
        return None