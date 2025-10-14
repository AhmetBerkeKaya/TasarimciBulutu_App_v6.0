# app/schemas/skill.py
from pydantic import BaseModel, UUID4

# API üzerinden yeni yetenek oluşturmak için kullanılacak temel şema
# Şimdilik kullanmıyoruz ama iyi bir pratik.
class SkillBase(BaseModel):
    name: str
    category: str

class SkillCreate(SkillBase):
    pass

# API'den yanıt olarak dönecek tam Skill modeli
class Skill(SkillBase):
    id: UUID4

    class Config:
        from_attributes = True # Pydantic v2'de bu şekilde kullanılır