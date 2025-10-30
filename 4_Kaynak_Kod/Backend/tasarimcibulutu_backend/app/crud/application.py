# app/crud/application.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from uuid import UUID
from typing import List
from datetime import timezone, datetime
from app.models.application import ApplicationStatus
from app.models.project import ProjectStatus
from app import models, schemas, crud
from app.models.notification import NotificationType

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def get_application(db: Session, application_id: str):
    return db.query(models.Application).filter(models.Application.id == application_id).first()


def get_applications(db: Session, skip: int = 0, limit: int = 100) -> List[models.Application]:
    return db.query(models.Application).offset(skip).limit(limit).all()

def update_application_status(
    db: Session,
    application_id: UUID,
    new_status: ApplicationStatus,
    current_user_id: UUID
) -> models.Application | None:
    """
    Bir başvurunun durumunu günceller.
    Durum değişikliğine göre freelancer'a bildirim gönderir.
    """
    logger.info(f"Başvuru durumu güncelleniyor: ID={application_id}, YeniDurum={new_status}, GüncelleyenKullanıcı={current_user_id}") # <-- EKLENDİ
    
    application = db.query(models.Application).options(
        joinedload(models.Application.project)
    ).filter(models.Application.id == application_id).first()
    
    if not application or application.project.user_id != current_user_id:
        logger.warning(f"Başvuru güncelleme yetkisi reddedildi veya başvuru bulunamadı: ID={application_id}, Kullanıcı={current_user_id}") # <-- EKLENDİ
        return None
    
    # Bilgileri, veritabanı işlemi öncesinde güvenli değişkenlere alalım.
    project_title = application.project.title
    freelancer_id = application.freelancer_id
    project_id = application.project.id

    # Başvurunun ve projenin durumunu güncelle
    application.status = new_status
    
    # --- KRİTİK DEĞİŞİKLİK: Enum'ların değerlerini (.value) karşılaştırıyoruz ---
    if new_status.value == ApplicationStatus.accepted.value:
        logger.info(f"Başvuru kabul edildi, proje (ID={project_id}) IN_PROGRESS olarak ayarlanıyor.") # <-- EKLENDİ
        application.project.status = ProjectStatus.IN_PROGRESS.value
        (
            db.query(models.Application)
            .filter(
                models.Application.project_id == application.project_id,
                models.Application.id != application_id,
                models.Application.status == ApplicationStatus.pending
            )
            .update({"status": ApplicationStatus.rejected.value}, synchronize_session=False)
        )
    
    db.commit()
    db.refresh(application)
    
    logger.info(f"Başvuru durumu başarıyla güncellendi: ID={application_id}, YeniDurum={new_status}") # <-- EKLENDİ

    # --- FREELANCER'A BİLDİRİM GÖNDERME ---
    try:
        notification_type = None
        notification_content = None

        # --- KRİTİK DEĞİŞİKLİK: Enum'ların değerlerini (.value) karşılaştırıyoruz ---
        if new_status.value == ApplicationStatus.accepted.value:
            notification_type = NotificationType.APPLICATION_ACCEPTED
            notification_content = f"Tebrikler! '{project_title}' projesine yaptığınız başvuru kabul edildi."
        
        elif new_status.value == ApplicationStatus.rejected.value:
            notification_type = NotificationType.APPLICATION_REJECTED
            notification_content = f"'{project_title}' projesine yaptığınız başvuru reddedildi."

        if notification_type and notification_content:
            crud.notification.create_notification(
                db=db,
                user_id=freelancer_id,
                actor_id=current_user_id,
                type=notification_type,
                content=notification_content,
                related_entity_id=project_id
            )

    except Exception as e:
        # print() -> logger.error() olarak değiştirildi
        logger.error(f"Başvuru durumu (ID={application_id}) değişikliği sonrası bildirim oluşturulurken HATA: {e}") # <-- GÜNCELLENDİ

    return application

def get_applications_by_project(db: Session, project_id: str) -> List[models.Application]:
    """
    Belirli bir projeye gelen tüm başvuruları getirir.
    Freelancer ve proje bilgilerini de dahil eder.
    """
    return db.query(models.Application).options(
        joinedload(models.Application.freelancer),  # Freelancer bilgilerini getir
        joinedload(models.Application.project)      # Proje bilgilerini getir
    ).filter(models.Application.project_id == project_id).all()

