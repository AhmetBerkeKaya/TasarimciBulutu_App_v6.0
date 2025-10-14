# app/crud/review.py
import uuid
from sqlalchemy.orm import Session
from sqlalchemy import and_

# --- YENİ İMPORTLAR ---
from app import models, schemas, crud
from app.models.notification import NotificationType
# --- BİTTİ ---


def get_review_by_reviewer_and_project(db: Session, reviewer_id: uuid.UUID, project_id: uuid.UUID):
    """Kullanıcının bir proje için daha önce yorum yapıp yapmadığını kontrol eder."""
    return db.query(models.Review).filter(
        and_(
            models.Review.reviewer_id == reviewer_id,
            models.Review.project_id == project_id
        )
    ).first()


# --- GÜNCELLENMİŞ FONKSİYON ---
def create_review(db: Session, review: schemas.ReviewCreate, reviewer_id: uuid.UUID) -> models.Review:
    """Yeni bir değerlendirme oluşturur ve değerlendirilen kullanıcıya bildirim gönderir."""
    # 1. Adım: Değerlendirmeyi veritabanına kaydet
    db_review = models.Review(
        **review.model_dump(),
        reviewer_id=reviewer_id
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)

    # 2. Adım: Değerlendirilen kullanıcıya bildirim gönder
    try:
        # Kişinin kendi kendine yaptığı bir değerlendirme için bildirim gönderme
        if review.reviewee_id == reviewer_id:
            return db_review

        reviewer = db.query(models.User).filter(models.User.id == reviewer_id).first()
        if reviewer:
            notification_content = f"{reviewer.name}, projeniz hakkındaki değerlendirmesini paylaştı."
            
            crud.notification.create_notification(
                db=db,
                user_id=review.reviewee_id,     # Bildirimi alacak kişi (değerlendirilen)
                actor_id=reviewer_id,           # Eylemi yapan kişi (değerlendiren)
                type=NotificationType.NEW_REVIEW,
                content=notification_content,
                related_entity_id=review.project_id # Tıklayınca projeye gitmesi için
            )

    except Exception as e:
        print(f"Değerlendirme sonrası bildirim oluşturulurken hata oluştu: {e}")

    # 3. Adım: Oluşturulan review nesnesini döndür
    return db_review