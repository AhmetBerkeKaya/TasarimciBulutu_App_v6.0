# app/models/portfolio.py

import uuid
# Table importunu ekliyoruz
from sqlalchemy import Column, String, Text, ForeignKey, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

# ================== YENİ ARA TABLO ==================
# Portfolyo ve Yetenekler arasındaki ilişki için ara tablo
portfolio_item_skill_association = Table(
    'portfolio_item_skills', Base.metadata,
    Column('portfolio_item_id', UUID(as_uuid=True), ForeignKey('portfolio_items.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('skills.id'), primary_key=True)
)
# ====================================================

class PortfolioItem(Base):
    __tablename__ = "portfolio_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    image_url = Column(String, nullable=False)

    owner = relationship("User", back_populates="portfolio_items")

    # ================== YENİ İLİŞKİ ==================
    # Bir portfolyo elemanının sergilediği yeteneklerin listesi
    demonstrated_skills = relationship("Skill", secondary=portfolio_item_skill_association)
    # ================================================