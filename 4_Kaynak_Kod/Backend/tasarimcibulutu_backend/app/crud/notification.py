# app/crud/notification.py

from uuid import UUID
from sqlalchemy.orm import Session, joinedload

from app import models, schemas
from app.models.notification import NotificationType


def get_notifications_by_user(db: Session, user_id: UUID, skip: int = 0, limit: int = 20) -> list[models.Notification]:
    """
    Belirli bir kullanıcının bildirimlerini, en yeniden eskiye doğru listeler.
    `actor` bilgisini de verimli bir şekilde yükler (N+1 problemini önler).
    """
    return (
        db.query(models.Notification)
        .options(joinedload(models.Notification.actor)) # Actor bilgisini tek sorguda getir
        .filter(models.Notification.user_id == user_id)
        .order_by(models.Notification.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_unread_notification_count(db: Session, user_id: UUID) -> int:
    """
    Belirli bir kullanıcının okunmamış bildirimlerinin sayısını döndürür.
    """
    return (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user_id, models.Notification.is_read == False)
        .count()
    )


def create_notification(
    db: Session,
    *,
    user_id: UUID,         # Bildirimi alacak kullanıcı
    type: NotificationType,
    content: str,
    actor_id: UUID | None = None, # Eylemi yapan kullanıcı (isteğe bağlı)
    related_entity_id: UUID | None = None # İlgili varlık ID'si (isteğe bağlı)
) -> models.Notification:
    """
    Veritabanına yeni bir bildirim kaydı oluşturur.
    Bu fonksiyon, diğer servisler tarafından (örn: yeni mesaj, yeni başvuru) çağrılmalıdır.
    """
    db_notification = models.Notification(
        user_id=user_id,
        actor_id=actor_id,
        type=type,
        content=content,
        related_entity_id=related_entity_id,
    )
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)

    # TODO: Bu noktada, anlık bildirim (push notification) için
    # AWS SNS'e bir mesaj yayınlama mantığı eklenebilir.

    return db_notification


def mark_notification_as_read(db: Session, *, notification_id: UUID, user_id: UUID) -> models.Notification | None:
    """
    Tek bir bildirimi okundu olarak işaretler.
    Kullanıcının sadece kendi bildirimlerini işaretleyebilmesini sağlar.
    """
    notification = (
        db.query(models.Notification)
        .filter(models.Notification.id == notification_id, models.Notification.user_id == user_id)
        .first()
    )
    if notification:
        notification.is_read = True
        db.commit()
        db.refresh(notification)
    return notification


def mark_all_notifications_as_read(db: Session, *, user_id: UUID) -> int:
    """

    Bir kullanıcının tüm okunmamış bildirimlerini tek seferde okundu olarak işaretler.
    Verimlilik için toplu güncelleme (bulk update) yapar.
    """
    num_updated = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user_id, models.Notification.is_read == False)
        .update({"is_read": True}, synchronize_session=False)
    )
    db.commit()
    return num_updated