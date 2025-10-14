import uuid
from datetime import datetime
from sqlalchemy import Column, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy import func # func'ı import et


class Message(Base):
    __tablename__ = "messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sender_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    receiver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # --- YENİ EKLENEN SÜTUNLAR ---
    deleted_by_sender = Column(Boolean, default=False, nullable=False)
    deleted_by_receiver = Column(Boolean, default=False, nullable=False)
    # --- BİTTİ ---

    sender = relationship("User", back_populates="sent_messages", foreign_keys=[sender_id])
    receiver = relationship("User", back_populates="received_messages", foreign_keys=[receiver_id])