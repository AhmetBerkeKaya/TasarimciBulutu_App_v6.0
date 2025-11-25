# app/routers/admin.py

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_ , and_
from app import database
from app.routers.auth import get_db # DB Dependency
from app import security # Oauth2 scheme için gerekebilir ama şimdilik basitleştirelim
from sqlalchemy import func, extract
from sqlalchemy import func, extract, desc
from datetime import datetime, timedelta

from app.models.user import User, UserRole
from app.schemas.user import User as UserSchema
from app.models.project import Project, ProjectStatus
from app.schemas.project import Project as ProjectSchema
from app.models.showcase import ShowcasePost, ProcessingStatus
from app.schemas.showcase import ShowcasePost as ShowcaseSchema
from app.models.skill_test import SkillTest
from app.models.question import Question
from app.models.choice import Choice
from app.models.portfolio import PortfolioItem
from app.models.skill import Skill
from app.models.work_experience import WorkExperience
from app.models.application import Application, ApplicationStatus

# Şema için Pydantic kullanacağız, aşağıda lokal tanımlayacağım pratik olsun diye
from pydantic import BaseModel

# Router Tanımlaması
router = APIRouter(
    prefix="/admin",
    tags=["admin_panel"]
)

# --- YETKİ KONTROLÜ (BASİT) ---
# Gerçek projede bunu 'dependencies.py' içine alıp her yerde kullanırız.
# Şimdilik burada hızlıca tanımlıyoruz.
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from app.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_current_admin(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    user = db.query(User).filter(User.email == email).first()
    if user is None or user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    return user

# ==========================================
# ENDPOINTLER
# ==========================================

# 1. KULLANICI LİSTESİ (Filtreleme ve Sayfalama ile)
@router.get("/users", response_model=List[UserSchema])
def get_all_users(
    skip: int = 0, 
    limit: int = 50,
    search: Optional[str] = None,
    role: Optional[UserRole] = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin) # Sadece adminler girebilir
):
    query = db.query(User)
    
    # Arama Filtresi (İsim veya Email içinde arar)
    if search:
        search_fmt = f"%{search}%"
        # EncryptedString olduğu için like sorgusu düzgün çalışmayabilir (Backend yapısına göre).
        # Eğer şifreleme varsa, search işlemi frontend tarafında veya RAM'de yapılmalı.
        # Şimdilik email üzerinden (şifresizse) arama yapıyoruz.
        query = query.filter(User.email.ilike(search_fmt))
    
    # Rol Filtresi (Sadece Firmaları getir vb.)
    if role:
        query = query.filter(User.role == role)
        
    # Sıralama (En yeniden eskiye)
    query = query.order_by(User.created_at.desc())
    
    return query.offset(skip).limit(limit).all()

