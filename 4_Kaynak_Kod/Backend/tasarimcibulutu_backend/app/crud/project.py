from sqlalchemy.orm import Session, joinedload
from uuid import UUID
from typing import List
from datetime import datetime, timezone
from sqlalchemy import desc, asc
from app.models.skill import Skill
from app import models, schemas
from app.models.project import ProjectStatus
from app.models.application import ApplicationStatus
from app import models, schemas, crud
from app.models.notification import NotificationType

# --- PROJE GETİRME FONKSİYONLARI ---
def get_project(db: Session, project_id: UUID) -> models.Project | None:
    return db.query(models.Project).options(
        joinedload(models.Project.owner),
        joinedload(models.Project.applications).joinedload(models.Application.freelancer),
        joinedload(models.Project.reviews).joinedload(models.Review.reviewer)
    ).filter(models.Project.id == project_id).first()

def get_projects(
    db: Session, 
    skip: int = 0, 
    limit: int = 100, 
    search: str | None = None, 
    category: str | None = None,
    # --- YENİ PARAMETRELER ---
    min_budget: float | None = None,
    max_budget: float | None = None,
    sort_by: str | None = None
) -> List[models.Project]:
    
    query = db.query(models.Project).options(joinedload(models.Project.owner))
    query = query.filter(models.Project.status == ProjectStatus.OPEN.value)

    if search:
        query = query.filter(models.Project.title.ilike(f"%{search}%"))
    if category:
        query = query.filter(models.Project.category == category)
    
    # --- YENİ FİLTRELEME MANTIĞI ---
    if min_budget is not None:
        # Bütçesi belirtilen minimum değerden büyük veya eşit olanları filtrele
        query = query.filter(models.Project.budget_min >= min_budget)
    if max_budget is not None:
        # Bütçesi belirtilen maksimum değerden küçük veya eşit olanları filtrele
        query = query.filter(models.Project.budget_max <= max_budget)
    
    # --- YENİ SIRALAMA MANTIĞI ---
    if sort_by == 'budget_high':
        # En yüksek bütçeye göre sırala (azalan)
        query = query.order_by(desc(models.Project.budget_max))
    elif sort_by == 'budget_low':
        # En düşük bütçeye göre sırala (artan)
        query = query.order_by(asc(models.Project.budget_min))
    else:
        # Varsayılan olarak en yeniye göre sırala
        query = query.order_by(desc(models.Project.created_at))
        
    return query.offset(skip).limit(limit).all()

def get_projects_by_user(db: Session, user_id: UUID) -> List[models.Project]:
    return db.query(models.Project).options(
        # KRİTİK SATIR: Projeleri ve ilişkili başvuruları birlikte yükle
        joinedload(models.Project.applications).joinedload(models.Application.freelancer)
    ).filter(models.Project.user_id == user_id).order_by(models.Project.created_at.desc()).all()

def get_projects_for_freelancer(db: Session, user_id: UUID) -> List[models.Project]:
    accepted_project_ids_subquery = db.query(models.Application.project_id).filter(
        models.Application.freelancer_id == user_id,
        models.Application.status == ApplicationStatus.accepted
    ).subquery()
    return db.query(models.Project).options(
        joinedload(models.Project.owner),
        # KRİTİK SATIR: Projeleri ve ilişkili başvuruları birlikte yükle
        joinedload(models.Project.applications).joinedload(models.Application.freelancer)
    ).filter(
        models.Project.id.in_(accepted_project_ids_subquery)
    ).order_by(models.Project.updated_at.desc()).all()


# --- PROJE OLUŞTURMA, GÜNCELLEME, SİLME VE YAŞAM DÖNGÜSÜ FONKSİYONLARI ---

# --- BU FONKSİYON GÜNCELLENDİ ---
def create_project(db: Session, project: schemas.ProjectCreate, owner_id: UUID) -> models.Project:
    # 1. Gelen veriden yetenek ID'lerini ayır
    skill_ids = project.required_skill_ids
    project_data = project.model_dump(exclude={'required_skill_ids'}) # Yetenekler hariç diğer veriler

    current_time = datetime.now(timezone.utc)
    
    # 2. Projeyi yetenekler olmadan oluştur
    db_project = models.Project(
        **project_data,
        user_id=owner_id,
        status=ProjectStatus.OPEN.value,
        created_at=current_time,
        updated_at=current_time
    )

    # 3. Eğer yetenek ID'leri geldiyse, onları bul ve projeye ekle
    if skill_ids:
        skills = db.query(Skill).filter(Skill.id.in_(skill_ids)).all()
        db_project.required_skills.extend(skills)

    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

