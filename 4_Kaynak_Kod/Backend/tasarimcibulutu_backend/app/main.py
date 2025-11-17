# main.py

import logging
import sys
from fastapi import FastAPI, Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware 
from slowapi.util import get_remote_address
from fastapi.staticfiles import StaticFiles

# --- DÜZELTME 1: IMPORT YOLLARI ---
# Dosya artık ana dizinde olduğu için 'app.' diyerek tam yolunu göstermeliyiz.
# Eskiden: from .config import settings
from app.config import settings 
from app import models
from app.database import engine

# Router importları (Zaten doğruydu ama kontrol ettik)
from app.routers import (
    user, project, application, auth, message, notification, 
    skill_test, skill, portfolio, work_experience, review, 
    showcase, recommendation
)

# --- DÜZELTME 2: LOGGING ---
# Basit ve temiz bir log yapısı. Render/Railway konsoluna basması yeterli.
logging.basicConfig(
    level=logging.INFO, 
    stream=sys.stdout, 
    format='%(asctime)s %(levelname)s %(message)s', 
    datefmt='%Y-%m-%dT%H:%M:%S%z'
)
logger = logging.getLogger(__name__)

# Rate Limiter Ayarı
limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])

# --- DÜZELTME 3: TABLO OLUŞTURMA ---
# Bu satır Supabase veritabanında tabloların yoksa oluşmasını sağlar.
# İlk çalıştırma için çok kritik.
# models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="TasarimciBulutu API",
    description="CAD tasarımcıları ve firmalar için proje eşleştirme platformu.",
    version="1.0.0",
)

# Uygulama başladığında log atalım
logger.info("TasarimciBulutu API (Non-AWS Version) başlatılıyor...")

# Rate Limiter Entegrasyonu
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Statik Dosyalar (Resim vs. için geçici çözüm, sonra Cloudinary'ye geçeceğiz)
# 'static' klasörü yoksa hata vermemesi için try-except bloğu iyi olur ama şimdilik kalsın.
app.mount("/static", StaticFiles(directory="static"), name="static")

# Router'ları Dahil Etme
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(project.router)
app.include_router(application.router)
app.include_router(message.router)
app.include_router(notification.router)
app.include_router(skill_test.router)
app.include_router(skill.router)
app.include_router(portfolio.router)
app.include_router(work_experience.router)
app.include_router(review.router)
app.include_router(showcase.router)
app.include_router(recommendation.router)

@app.get("/")
@limiter.limit("10/minute")
def read_root(request: Request):
    logger.info("Ana sayfa isteği alındı.")
    return {"message": "Welcome to TasarimciBulutu API (Free Tier Edition)"}

# --- DÜZELTME 4: AWS LAMBDA IPTALI ---
# Mangum'u sildik çünkü artık Lambda kullanmıyoruz.
# handler = Mangum(app)  <-- Buna gerek kalmadı.