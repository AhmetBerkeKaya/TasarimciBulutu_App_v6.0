# app/crud/review.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
import uuid
from sqlalchemy.orm import Session
from sqlalchemy import and_

# --- YENİ İMPORTLAR ---
from app import models, schemas, crud
from app.models.notification import NotificationType
# --- BİTTİ ---

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def get_review_by_reviewer_and_project(db: Session, reviewer_id: uuid.UUID, project_id: uuid.UUID):
    """Kullanıcının bir proje için daha önce yorum yapıp yapmadığını kontrol eder."""
    return db.query(models.Review).filter(
        and_(
            models.Review.reviewer_id == reviewer_id,
            models.Review.project_id == project_id
        )
    ).first()


# --- GÜNCELLENMİŞ FONKSİYON (Loglama ve Hata Yönetimi) ---
def create_review(db: Session, review: schemas.ReviewCreate, reviewer_id: uuid.UUID) -> models.Review | None:
    """Yeni bir değerlendirme oluşturur ve değerlendirilen kullanıcıya bildirim gönderir."""
    logger.info(f"Yeni değerlendirme oluşturuluyor: ProjeID={review.project_id}, DeğerlendirenID={reviewer_id}, DeğerlendirilenID={review.reviewee_id}") # <-- EKLENDİ
    
    try:
        # 1. Adım: Değerlendirmeyi veritabanına kaydet
        db_review = models.Review(
            **review.model_dump(),
            reviewer_id=reviewer_id
        )
        db.add(db_review)
        db.commit()
        db.refresh(db_review)
        
        logger.info(f"Değerlendirme başarıyla oluşturuldu: ID={db_review.id}, ProjeID={review.project_id}") # <-- EKLENDİ

    except Exception as e:
        logger.error(f"Değerlendirme veritabanına kaydedilirken HATA: ProjeID={review.project_id}, DeğerlendirenID={reviewer_id}. Hata: {e}") # <-- EKLENDİ
        db.rollback()
        return None

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
        # print() -> logger.error() olarak değiştirildi
        logger.error(f"Değerlendirme (ID={db_review.id}) sonrası bildirim oluşturulurken HATA: {e}") # <-- GÜNCELLENDİ

    # 3. Adım: Oluşturulan review nesnesini döndür
    return db_review


def get_reviews_for_user(db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100):
    """Belirli bir kullanıcının aldığı tüm değerlendirmeleri en yeniden eskiye doğru getirir."""
    return db.query(models.Review)\
        .filter(models.Review.reviewee_id == user_id)\
        .order_by(models.Review.created_at.desc())\
        .offset(skip).limit(limit).all()