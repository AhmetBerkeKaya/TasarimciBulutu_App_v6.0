# app/crud/portfolio.py (DÜZELTİLMİŞ HALİ)

import logging
from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional

from app.models.portfolio import PortfolioItem
from app.schemas.portfolio import PortfolioItemCreate, PortfolioItemUpdate

# === LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# ==============

def get_portfolio_item(db: Session, item_id: UUID) -> PortfolioItem | None:
    return db.query(PortfolioItem).filter(PortfolioItem.id == str(item_id)).first()

# --- DÜZELTME BURADA ---
# Parametre adını 'image_url' -> 'file_url' olarak değiştirdik.
# Böylece Router'dan gelen "file_url=..." çağrısını kabul edecek.
def create_portfolio_item(db: Session, item: PortfolioItemCreate, user_id: UUID, file_url: str) -> PortfolioItem | None:
    logger.info(f"Yeni portfolyo öğesi oluşturuluyor: KullanıcıID={user_id}, Başlık='{item.title}'")
    try:
        db_item = PortfolioItem(
            **item.model_dump(),
            user_id=user_id,
            image_url=file_url # Veritabanı kolonu 'image_url', biz 'file_url' değişkenini atıyoruz.
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        logger.info(f"Portfolyo öğesi başarıyla oluşturuldu: ID={db_item.id}, KullanıcıID={user_id}")
        return db_item
    except Exception as e:
        logger.error(f"Portfolyo öğesi oluşturulurken HATA: KullanıcıID={user_id}. Hata: {e}")
        db.rollback()
        return None

def update_portfolio_item(
    db: Session, 
    db_item: PortfolioItem, 
    item_in: PortfolioItemUpdate, 
    new_file_url: Optional[str] = None
) -> PortfolioItem | None:
    item_id = db_item.id
    logger.info(f"Portfolyo öğesi güncelleniyor: ID={item_id}")
    try:
        update_data = item_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_item, key, value)
        
        # Eğer yeni bir dosya yolu varsa, onu da güncelle
        if new_file_url:
            db_item.image_url = new_file_url
            
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        logger.info(f"Portfolyo öğesi başarıyla güncellendi: ID={item_id}")
        return db_item
    except Exception as e:
        logger.error(f"Portfolyo öğesi (ID={item_id}) güncellenirken HATA: {e}")
        db.rollback()
        return None

def delete_portfolio_item(db: Session, db_item: PortfolioItem) -> PortfolioItem | None:
    item_id = db_item.id
    logger.info(f"Portfolyo öğesi siliniyor: ID={item_id}")
    try:
        db.delete(db_item)
        db.commit()
        logger.info(f"Portfolyo öğesi başarıyla silindi: ID={item_id}")
        return db_item
    except Exception as e:
        logger.error(f"Portfolyo öğesi (ID={item_id}) silinirken HATA: {e}")
        db.rollback()
        return None