# 2. KULLANICI DURUMUNU DEĞİŞTİR (BAN / AKTİF ET)
@router.patch("/users/{user_id}/status")
def change_user_status(
    user_id: str, # UUID
    is_active: bool,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = is_active
    db.commit()
    return {"message": f"User status updated to {'Active' if is_active else 'Banned'}"}

# 3. KULLANICIYI DOĞRULA (MANUEL ONAY)
@router.patch("/users/{user_id}/verify")
def verify_user(
    user_id: str,
    is_verified: bool,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_verified = is_verified
    db.commit()
    return {"message": f"User verification updated to {is_verified}"}


# ==========================================
# PROJE YÖNETİMİ ENDPOINTLERİ
# ==========================================

# 1. TÜM PROJELERİ LİSTELE
@router.get("/projects", response_model=List[ProjectSchema])
def get_all_projects(
    skip: int = 0, 
    limit: int = 50,
    search: Optional[str] = None,
    status: Optional[str] = None, # Enum yerine str alabiliriz esneklik için
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    query = db.query(Project)
    
    # Arama (Başlık veya Açıklama içinde)
    if search:
        search_fmt = f"%{search}%"
        query = query.filter(
            or_(
                Project.title.ilike(search_fmt),
                Project.description.ilike(search_fmt)
            )
        )
    
    # Durum Filtresi (Open, Completed vs.)
    if status:
        query = query.filter(Project.status == status)
        
    # En yeniden eskiye sırala
    query = query.order_by(Project.created_at.desc())
    
    return query.offset(skip).limit(limit).all()

# 2. PROJE DURUMUNU GÜNCELLE
@router.patch("/projects/{project_id}/status")
def update_project_status(
    project_id: str,
    status: str, # "open", "cancelled", "completed"
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Proje bulunamadı")
    
    # Enum kontrolü yapmak iyi olur ama string olarak kaydediyoruz
    project.status = status
    db.commit()
    
    return {"message": f"Proje durumu '{status}' olarak güncellendi."}

# 3. PROJEYİ SİL (Hard Delete - Dikkatli Kullanılmalı)
@router.delete("/projects/{project_id}")
def delete_project(
    project_id: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Proje bulunamadı")
    
    db.delete(project)
    db.commit()
    return {"message": "Proje kalıcı olarak silindi."}


# ==========================================
# VİTRİN (SHOWCASE) YÖNETİMİ
# ==========================================

# 1. TÜM VİTRİN GÖNDERİLERİNİ LİSTELE
@router.get("/showcase", response_model=List[ShowcaseSchema])
def get_all_showcase_posts(
    skip: int = 0, 
    limit: int = 50,
    search: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    query = db.query(ShowcasePost)
    
    # Başlık veya Açıklamada Ara
    if search:
        search_fmt = f"%{search}%"
        query = query.filter(
            or_(
                ShowcasePost.title.ilike(search_fmt),
                ShowcasePost.description.ilike(search_fmt)
            )
        )
    
    # Kategori Filtresi
    if category:
        query = query.filter(ShowcasePost.category == category)
        
    # En yeniden eskiye
    query = query.order_by(ShowcasePost.created_at.desc())
    
    return query.offset(skip).limit(limit).all()

# 2. GÖNDERİYİ SİL (Moderasyon)
@router.delete("/showcase/{post_id}")
def delete_showcase_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    post = db.query(ShowcasePost).filter(ShowcasePost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Gönderi bulunamadı")
    
    # İleride burada S3/Cloudinary'den de silme işlemi tetiklenebilir
    db.delete(post)
    db.commit()
    return {"message": "İçerik yayından kaldırıldı."}

# ==========================================
# YETENEK TESTİ (SKILL TEST) YÖNETİMİ
# ==========================================

# --- Create İçin Özel Şemalar (Sadece burada kullanacağız) ---
class ChoiceCreate(BaseModel):
    choice_text: str
    is_correct: bool

class QuestionCreate(BaseModel):
    question_text: str
    choices: List[ChoiceCreate]

class SkillTestCreate(BaseModel):
    title: str
    description: Optional[str] = None
    software: str # Örn: "Autodesk Inventor"
    questions: List[QuestionCreate]

# 1. YENİ TEST OLUŞTUR (COMPLEX INSERT)
@router.post("/skill-tests")
def create_skill_test(
    test_data: SkillTestCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    # 1. Test Başlığını Oluştur
    new_test = SkillTest(
        title=test_data.title,
        description=test_data.description,
        software=test_data.software
    )
    db.add(new_test)
    db.commit()
    db.refresh(new_test) # ID'sini alalım
    
    # 2. Soruları ve Şıkları Dön
    try:
        for q_data in test_data.questions:
            # Soruyu kaydet
            new_q = Question(
                test_id=new_test.id,
                question_text=q_data.question_text
            )
            db.add(new_q)
            db.commit()
            db.refresh(new_q) # Soru ID'sini al
            
            # Şıkları kaydet
            for c_data in q_data.choices:
                new_c = Choice(
                    question_id=new_q.id,
                    choice_text=c_data.choice_text,
                    is_correct=c_data.is_correct
                )
                db.add(new_c)
            
        db.commit() # Tüm şıkları onayla
        return {"message": "Test ve sorular başarıyla oluşturuldu.", "test_id": new_test.id}
        
    except Exception as e:
        db.rollback() # Hata olursa her şeyi geri al (Yarım kalmasın)
        raise HTTPException(status_code=500, detail=f"Kayıt sırasında hata: {str(e)}")

# 2. TESTLERİ LİSTELE
@router.get("/skill-tests")
def get_skill_tests(
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    # Sorularıyla birlikte getirelim mi? Şimdilik sadece test listesi yeterli.
    return db.query(SkillTest).order_by(SkillTest.created_at.desc()).all()

# 3. TEST SİL (Cascading Delete sayesinde sorular da silinir)
@router.delete("/skill-tests/{test_id}")
def delete_skill_test(
    test_id: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    test = db.query(SkillTest).filter(SkillTest.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Test bulunamadı")
    
    db.delete(test)
    db.commit()
    return {"message": "Test ve bağlı tüm sorular silindi."}


# ==========================================
# İSTATİSTİKLER VE DETAYLAR
# ==========================================

# 1. DASHBOARD İSTATİSTİKLERİ
# --- YARDIMCI FONKSİYON: YÜZDE HESAPLA ---
def calculate_percentage_change(current: float, previous: float) -> float:
    if previous == 0:
        return 100.0 if current > 0 else 0.0
    return ((current - previous) / previous) * 100.0

@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    # --- TARİH ARALIKLARI ---
    now = datetime.utcnow()
    start_of_this_month = datetime(now.year, now.month, 1)
    # Geçen ayın başı
    last_month = start_of_this_month - timedelta(days=1)
    start_of_last_month = datetime(last_month.year, last_month.month, 1)
    
    # 1. KULLANICI İSTATİSTİKLERİ
    total_users = db.query(User).count()
    
    # Bu ay katılanlar
    users_this_month = db.query(User).filter(User.created_at >= start_of_this_month).count()
    # Geçen ay katılanlar (Sadece o ay aralığında)
    users_last_month = db.query(User).filter(
        and_(User.created_at >= start_of_last_month, User.created_at < start_of_this_month)
    ).count()
    user_growth = calculate_percentage_change(users_this_month, users_last_month)

    # 2. PROJE İSTATİSTİKLERİ
    active_projects = db.query(Project).filter(Project.status == ProjectStatus.OPEN.value).count()
    
    projects_this_month = db.query(Project).filter(Project.created_at >= start_of_this_month).count()
    projects_last_month = db.query(Project).filter(
        and_(Project.created_at >= start_of_last_month, Project.created_at < start_of_this_month)
    ).count()
    project_growth = calculate_percentage_change(projects_this_month, projects_last_month)

    # 3. GELİR İSTATİSTİKLERİ
    # Toplam Gelir
    total_revenue = db.query(func.sum(Application.proposed_budget))\
        .filter(Application.status == ApplicationStatus.accepted)\
        .scalar() or 0
    
    # Bu Ayın Geliri (Başvuru onaylanma tarihine göre - created_at kullanıyoruz basitleştirmek için)
    revenue_this_month = db.query(func.sum(Application.proposed_budget))\
        .filter(Application.status == ApplicationStatus.accepted)\
        .filter(Application.created_at >= start_of_this_month)\
        .scalar() or 0
        
    revenue_last_month = db.query(func.sum(Application.proposed_budget))\
        .filter(Application.status == ApplicationStatus.accepted)\
        .filter(and_(Application.created_at >= start_of_last_month, Application.created_at < start_of_this_month))\
        .scalar() or 0
        
    revenue_growth = calculate_percentage_change(float(revenue_this_month), float(revenue_last_month))

    # 4. VİTRİN İSTATİSTİKLERİ
    total_showcase = db.query(ShowcasePost).count()
    
    showcase_this_month = db.query(ShowcasePost).filter(ShowcasePost.created_at >= start_of_this_month).count()
    showcase_last_month = db.query(ShowcasePost).filter(
        and_(ShowcasePost.created_at >= start_of_last_month, ShowcasePost.created_at < start_of_this_month)
    ).count()
    showcase_growth = calculate_percentage_change(showcase_this_month, showcase_last_month)

    # Ekstra Sayaçlar
    completed_projects = db.query(Project).filter(Project.status == ProjectStatus.COMPLETED.value).count()
    pending_users = db.query(User).filter(User.is_verified == False).count()

    # --- GRAFİKLER VE LİSTELER (Önceki kodla aynı mantık) ---
    
    # Aylık Gelir Grafiği
    six_months_ago = now - timedelta(days=180)
    revenue_data = db.query(
        func.to_char(Application.created_at, 'Month').label('month'),
        func.sum(Application.proposed_budget).label('revenue')
    ).filter(
        Application.status == ApplicationStatus.accepted,
        Application.created_at >= six_months_ago
    ).group_by(
        func.to_char(Application.created_at, 'Month'),
        extract('month', Application.created_at)
    ).order_by(extract('month', Application.created_at)).all()

    chart_revenue = []
    for r in revenue_data:
        month_name = r.month.strip()[:3]
        revenue_val = float(r.revenue or 0)
        chart_revenue.append({
            "date": month_name,
            "Revenue": revenue_val,
            "Sales": int(revenue_val * 0.7) 
        })

    # Kategori Dağılımı
    cat_data = db.query(
        Project.category, func.count(Project.id)
    ).group_by(Project.category).all()

    colors = ['indigo.6', 'blue.6', 'teal.6', 'grape.6', 'orange.6', 'red.6']
    chart_category = []
    for i, (cat_name, count) in enumerate(cat_data):
        if i < 5: 
            chart_category.append({
                "name": cat_name.split(' ')[0], 
                "value": count,
                "color": colors[i % len(colors)]
            })

    # Son Projeler
    recent_projects_query = db.query(Project).order_by(desc(Project.created_at)).limit(5).all()
    recent_projects = []
    for p in recent_projects_query:
        recent_projects.append({
            "id": str(p.id),
            "owner": p.owner.name,
            "initials": p.owner.name[:2].upper(),
            "category": p.category.split(' ')[0],
            "budget": (p.budget_min + p.budget_max) / 2,
            "status": p.status
        })

    return {
        "cards": {
            "total_users": total_users,
            "user_growth": round(user_growth, 1), # Yeni Eklendi
            
            "active_projects": active_projects,
            "project_growth": round(project_growth, 1), # Yeni Eklendi
            
            "total_revenue": total_revenue,
            "revenue_growth": round(revenue_growth, 1), # Yeni Eklendi
            
            "total_showcase": total_showcase,
            "showcase_growth": round(showcase_growth, 1), # Yeni Eklendi
            
            "completed_projects": completed_projects,
            "pending_users": pending_users
        },
        "charts": {
            "revenue": chart_revenue,
            "categories": chart_category
        },
        "recent_projects": recent_projects
    }

# 2. KULLANICI DETAYI (Full Profil)
@router.get("/users/{user_id}")
def get_user_details(
    user_id: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    
    # İlişkili verileri manuel toparlayıp dönüyoruz (veya Pydantic şemasıyla otomatik)
    # Burada basitçe dict olarak dönüyorum, gerçek projede UserDetailSchema kullanmak daha şık olur.
    return {
        "id": user.id,
        "name": user.name, # EncryptedString olduğu için otomatik çözülür
        "email": user.email,
        "role": user.role,
        "phone": user.phone_number,
        "bio": user.bio,
        "is_active": user.is_active,
        "is_verified": user.is_verified,
        "created_at": user.created_at,
        "skills": [s.name for s in user.skills], # İlişkili yetenekler
        "portfolio": [
            {"title": p.title, "image": p.image_url, "desc": p.description} 
            for p in user.portfolio_items
        ],
        "experiences": [
            {"company": w.company_name, "title": w.title, "start": w.start_date}
            for w in user.work_experiences
        ]
    }

# 3. PROJE DETAYI
@router.get("/projects/{project_id}")
def get_project_details(
    project_id: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Proje bulunamadı")
        
    return {
        "id": project.id,
        "title": project.title,
        "description": project.description,
        "category": project.category,
        "budget_min": project.budget_min,
        "budget_max": project.budget_max,
        "status": project.status,
        "deadline": project.deadline,
        "created_at": project.created_at,
        "owner": {
            "name": project.owner.name,
            "email": project.owner.email
        },
        # Gereken yetenekleri listele
        "required_skills": [s.name for s in project.required_skills],
        # Başvuru sayısı
        "application_count": len(project.applications)
    }