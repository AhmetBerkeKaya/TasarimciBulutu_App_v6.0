from pydantic import BaseModel, UUID4
from typing import Optional

class PortfolioItemBase(BaseModel):
    title: str
    description: Optional[str] = None

class PortfolioItemCreate(PortfolioItemBase):
    pass

# --- YENİ EKLENEN SINIF ---
class PortfolioItemUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
# --- BİTTİ ---

class PortfolioItem(PortfolioItemBase):
    id: UUID4
    image_url: str # Bu alan artık genel bir 'file_url' gibi düşünülebilir

    class Config:
        from_attributes = True