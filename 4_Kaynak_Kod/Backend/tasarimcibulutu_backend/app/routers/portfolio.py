# app/routers/portfolio.py (GÜNCELLENMİŞ)

import os
import uuid
import requests
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from typing import Optional
from uuid import UUID
from supabase import create_client, Client

from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.portfolio import PortfolioItem as PortfolioItemSchema, PortfolioItemCreate, PortfolioItemUpdate
from app.crud import portfolio as portfolio_crud
from app.utils import s3 as s3_utils # Akıllı URL oluşturucumuz
from app.config import settings

router = APIRouter(prefix="/portfolio", tags=["Portfolio"])

ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "pdf", "dwg", "stl", "f3d", "step", "stp"}

def is_file_allowed(filename: str):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

# --- YARDIMCI FONKSİYON: DOSYAYI BULUTA YÜKLE ---
async def upload_file_to_cloud(file: UploadFile) -> str:
    """
    Dosyayı okur, türüne göre Cloudinary veya Supabase'e yükler
    ve erişilebilir Public URL'i döner.
    """
    file_content = await file.read()
    filename = file.filename
    file_ext = filename.split(".")[-1].lower()
    
    # Benzersiz bir dosya yolu oluştur
    unique_filename = f"{uuid.uuid4()}.{file_ext}"
    # Portfolyo dosyaları için sanal bir klasör yolu
    object_name = f"portfolio/{unique_filename}"

    # s3_utils bizim trafik polisimizdi. Ona soruyoruz: "Bu dosya nereye gitmeli?"
    # Not: s3_utils içindeki mantığı burada manuel uyguluyoruz çünkü s3_utils
    # frontend için imzalı URL dönüyor, biz ise burada backend'den yükleme yapacağız.
    
    # DURUM A: RESİM (Cloudinary)
    if file_ext in ["jpg", "jpeg", "png"]:
        # s3_utils'den imza ve parametreleri alalım
        presigned_data = s3_utils.create_presigned_post_url(
            bucket_name="portfolio", # Cloudinary folder
            object_name=object_name
        )
        
        # Cloudinary'ye POST isteği at (Backend -> Cloudinary)
        # presigned_data['url'] = https://api.cloudinary.com/...
        # presigned_data['fields'] = api_key, signature, timestamp vb.
        
        files = {'file': (unique_filename, file_content)}
        response = requests.post(presigned_data['url'], data=presigned_data['fields'], files=files)
        
        if response.status_code == 200:
            return response.json()['secure_url']
        else:
            print(f"Cloudinary Upload Error: {response.text}")
            raise HTTPException(status_code=500, detail="Resim yüklenirken hata oluştu.")

    # DURUM B: DİĞER DOSYALAR (Supabase Storage)
    else:
        try:
            supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
            bucket_name = "raw-files" # Supabase'de açtığımız bucket
            
            # Supabase'e yükle
            # Content-Type'ı otomatik algılaması için file_options boş bırakılabilir veya manuel verilebilir.
            res = supabase.storage.from_(bucket_name).upload(
                path=object_name,
                file=file_content,
                file_options={"content-type": file.content_type or "application/octet-stream"}
            )
            
            # Public URL oluştur
            project_id = settings.SUPABASE_URL.split("https://")[1].split(".")[0]
            public_url = f"https://{project_id}.supabase.co/storage/v1/object/public/{bucket_name}/{object_name}"
            return public_url
            
        except Exception as e:
            print(f"Supabase Upload Error: {e}")
            raise HTTPException(status_code=500, detail=f"Dosya yüklenirken hata oluştu: {str(e)}")

# ------------------------------------------------

@router.post("/items", response_model=PortfolioItemSchema, status_code=status.HTTP_201_CREATED)
async def create_portfolio_item_for_current_user(
    title: str = Form(...),
    description: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    if not is_file_allowed(file.filename):
        raise HTTPException(status_code=400, detail=f"Desteklenmeyen dosya formatı. İzin verilenler: {', '.join(ALLOWED_EXTENSIONS)}")

    # 1. Dosyayı Buluta Yükle (Yeni Fonksiyonu Kullanıyoruz)
    file_url = await upload_file_to_cloud(file)

    # 2. Veritabanına Kaydet
    item_data = PortfolioItemCreate(title=title, description=description)
    return portfolio_crud.create_portfolio_item(db=db, item=item_data, user_id=current_user.id, file_url=file_url)

@router.put("/items/{item_id}", response_model=PortfolioItemSchema)
async def update_portfolio_item(
    item_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
    title: str = Form(...),
    description: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None)
):
    db_item = portfolio_crud.get_portfolio_item(db, item_id=item_id)
    if not db_item or db_item.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Portfolio item not found or not authorized")

    file_url = db_item.image_url # Varsayılan: eski URL kalsın

    # Eğer yeni bir dosya yüklendiyse...
    if file:
        if not is_file_allowed(file.filename):
             raise HTTPException(status_code=400, detail="Unsupported file type.")
        
        # 1. Yeni Dosyayı Buluta Yükle
        file_url = await upload_file_to_cloud(file)
        
        # Not: Eski dosyayı Cloudinary/Supabase'den silmek iyi bir pratiktir ama 
        # "Bebek adımları" için şimdilik o kısmı atlıyoruz.
    
    # 2. Veritabanını Güncelle
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
    
    return portfolio_crud.delete_portfolio_item(db, db_item=db_item)