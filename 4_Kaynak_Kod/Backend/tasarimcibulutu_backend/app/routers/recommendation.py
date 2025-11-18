# app/routers/recommendation.py (GÜNCEL)

from typing import List
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status, Request
from sqlalchemy.orm import Session

from app.crud import recommendation
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.recommendation import ProjectRecommendationOut

# YENİ EKLENEN IMPORTLAR
from app.utils import recommender_engine
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

router = APIRouter(
    prefix="/recommendations",
    tags=["recommendations"]
)

# =====================================================================
# ===            YENİ: ÖNERİ MOTORUNU TETİKLEME (MANUEL)            ===
# =====================================================================
@router.post("/calculate", status_code=status.HTTP_202_ACCEPTED)
@limiter.limit("5/hour") # Çok sık çalıştırılmasını engellemek için limit
def trigger_recommendation_engine(
    request: Request,  # <--- BU SATIRI EKLEMEN GEREKİYOR
    background_tasks: BackgroundTasks,
    current_user: UserModel = Depends(get_current_user) # Sadece giriş yapmış kullanıcılar
):
    """
    Öneri motorunu manuel olarak tetikler. 
    Bu işlem asenkron olarak arka planda çalışır.
    """
    # İsteğe bağlı: Sadece adminler çalıştırabilsin diye kontrol eklenebilir.
    # if current_user.role != "admin": raise HTTPException(...)
    
    background_tasks.add_task(recommender_engine.run_recommendation_engine_background)
    
    return {"message": "Recommendation engine started in background."}
# =====================================================================


@router.get("/me", response_model=List[ProjectRecommendationOut])
def read_my_recommendations(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan kullanıcı için kişiselleştirilmiş proje önerilerini getirir.
    """
    # Eğer hiç öneri yoksa, belki de motoru o an tetiklemek iyi bir fikir olabilir?
    # Ama şimdilik sadece olanı getirsin.
    recommendations = recommendation.get_recommendations_for_user(db, user_id=current_user.id)
    
    response_data = [
        {"score": rec.score, "project": rec.project} for rec in recommendations
    ]
    return response_data