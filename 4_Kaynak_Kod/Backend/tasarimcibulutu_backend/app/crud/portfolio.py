from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional

from app.models.portfolio import PortfolioItem
from app.schemas.portfolio import PortfolioItemCreate, PortfolioItemUpdate
from app.schemas import work_experience
def get_portfolio_item(db: Session, item_id: UUID) -> PortfolioItem | None:
    return db.query(PortfolioItem).filter(PortfolioItem.id == str(item_id)).first()

def create_portfolio_item(db: Session, item: PortfolioItemCreate, user_id: UUID, image_url: str) -> PortfolioItem:
    # --- DÜZELTME: Sondaki fazladan virgül kaldırıldı ---
    db_item = PortfolioItem(
        **item.model_dump(),
        user_id=user_id,
        image_url=image_url
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

def update_portfolio_item(
    db: Session, 
    db_item: PortfolioItem, 
    item_in: work_experience.WorkExperienceUpdate, # Şema adını düzeltelim
    new_file_url: Optional[str] = None
) -> PortfolioItem:
    update_data = item_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_item, key, value)
    
    # Eğer yeni bir dosya yolu varsa, onu da güncelle
    if new_file_url:
        db_item.image_url = new_file_url
        
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item
def delete_portfolio_item(db: Session, db_item: PortfolioItem) -> PortfolioItem:
    db.delete(db_item)
    db.commit()
    return db_item