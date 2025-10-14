# app/schemas/recommendation.py

from pydantic import BaseModel, ConfigDict
from .project import Project  # Mevcut Project şemasını import ediyoruz

class ProjectRecommendationOut(BaseModel):
    score: float
    project: Project

    model_config = ConfigDict(from_attributes=True)