def get_applications_by_freelancer(db: Session, freelancer_id: str) -> List[models.Application]:
    """
    Belirli bir freelancer'ın tüm başvurularını getirir.
    """
    return db.query(models.Application).options(
        joinedload(models.Application.project),
        joinedload(models.Application.freelancer)
    ).filter(models.Application.freelancer_id == freelancer_id).all()

def get_application_by_project_and_freelancer(db: Session, project_id: UUID, freelancer_id: UUID) -> models.Application | None:
    """
    Belirli bir freelancer'ın belirli bir projeye daha önce başvurup başvurmadığını kontrol eder.
    """
    return db.query(models.Application).filter(
        models.Application.project_id == project_id,
        models.Application.freelancer_id == freelancer_id
    ).first()

def create_application(db: Session, application: schemas.ApplicationCreate, freelancer_id: UUID) -> models.Application:
    """
    Yeni bir başvuru oluşturur ve proje sahibine bildirim gönderir.
    """
    logger.info(f"Yeni başvuru oluşturuluyor: ProjeID={application.project_id}, FreelancerID={freelancer_id}") # <-- EKLENDİ

    # 1. Adım: Başvuruyu veritabanına kaydet
    db_application = models.Application(
        project_id=application.project_id,
        freelancer_id=freelancer_id,
        cover_letter=application.cover_letter,
        proposed_budget=application.proposed_budget,
        proposed_duration=application.proposed_duration,
        status=ApplicationStatus.pending,
        created_at=datetime.now(timezone.utc)
    )
    db.add(db_application)
    db.commit()
    db.refresh(db_application)
    
    logger.info(f"Yeni başvuru başarıyla oluşturuldu: ID={db_application.id}") # <-- EKLENDİ

    # 2. Adım: Proje sahibi için bildirim oluştur
    try:
        # Gerekli bilgiler için freelancer'ı ve projeyi çek
        freelancer = db.query(models.User).filter(models.User.id == freelancer_id).first()
        project = db.query(models.Project).filter(models.Project.id == application.project_id).first()

        if freelancer and project:
            notification_content = f"{freelancer.name}, '{project.title}' projenize başvurdu."
            
            crud.notification.create_notification(
                db=db,
                user_id=project.user_id,          # Bildirimi alacak kişi (proje sahibi)
                actor_id=freelancer_id,           # Eylemi yapan kişi (başvuran freelancer)
                type=NotificationType.APPLICATION_SUBMITTED,
                content=notification_content,
                related_entity_id=project.id      # Tıklayınca projeye gitmesi için
            )
    except Exception as e:
        # print() -> logger.error() olarak değiştirildi
        logger.error(f"Başvuru (ID={db_application.id}) sonrası bildirim oluşturulurken HATA: {e}") # <-- GÜNCELLENDİ

    # 3. Adım: Oluşturulan başvuru nesnesini döndür
    return db_application

def update_application(db: Session, application_id: str, application_update: schemas.ApplicationUpdate):
    db_application = get_application(db, application_id)
    if not db_application:
        logger.warning(f"Güncellenmek istenen başvuru bulunamadı: ID={application_id}") # <-- EKLENDİ
        return None
    update_data = application_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_application, key, value)
    db.commit()
    db.refresh(db_application)
    logger.info(f"Başvuru (basit) güncellendi: ID={application_id}") # <-- EKLENDİ
    return db_application


def delete_application(db: Session, application_id: str):
    db_application = get_application(db, application_id)
    if not db_application:
        logger.warning(f"Silinmek istenen başvuru bulunamadı: ID={application_id}") # <-- EKLENDİ
        return None
    db.delete(db_application)
    db.commit()
    logger.info(f"Başvuru silindi: ID={application_id}") # <-- EKLENDİ
    return db_application

def get_accepted_application_for_project(db: Session, project_id: UUID) -> models.Application | None:
    """
    Belirli bir proje için kabul edilmiş ('accepted') başvuruyu getirir.
    """
    return db.query(models.Application).filter(
        models.Application.project_id == project_id,
        models.Application.status == models.ApplicationStatus.accepted
    ).first()