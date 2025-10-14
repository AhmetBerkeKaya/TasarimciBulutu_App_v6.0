# app/routers/recommendation.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.crud import recommendation
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.recommendation import ProjectRecommendationOut

router = APIRouter(
    prefix="/recommendations",
    tags=["recommendations"]
)

@router.get("/me", response_model=List[ProjectRecommendationOut])
def read_my_recommendations(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan kullanıcı için kişiselleştirilmiş proje önerilerini getirir.
    """
    recommendations = recommendation.get_recommendations_for_user(db, user_id=current_user.id)
    
    # Gelen sonucu response modelimize uygun hale getiriyoruz
    response_data = [
        {"score": rec.score, "project": rec.project} for rec in recommendations
    ]
    return response_data