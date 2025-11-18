# app/crud/project.py

import logging
from sqlalchemy.orm import Session, joinedload
from uuid import UUID
from typing import List
from datetime import datetime, timezone
from sqlalchemy import desc, asc, or_
from app.models.skill import Skill
from app import models, schemas
from app.models.project import ProjectStatus
from app.models.application import ApplicationStatus
from app import models, schemas, crud
from app.models.notification import NotificationType

# === LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# ==============

# --- PROJE GETİRME FONKSİYONLARI ---
def get_project(db: Session, project_id: UUID) -> models.Project | None:
    return db.query(models.Project).options(
        joinedload(models.Project.owner),
        joinedload(models.Project.applications).joinedload(models.Application.freelancer),
        joinedload(models.Project.reviews).joinedload(models.Review.reviewer),
        
        # --- EKLENEN SATIR: REVIZYONLARI DA YÜKLE ---
        joinedload(models.Project.revisions)
        # --------------------------------------------
        
    ).filter(models.Project.id == project_id).first()

def get_projects(
    db: Session, 
    skip: int = 0, 
    limit: int = 100, 
    search: str | None = None, 
    category: str | None = None,
    min_budget: float | None = None,
    max_budget: float | None = None,
    sort_by: str | None = None
) -> List[models.Project]:
    
    logger.info(f"Projeler listeleniyor: search='{search}', category='{category}'")
    
    query = db.query(models.Project).options(joinedload(models.Project.owner))
    
    # 1. Sadece AÇIK (OPEN) projeleri getir
    query = query.filter(models.Project.status == ProjectStatus.OPEN.value)

    # --- FAZ 1 DÜZELTMESİ: TARİHİ GEÇMİŞ PROJELERİ GİZLE ---
    # Deadline'ı (son başvuru tarihi) şu anki zamandan ileri olanları getir.
    # Deadline'ı null olanlar (süresiz) listelensin diye 'or_' kullanmıyoruz, 
    # genelde deadline zorunludur. Eğer opsiyonelse mantığı değiştirebiliriz.
    # YENİSİ (Düzeltilmiş):
    current_now = datetime.now(timezone.utc)
    
    # Mantık: Deadline ya şu andan büyük olsun YA DA (OR) Deadline boş (None) olsun.
    query = query.filter(
        or_(
            models.Project.deadline > current_now,
            models.Project.deadline.is_(None)
        )
    )
    # -------------------------------------------------------

    if search:
        query = query.filter(models.Project.title.ilike(f"%{search}%"))
    if category:
        query = query.filter(models.Project.category == category)
    
    if min_budget is not None:
        query = query.filter(models.Project.budget_min >= min_budget)
    if max_budget is not None:
        query = query.filter(models.Project.budget_max <= max_budget)
    
    # Sıralama
    if sort_by == 'budget_high':
        query = query.order_by(desc(models.Project.budget_max))
    elif sort_by == 'budget_low':
        query = query.order_by(asc(models.Project.budget_min))
    else:
        # Varsayılan: En yeniden en eskiye
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

# --- CRUD FONKSİYONLARI ---

def create_project(db: Session, project: schemas.ProjectCreate, owner_id: UUID) -> models.Project | None:
    logger.info(f"Yeni proje oluşturuluyor: SahipID={owner_id}, Başlık='{project.title}'")
    try:
        skill_ids = project.required_skill_ids
        project_data = project.model_dump(exclude={'required_skill_ids'})

        current_time = datetime.now(timezone.utc)
        
        db_project = models.Project(
            **project_data,
            user_id=owner_id,
            status=ProjectStatus.OPEN.value,
            created_at=current_time,
            updated_at=current_time
        )

        if skill_ids:
            skills = db.query(Skill).filter(Skill.id.in_(skill_ids)).all()
            db_project.required_skills.extend(skills)

        db.add(db_project)
        db.commit()
        db.refresh(db_project)
        
        logger.info(f"Proje başarıyla oluşturuldu: ID={db_project.id}")
        return db_project
    except Exception as e:
        logger.error(f"Proje oluşturulurken HATA: SahipID={owner_id}. Hata: {e}")
        db.rollback()
        return None

def update_project(db: Session, project_id: UUID, project_update: schemas.ProjectUpdate) -> models.Project | None:
    logger.info(f"Proje güncelleniyor: ID={project_id}")
    db_project = get_project(db, project_id=project_id)
    if not db_project:
        logger.warning(f"Güncellenmek istenen proje bulunamadı: ID={project_id}")
        return None
    
    try:
        update_data = project_update.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_project, key, value)
        
        db_project.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(db_project)
        
        logger.info(f"Proje başarıyla güncellendi: ID={project_id}")
        return db_project
    except Exception as e:
        logger.error(f"Proje (ID={project_id}) güncellenirken HATA: {e}")
        db.rollback()
        return None

