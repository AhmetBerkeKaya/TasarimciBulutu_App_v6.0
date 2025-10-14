import shutil
import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from typing import Optional
from uuid import UUID
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.portfolio import PortfolioItem as PortfolioItemSchema, PortfolioItemCreate, PortfolioItemUpdate
from app.crud import portfolio as portfolio_crud

router = APIRouter(prefix="/portfolio", tags=["Portfolio"])

# --- YENİ: İzin verilen dosya uzantıları ---
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "pdf", "dwg", "stl", "f3d", "step", "stp"}

def is_file_allowed(filename: str):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
# --- BİTTİ ---

@router.post("/items", response_model=PortfolioItemSchema, status_code=status.HTTP_201_CREATED)
def create_portfolio_item_for_current_user(
    title: str = Form(...),
    description: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    # --- YENİ: Dosya formatı kontrolü ---
    if not is_file_allowed(file.filename):
        raise HTTPException(status_code=400, detail=f"Desteklenmeyen dosya formatı. İzin verilenler: {', '.join(ALLOWED_EXTENSIONS)}")
    # --- BİTTİ ---

    file_extension = file.filename.split(".")[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = f"static/portfolio_files/{unique_filename}" # Klasör adını değiştirdik
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    item_data = PortfolioItemCreate(title=title, description=description)
    return portfolio_crud.create_portfolio_item(db=db, item=item_data, user_id=current_user.id, file_url=file_path)

@router.put("/items/{item_id}", response_model=PortfolioItemSchema)
def update_portfolio_item(
    item_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
    # --- DEĞİŞİKLİK: Form verilerini ve opsiyonel dosyayı al ---
    title: str = Form(...),
    description: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None)
):
    db_item = portfolio_crud.get_portfolio_item(db, item_id=item_id)
    if not db_item or db_item.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Portfolio item not found or not authorized")

    file_url = db_item.image_url # Varsayılan olarak eski dosya yolunu koru

    # Eğer yeni bir dosya yüklendiyse...
    if file:
        if not is_file_allowed(file.filename):
             raise HTTPException(status_code=400, detail="Unsupported file type.")
        
        # Eski dosyayı diskten sil
        if os.path.exists(db_item.image_url):
            os.remove(db_item.image_url)
            
        # Yeni dosyayı kaydet
        file_extension = file.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_url = f"static/portfolio_files/{unique_filename}"
        with open(file_url, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    
    # Veritabanını yeni verilerle güncelle
    item_in = PortfolioItemUpdate(title=title, description=description)
    return portfolio_crud.update_portfolio_item(db, db_item=db_item, item_in=item_in, new_file_url=file_url)

@router.delete("/items/{item_id}", response_model=PortfolioItemSchema)
def delete_portfolio_item_for_current_user(
    item_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    db_item = portfolio_crud.get_portfolio_item(db, item_id=item_id)
    if not db_item:
        raise HTTPException(status_code=404, detail="Portfolio item not found")
    if db_item.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this item")
    
    # TODO: Diskteki fiziksel dosyayı da silmek iyi bir pratiktir (os.remove(db_item.image_url))
    return portfolio_crud.delete_portfolio_item(db, db_item=db_item)

# Not: /users/{user_id}/items endpoint'i artık gereksiz, çünkü bu bilgiyi /users/me ile alıyoruz.
# İstersen bu endpoint'i silebilirsin.