# --- YENİDEN EKLENEN FONKSİYON ---
def update_project(db: Session, project_id: UUID, project_update: schemas.ProjectUpdate) -> models.Project | None:
    db_project = get_project(db, project_id=project_id)
    if not db_project:
        return None
    
    update_data = project_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_project, key, value)
    
    db_project.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_project)
    return db_project

# --- YENİDEN EKLENEN FONKSİYON ---
def delete_project(db: Session, project_id: UUID) -> models.Project | None:
    db_project = get_project(db, project_id=project_id)
    if not db_project:
        return None
    db.delete(db_project)
    db.commit()
    return db_project

def deliver_project(db: Session, project_id: UUID, freelancer_id: UUID) -> models.Project | None:
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    
    # Proje modelinde accepted_freelancer_id olduğunu varsayıyoruz
    # Eğer yoksa, kabul edilmiş başvuru üzerinden bulunabilir.
    # Şimdilik bu şekilde ilerleyelim.
    accepted_app = crud.application.get_accepted_application_for_project(db, project_id)

    if db_project and accepted_app and accepted_app.freelancer_id == freelancer_id and db_project.status == ProjectStatus.IN_PROGRESS.value:
        db_project.status = ProjectStatus.PENDING_REVIEW.value
        db_project.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(db_project)

        # --- BİLDİRİM OLUŞTURMA ---
        try:
            freelancer = db.query(models.User).filter(models.User.id == freelancer_id).first()
            if freelancer:
                content = f"{freelancer.name}, '{db_project.title}' projesinin teslimatını yaptı. Lütfen inceleyin."
                crud.notification.create_notification(
                    db=db,
                    user_id=db_project.user_id, # Alıcı: Proje sahibi
                    actor_id=freelancer_id,   # Eylemi yapan: Freelancer
                    type=NotificationType.PROJECT_DELIVERED,
                    content=content,
                    related_entity_id=db_project.id
                )
        except Exception as e:
            print(f"Teslimat sonrası bildirim hatası: {e}")
        # --- BİLDİRİM SONU ---

        return db_project
    return None

# --- GÜNCELLENMİŞ FONKSİYON ---
def accept_and_complete_project(db: Session, project_id: UUID, owner_id: UUID) -> models.Project | None:
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    if db_project and db_project.status == ProjectStatus.PENDING_REVIEW.value and db_project.user_id == owner_id:
        
        accepted_app = crud.application.get_accepted_application_for_project(db, project_id)
        if not accepted_app: return None # Kabul edilmiş freelancer yoksa işlem yapma

        db_project.status = ProjectStatus.COMPLETED.value
        db_project.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(db_project)

        # --- BİLDİRİM OLUŞTURMA ---
        try:
            content = f"Harika iş! '{db_project.title}' projesi için yaptığınız teslimat onaylandı ve proje tamamlandı."
            crud.notification.create_notification(
                db=db,
                user_id=accepted_app.freelancer_id, # Alıcı: Freelancer
                actor_id=owner_id,                  # Eylemi yapan: Proje Sahibi
                type=NotificationType.DELIVERY_ACCEPTED,
                content=content,
                related_entity_id=db_project.id
            )
        except Exception as e:
            print(f"Teslimat onayı sonrası bildirim hatası: {e}")
        # --- BİLDİRİM SONU ---

        return db_project
    return None

# --- GÜNCELLENMİŞ FONKSİYON ---
def request_revision(db: Session, project_id: UUID, owner_id: UUID) -> models.Project | None:
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    if db_project and db_project.status == ProjectStatus.PENDING_REVIEW.value and db_project.user_id == owner_id:
        
        accepted_app = crud.application.get_accepted_application_for_project(db, project_id)
        if not accepted_app: return None # Kabul edilmiş freelancer yoksa işlem yapma

        db_project.status = ProjectStatus.IN_PROGRESS.value
        db_project.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(db_project)

        # --- BİLDİRİM OLUŞTURMA ---
        try:
            content = f"'{db_project.title}' projesi için revizyon talep edildi. Lütfen detayları kontrol edin."
            crud.notification.create_notification(
                db=db,
                user_id=accepted_app.freelancer_id, # Alıcı: Freelancer
                actor_id=owner_id,                  # Eylemi yapan: Proje Sahibi
                type=NotificationType.REVISION_REQUESTED,
                content=content,
                related_entity_id=db_project.id
            )
        except Exception as e:
            print(f"Revizyon talebi sonrası bildirim hatası: {e}")
        # --- BİLDİRİM SONU ---

        return db_project
    return None