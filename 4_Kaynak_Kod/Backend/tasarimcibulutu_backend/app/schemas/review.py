# app/schemas/review.py

import uuid
from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
# from .user import User  # <-- BU SATIRI SİLİN VEYA YORUMA ALIN

class ProjectInReview(BaseModel):
    id: uuid.UUID
    title: str

    model_config = ConfigDict(from_attributes=True)
        
class ReviewBase(BaseModel):
    rating: int = Field(..., gt=0, lt=6) # 1-5 arası puanlama için
    comment: str | None = None

class ReviewCreate(ReviewBase):
    project_id: uuid.UUID
    reviewee_id: uuid.UUID # Değerlendirilen kişinin ID'si

# API'dan yanıt olarak dönecek tam Review modeli
class Review(ReviewBase):
    id: uuid.UUID
    reviewer: 'UserSummary' 
    
    # --- DEĞİŞİKLİK BURADA ---
    # Artık ProjectInReview'i import etmediğimiz için
    # bunu da string olarak referans göstermeliyiz.
    project: 'ProjectInReview'
    
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
