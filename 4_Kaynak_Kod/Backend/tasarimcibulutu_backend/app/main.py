# main.py

# YENİ EKLENDİ: AWS Lambda adaptörü
from mangum import Mangum

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware 
from .config import settings
from slowapi.util import get_remote_address

from app.routers import user, project, application, auth, message, notification, skill_test, skill, portfolio, work_experience, review, showcase, recommendation
from fastapi.staticfiles import StaticFiles
from . import models
from .database import engine


limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])

# Bu satır, staj raporunuzda (Sayfa 17) bahsettiğiniz Alembic'in
# production ortamında yönetmesi gerektiği için opsiyoneldir.
# Lambda'nın her soğuk başlatmada bunu çalıştırması ideal değildir,
# ancak geliştirme için bir sakıncası yok.
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="TasarimciBulutu API",
    description="CAD tasarımcıları ve firmalar için proje eşleştirme platformu.",
    version="1.0.0",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(SlowAPIMiddleware)

# Static dosyaları AWS üzerinde (S3/CloudFront) sunmak daha iyidir
# ancak bu kurulum da çalışacaktır.
app.mount("/static", StaticFiles(directory="static"), name="static")

# API Router'larını uygulamaya dahil etme
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
    return {"message": "Welcome to TasarimciBulutu API"}

# YENİ EKLENDİ: FastAPI 'app' nesnesini Mangum ile sarmala
# ve 'handler' olarak dışa aktar.
handler = Mangum(app)