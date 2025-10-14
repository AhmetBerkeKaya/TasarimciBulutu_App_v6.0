# app/schemas/notification.py - GÜNCELLENMİŞ HALİ

from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict

from app.models.notification import NotificationType

# --- İç İçe Kullanılacak Yardımcı Şemalar ---
class UserSummary(BaseModel):
    id: UUID
    name: str
    model_config = ConfigDict(from_attributes=True)

# --- Ana Bildirim Şemaları ---
class NotificationBase(BaseModel):
    type: NotificationType
    content: str
    related_entity_id: UUID | None = None

class Notification(NotificationBase):
    id: UUID
    is_read: bool
    created_at: datetime
    actor: UserSummary | None = None
    model_config = ConfigDict(from_attributes=True)

# ================= YENİ EKLENEN ŞEMALAR =================
# Okunmamış bildirim sayısını döndürmek için kullanılacak.
class UnreadNotificationCount(BaseModel):
    unread_count: int

# Tümünü okundu olarak işaretleme işleminden sonra dönecek mesaj için.
class MarkAllReadResponse(BaseModel):
    message: str
    updated_count: int
# ========================================================