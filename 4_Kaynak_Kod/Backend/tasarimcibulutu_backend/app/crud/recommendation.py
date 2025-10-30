# app/crud/recommendation.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
from typing import List
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc
from uuid import UUID
from app import models

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def get_recommendations_for_user(db: Session, user_id: UUID, limit: int = 10) -> List[models.ProjectRecommendation]:
    """
    Belirli bir kullanıcı için en yüksek puanlı proje önerilerini getirir.
    ProjectRecommendation ve ilişkili Project verilerini birlikte çeker.
    """
    logger.info(f"Proje önerileri getiriliyor: KullanıcıID={user_id}, Limit={limit}") # <-- EKLENDİ
    try:
        recommendations = (
            db.query(models.ProjectRecommendation)
            .join(models.Project) # Project tablosuyla birleştir
            .options(joinedload(models.ProjectRecommendation.project).joinedload(models.Project.owner)) # Proje ve sahibini de yükle
            .filter(models.ProjectRecommendation.user_id == user_id)
            .order_by(desc(models.ProjectRecommendation.score)) # Puana göre büyükten küçüğe sırala
            .limit(limit)
            .all()
        )
        logger.info(f"Proje önerileri başarıyla getirildi: KullanıcıID={user_id}, Bulunan={len(recommendations)}") # <-- EKLENDİ
        return recommendations
    except Exception as e:
        logger.error(f"Proje önerileri getirilirken HATA: KullanıcıID={user_id}. Hata: {e}") # <-- EKLENDİ
        return [] # Hata durumunda boş liste döndür