# app/crud/recommendation.py

from typing import List
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc
from uuid import UUID
from app import models

def get_recommendations_for_user(db: Session, user_id: UUID, limit: int = 10) -> List[models.ProjectRecommendation]:
    """
    Belirli bir kullanıcı için en yüksek puanlı proje önerilerini getirir.
    ProjectRecommendation ve ilişkili Project verilerini birlikte çeker.
    """
    recommendations = (
        db.query(models.ProjectRecommendation)
        .join(models.Project) # Project tablosuyla birleştir
        .options(joinedload(models.ProjectRecommendation.project).joinedload(models.Project.owner)) # Proje ve sahibini de yükle
        .filter(models.ProjectRecommendation.user_id == user_id)
        .order_by(desc(models.ProjectRecommendation.score)) # Puana göre büyükten küçüğe sırala
        .limit(limit)
        .all()
    )
    return recommendations