# app/crud/project.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
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

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

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
    
    # Proje aramasının loglanması, sistemin nasıl kullanıldığını anlamak için faydalıdır.
    logger.info(f"Projeler listeleniyor: search='{search}', category='{category}', min_budget={min_budget}, max_budget={max_budget}, sort_by='{sort_by}'") # <-- EKLENDİ
    
    query = db.query(models.Project).options(joinedload(models.Project.owner))
    query = query.filter(models.Project.status == ProjectStatus.OPEN.value)

    if search:
        query = query.filter(models.Project.title.ilike(f"%{search}%"))
    if category:
        query = query.filter(models.Project.category == category)
    
    # --- YENİ FİLTRELEME MANTIĞI ---
    if min_budget is not None:
        query = query.filter(models.Project.budget_min >= min_budget)
    if max_budget is not None:
        query = query.filter(models.Project.budget_max <= max_budget)
    
    # --- YENİ SIRALAMA MANTIĞI ---
    if sort_by == 'budget_high':
        query = query.order_by(desc(models.Project.budget_max))
    elif sort_by == 'budget_low':
        query = query.order_by(asc(models.Project.budget_min))
    else:
        query = query.order_by(desc(models.Project.created_at))
        
    return query.offset(skip).limit(limit).all()

def get_projects_by_user(db: Session, user_id: UUID) -> List[models.Project]:
    return db.query(models.Project).options(
        joinedload(models.Project.applications).joinedload(models.Application.freelancer)
    ).filter(models.Project.user_id == user_id).order_by(models.Project.created_at.desc()).all()

def get_projects_for_freelancer(db: Session, user_id: UUID) -> List[models.Project]:
    accepted_project_ids_subquery = db.query(models.Application.project_id).filter(
        models.Application.freelancer_id == user_id,
        models.Application.status == ApplicationStatus.accepted
    ).subquery()
    return db.query(models.Project).options(
        joinedload(models.Project.owner),
        joinedload(models.Project.applications).joinedload(models.Application.freelancer)
    ).filter(
        models.Project.id.in_(accepted_project_ids_subquery)
    ).order_by(models.Project.updated_at.desc()).all()


# --- PROJE OLUŞTURMA, GÜNCELLEME, SİLME VE YAŞAM DÖNGÜSÜ FONKSİYONLARI ---

