# main.py

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
# YENİ: Middleware'i artık kullanacağız.
from slowapi.middleware import SlowAPIMiddleware 
from .config import settings
from slowapi.util import get_remote_address # get_remote_address'ı da import edelim

from app.routers import user, project, application, auth, message, notification, skill_test, skill, portfolio, work_experience, review, showcase, recommendation
from fastapi.staticfiles import StaticFiles
from . import models
from .database import engine


# --- GÜNCELLENMİŞ RATE LIMITER KURULUMU ---
# Limiter'ı key_func olmadan başlatabiliriz, middleware kendisi halledecek.
# VEYA IP adresine göre olmasını istiyorsak get_remote_address kullanabiliriz.
limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])
# default_limits: Tüm endpoint'ler için geçerli olacak genel limit.
# --- GÜNCELLENMİŞ RATE LIMITER KURULUMU SONU ---


models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="TasarimciBulutu API",
    description="CAD tasarımcıları ve firmalar için proje eşleştirme platformu.",
    version="1.0.0",
)

# --- GÜNCELLENMİŞ RATE LIMITER'I UYGULAMAYA EKLEME ---
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# YENİ: Middleware'i artık aktif olarak kullanıyoruz.
# Bu satır, yukarıda tanımlanan "default_limits"i tüm endpoint'lere uygular.
app.add_middleware(SlowAPIMiddleware)
# --- GÜNCELLENMİŞ RATE LIMITER'I UYGULAMAYA EKLEME SONU ---


app.mount("/static", StaticFiles(directory="static"), name="static")

# API Router'larını uygulamaya dahil etme
# (Burada bir değişiklik yok)
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
# Bu özel limit, global limiti ezer.
@limiter.limit("10/minute")
def read_root(request: Request):
    return {"message": "Welcome to TasarimciBulutu API"}
