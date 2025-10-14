# app/schemas/message.py
from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime
from .user import UserInResponse # Kullanıcı özet şemasını import ediyoruz

class MessageBase(BaseModel):
    receiver_id: UUID4
    content: str

class MessageCreate(MessageBase):
    # sender_id'yi buradan kaldırdık, çünkü token'dan gelecek
    pass

class MessageUpdate(BaseModel):
    is_read: Optional[bool] = None

# API'den dönecek zenginleştirilmiş Mesaj modeli
class Message(BaseModel):
    id: UUID4
    content: str
    is_read: bool
    created_at: datetime
    
    # Mesajı okurken gönderen ve alanın kim olduğunu bilmek isteriz
    sender: UserInResponse
    receiver: UserInResponse

    class Config:
        from_attributes = True