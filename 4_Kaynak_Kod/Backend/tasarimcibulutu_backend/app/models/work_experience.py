# app/models/work_experience.py
import uuid
from sqlalchemy import Column, String, Text, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class WorkExperience(Base):
    __tablename__ = "work_experiences"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False) # Pozisyon (örn: Makine Mühendisi)
    company_name = Column(String, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True) # Boş olabilir (halen çalışıyor)
    description = Column(Text, nullable=True)

    owner = relationship("User", back_populates="work_experiences")