def delete_project(db: Session, project_id: UUID) -> models.Project | None:
    logger.info(f"Proje siliniyor: ID={project_id}")
    db_project = get_project(db, project_id=project_id)
    if not db_project:
        logger.warning(f"Silinmek istenen proje bulunamadı: ID={project_id}")
        return None
    
    try:
        db.delete(db_project)
        db.commit()
        logger.info(f"Proje başarıyla silindi: ID={project_id}")
        return db_project
    except Exception as e:
        logger.error(f"Proje (ID={project_id}) silinirken HATA: {e}")
        db.rollback()
        return None

def deliver_project(db: Session, project_id: UUID, freelancer_id: UUID) -> models.Project | None:
    logger.info(f"Proje teslimatı yapılıyor: ProjeID={project_id}, FreelancerID={freelancer_id}")
    try:
        db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
        accepted_app = crud.application.get_accepted_application_for_project(db, project_id)

        if db_project and accepted_app and accepted_app.freelancer_id == freelancer_id and db_project.status == ProjectStatus.IN_PROGRESS.value:
            db_project.status = ProjectStatus.PENDING_REVIEW.value
            db_project.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(db_project)
            
            try:
                freelancer = db.query(models.User).filter(models.User.id == freelancer_id).first()
                if freelancer:
                    content = f"{freelancer.name}, '{db_project.title}' projesinin teslimatını yaptı. Lütfen inceleyin."
                    crud.notification.create_notification(
                        db=db,
                        user_id=db_project.user_id,
                        actor_id=freelancer_id,
                        type=NotificationType.PROJECT_DELIVERED,
                        content=content,
                        related_entity_id=db_project.id
                    )
            except Exception as e:
                logger.error(f"Bildirim hatası: {e}")

            return db_project
        else:
            return None
    except Exception as e:
        logger.error(f"Teslimat hatası: {e}")
        db.rollback()
        return None

def accept_and_complete_project(db: Session, project_id: UUID, owner_id: UUID) -> models.Project | None:
    try:
        db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
        if db_project and db_project.status == ProjectStatus.PENDING_REVIEW.value and db_project.user_id == owner_id:
            
            accepted_app = crud.application.get_accepted_application_for_project(db, project_id)
            if not accepted_app: return None 

            db_project.status = ProjectStatus.COMPLETED.value
            db_project.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(db_project)

            try:
                content = f"Harika iş! '{db_project.title}' projesi için yaptığınız teslimat onaylandı ve proje tamamlandı."
                crud.notification.create_notification(
                    db=db,
                    user_id=accepted_app.freelancer_id,
                    actor_id=owner_id,
                    type=NotificationType.DELIVERY_ACCEPTED,
                    content=content,
                    related_entity_id=db_project.id
                )
            except Exception as e:
                logger.error(f"Bildirim hatası: {e}")

            return db_project
        else:
            return None
    except Exception as e:
        logger.error(f"Teslimat kabul hatası: {e}")
        db.rollback()
        return None

def request_revision(db: Session, project_id: UUID, owner_id: UUID, reason: str) -> models.Project | None:
    try:
        db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
        # Durum kontrolü (Pending Review olmalı) ve Sahip kontrolü
        if db_project and db_project.status == ProjectStatus.PENDING_REVIEW.value and db_project.user_id == owner_id:
            
            accepted_app = crud.application.get_accepted_application_for_project(db, project_id)
            if not accepted_app: return None 

            # 1. Durumu güncelle
            db_project.status = ProjectStatus.IN_PROGRESS.value
            db_project.updated_at = datetime.now(timezone.utc)
            
            # 2. === YENİ: Revizyonu Tabloya Kaydet ===
            new_revision = models.ProjectRevision(
                project_id=project_id,
                request_reason=reason
            )
            db.add(new_revision)
            # =========================================
            
            db.commit()
            db.refresh(db_project) # Revisions listesi güncellensin diye refresh

            # 3. Bildirim Gönder
            try:
                content = f"'{db_project.title}' projesi için revizyon talep edildi.\nSebep: {reason}"
                crud.notification.create_notification(
                    db=db,
                    user_id=accepted_app.freelancer_id,
                    actor_id=owner_id,
                    type=NotificationType.REVISION_REQUESTED,
                    content=content,
                    related_entity_id=db_project.id
                )
            except Exception as e:
                logger.error(f"Bildirim hatası: {e}")

            return db_project
        else:
            return None
    except Exception as e:
        logger.error(f"Revizyon hatası: {e}")
        db.rollback()
        return None