# app/routers/notification.py

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List
from app import crud, models, schemas
from app.dependencies import get_current_user, get_db
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(
    prefix="/notifications",
    tags=["notifications"],
    responses={404: {"description": "Not found"}},
)


@router.get("/me", response_model=List[schemas.Notification])
@limiter.limit("60/minute")
def read_notifications_for_current_user(
    request: Request,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Oturum açmış kullanıcının bildirimlerini listeler.
    En yeniden eskiye doğru sıralıdır.
    """
    notifications = crud.notification.get_notifications_by_user(
        db, user_id=current_user.id, skip=skip, limit=limit
    )
    return notifications


@router.get("/unread-count", response_model=schemas.UnreadNotificationCount)
def get_unread_count(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Oturum açmış kullanıcının okunmamış bildirim sayısını döndürür.
    """
    count = crud.notification.get_unread_notification_count(db, user_id=current_user.id)
    return {"unread_count": count}


@router.post("/{notification_id}/read", response_model=schemas.Notification)
def mark_as_read(
    notification_id: UUID,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Belirli bir bildirimi okundu olarak işaretler.
    Kullanıcılar sadece kendi bildirimlerini işaretleyebilir.
    """
    notification = crud.notification.mark_notification_as_read(
        db, notification_id=notification_id, user_id=current_user.id
    )
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found or you do not have permission to access it.",
        )
    return notification


@router.post("/read-all", response_model=schemas.MarkAllReadResponse)
def mark_all_as_read(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Oturum açmış kullanıcının tüm okunmamış bildirimlerini okundu olarak işaretler.
    """
    updated_count = crud.notification.mark_all_notifications_as_read(
        db, user_id=current_user.id
    )
    return {
        "message": "All unread notifications have been marked as read.",
        "updated_count": updated_count,
    }