# --- BU FONKSİYON GÜNCELLENDİ (Loglama ve Hata Yönetimi) ---
def create_project(db: Session, project: schemas.ProjectCreate, owner_id: UUID) -> models.Project | None:
    logger.info(f"Yeni proje oluşturuluyor: SahipID={owner_id}, Başlık='{project.title}'") # <-- EKLENDİ
    try:
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
        
        logger.info(f"Proje başarıyla oluşturuldu: ID={db_project.id}, SahipID={owner_id}") # <-- EKLENDİ
        return db_project
    except Exception as e:
        logger.error(f"Proje oluşturulurken HATA: SahipID={owner_id}. Hata: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ (Güvenlik için)
        return None

# --- YENİDEN EKLENEN FONKSİYON (Loglama ve Hata Yönetimi) ---
def update_project(db: Session, project_id: UUID, project_update: schemas.ProjectUpdate) -> models.Project | None:
    logger.info(f"Proje güncelleniyor: ID={project_id}") # <-- EKLENDİ
    db_project = get_project(db, project_id=project_id)
    if not db_project:
        logger.warning(f"Güncellenmek istenen proje bulunamadı: ID={project_id}") # <-- EKLENDİ
        return None
    
    try:
        update_data = project_update.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_project, key, value)
        
        db_project.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(db_project)
        
        logger.info(f"Proje başarıyla güncellendi: ID={project_id}") # <-- EKLENDİ
        return db_project
    except Exception as e:
        logger.error(f"Proje (ID={project_id}) güncellenirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ (Güvenlik için)
        return None

# --- YENİDEN EKLENEN FONKSİYON (Loglama ve Hata Yönetimi) ---
def delete_project(db: Session, project_id: UUID) -> models.Project | None:
    logger.info(f"Proje siliniyor: ID={project_id}") # <-- EKLENDİ
    db_project = get_project(db, project_id=project_id)
    if not db_project:
        logger.warning(f"Silinmek istenen proje bulunamadı: ID={project_id}") # <-- EKLENDİ
        return None
    
    try:
        db.delete(db_project)
        db.commit()
        logger.info(f"Proje başarıyla silindi: ID={project_id}") # <-- EKLENDİ
        return db_project
    except Exception as e:
        logger.error(f"Proje (ID={project_id}) silinirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ (Güvenlik için)
        return None

def deliver_project(db: Session, project_id: UUID, freelancer_id: UUID) -> models.Project | None:
    logger.info(f"Proje teslimatı yapılıyor: ProjeID={project_id}, FreelancerID={freelancer_id}") # <-- EKLENDİ
    
    try:
        db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
        
        accepted_app = crud.application.get_accepted_application_for_project(db, project_id)

        if db_project and accepted_app and accepted_app.freelancer_id == freelancer_id and db_project.status == ProjectStatus.IN_PROGRESS.value:
            db_project.status = ProjectStatus.PENDING_REVIEW.value
            db_project.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(db_project)
            logger.info(f"Proje teslimatı başarıyla kaydedildi: ProjeID={project_id}, YeniDurum={ProjectStatus.PENDING_REVIEW.value}") # <-- EKLENDİ

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
                # print() -> logger.error() olarak değiştirildi
                logger.error(f"Teslimat (ProjeID={project_id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ
            # --- BİLDİRİM SONU ---

            return db_project
        else:
            logger.warning(f"Proje teslimatı yapılamadı (Yetki/Durum sorunu): ProjeID={project_id}, FreelancerID={freelancer_id}") # <-- EKLENDİ
            return None
    except Exception as e:
        logger.error(f"Proje teslimatı (ProjeID={project_id}) sırasında HATA: {e}") # <-- EKLENDİ
        db.rollback()
        return None

# --- GÜNCELLENMİŞ FONKSİYON (Loglama ve Hata Yönetimi) ---
def accept_and_complete_project(db: Session, project_id: UUID, owner_id: UUID) -> models.Project | None:
    logger.info(f"Proje teslimatı kabul ediliyor: ProjeID={project_id}, SahipID={owner_id}") # <-- EKLENDİ
    
    try:
        db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
        if db_project and db_project.status == ProjectStatus.PENDING_REVIEW.value and db_project.user_id == owner_id:
            
            accepted_app = crud.application.get_accepted_application_for_project(db, project_id)
            if not accepted_app: 
                logger.warning(f"Teslimat kabul edilemedi (Kabul edilmiş başvuru yok): ProjeID={project_id}") # <-- EKLENDİ
                return None 

            db_project.status = ProjectStatus.COMPLETED.value
            db_project.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(db_project)
            logger.info(f"Proje teslimatı kabul edildi: ProjeID={project_id}, YeniDurum={ProjectStatus.COMPLETED.value}") # <-- EKLENDİ

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
                # print() -> logger.error() olarak değiştirildi
                logger.error(f"Teslimat onayı (ProjeID={project_id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ
            # --- BİLDİRİM SONU ---

            return db_project
        else:
            logger.warning(f"Proje teslimatı kabul edilemedi (Yetki/Durum sorunu): ProjeID={project_id}, SahipID={owner_id}") # <-- EKLENDİ
            return None
    except Exception as e:
        logger.error(f"Proje teslimatı kabul (ProjeID={project_id}) sırasında HATA: {e}") # <-- EKLENDİ
        db.rollback()
        return None

# --- GÜNCELLENMİŞ FONKSİYON (Loglama ve Hata Yönetimi) ---
def request_revision(db: Session, project_id: UUID, owner_id: UUID) -> models.Project | None:
    logger.info(f"Proje için revizyon isteniyor: ProjeID={project_id}, SahipID={owner_id}") # <-- EKLENDİ
    
    try:
        db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
        if db_project and db_project.status == ProjectStatus.PENDING_REVIEW.value and db_project.user_id == owner_id:
            
            accepted_app = crud.application.get_accepted_application_for_project(db, project_id)
            if not accepted_app: 
                logger.warning(f"Revizyon istenemedi (Kabul edilmiş başvuru yok): ProjeID={project_id}") # <-- EKLENDİ
                return None 

            db_project.status = ProjectStatus.IN_PROGRESS.value
            db_project.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(db_project)
            logger.info(f"Proje revizyonu başarıyla istendi: ProjeID={project_id}, YeniDurum={ProjectStatus.IN_PROGRESS.value}") # <-- EKLENDİ

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
                # print() -> logger.error() olarak değiştirildi
                logger.error(f"Revizyon talebi (ProjeID={project_id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ
            # --- BİLDİRİM SONU ---

            return db_project
        else:
            logger.warning(f"Proje revizyonu istenemedi (Yetki/Durum sorunu): ProjeID={project_id}, SahipID={owner_id}") # <-- EKLENDİ
            return None
    except Exception as e:
        logger.error(f"Proje revizyonu isteme (ProjeID={project_id}) sırasında HATA: {e}") # <-- EKLENDİ
        db.rollback()
        return None