import enum
import uuid
from datetime import timezone , datetime
from sqlalchemy import Column, Text, Numeric, Integer, DateTime, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy import func

class ApplicationStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class Application(Base):
    __tablename__ = "applications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False)
    freelancer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    cover_letter = Column(Text, nullable=True)
    proposed_budget = Column(Numeric, nullable=True)
    proposed_duration = Column(Integer, nullable=True)
    status = Column(Enum(ApplicationStatus), default=ApplicationStatus.pending, nullable=False)
    
    # created_at sütununu veritabanı varsayılanı ile değiştiriyoruz
    created_at = Column(DateTime(timezone=True), nullable=False)
    project = relationship("Project", back_populates="applications")
    freelancer = relationship("User", back_populates="applications")