# app/crud/test_result.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
import uuid
from sqlalchemy.orm import Session
# --- YENİ İMPORTLAR ---
from app import models, schemas, crud
from app.models.notification import NotificationType
# --- BİTTİ ---
from datetime import datetime, timezone # <-- timezone EKLENDİ (utcnow() yerine)
from decimal import Decimal
from sqlalchemy import and_

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def create_test_result(db: Session, user_id: uuid.UUID, test_id: uuid.UUID) -> models.TestResult | None:
    """
    Kullanıcı bir teste başladığında yeni bir TestResult kaydı oluşturur.
    """
    logger.info(f"Yeni test sonucu kaydı oluşturuluyor (Test başlıyor): KullanıcıID={user_id}, TestID={test_id}") # <-- EKLENDİ
    try:
        db_test_result = models.TestResult(
            user_id=user_id,
            test_id=test_id,
            status=models.TestStatus.IN_PROGRESS
        )
        db.add(db_test_result)
        db.commit()
        db.refresh(db_test_result)
        logger.info(f"Test sonucu kaydı başarıyla oluşturuldu: ID={db_test_result.id}") # <-- EKLENDİ
        return db_test_result
    except Exception as e:
        logger.error(f"Test sonucu kaydı (KullanıcıID={user_id}, TestID={test_id}) oluşturulurken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

def get_test_result(db: Session, result_id: uuid.UUID):
    """
    ID'ye göre tek bir test sonucunu getirir.
    """
    return db.query(models.TestResult).filter(models.TestResult.id == result_id).first()

# --- GÜNCELLENMİŞ FONKSİYON (Loglama ve Hata Yönetimi) ---
def calculate_and_complete_test(db: Session, result_id: uuid.UUID, submission: schemas.TestSubmission):
    """
    Kullanıcının gönderdiği cevapları alır, puanı hesaplar, test sonucunu günceller
    ve kullanıcıya bildirim gönderir.
    """
    logger.info(f"Test sonucu hesaplanıyor: SonuçID={result_id}") # <-- EKLENDİ
    
    db_test_result = get_test_result(db, result_id)
    if not db_test_result:
        logger.warning(f"Hesaplanmak istenen test sonucu bulunamadı: ID={result_id}") # <-- EKLENDİ
        return None

    # 1. Adım: Testteki tüm soruların doğru cevaplarını al
    correct_answers = db.query(models.Choice).join(models.Question).filter(
        models.Question.test_id == db_test_result.test_id,
        models.Choice.is_correct == True
    ).all()
    
    correct_choices_map = {choice.question_id: choice.id for choice in correct_answers}
    
    # 2. Adım: Puanı hesapla
    score = 0
    total_questions = len(correct_choices_map)
    
    for answer in submission.answers:
        if correct_choices_map.get(str(answer.question_id)) == str(answer.selected_choice_id): # UUID'leri string olarak karşılaştırmak daha güvenli
            score += 1
            
    final_score = (Decimal(score) / Decimal(total_questions)) * 100 if total_questions > 0 else 0
    
    logger.info(f"Test hesaplaması tamamlandı: SonuçID={result_id}, Puan={final_score} ({score}/{total_questions})") # <-- EKLENDİ

    try:
        # 3. Adım: Test sonucunu güncelle
        db_test_result.score = final_score
        db_test_result.status = models.TestStatus.COMPLETED
        # utcnow() deprecated, timezone-aware datetime kullanmak daha iyidir
        db_test_result.completed_at = datetime.now(timezone.utc) # <-- GÜNCELLENDİ
        
        db.add(db_test_result)
        db.commit()
        db.refresh(db_test_result)
        logger.info(f"Test sonucu veritabanına başarıyla kaydedildi: ID={result_id}") # <-- EKLENDİ
    
    except Exception as e:
        logger.error(f"Test sonucu (ID={result_id}) veritabanına kaydedilirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None # Hata durumunda işlemi durdur

    # 4. Adım: Kullanıcıya bildirim gönder
    try:
        # Bildirim içeriği için testin adını alalım
        skill_test = db.query(models.SkillTest).filter(models.SkillTest.id == db_test_result.test_id).first()
        if skill_test:
            notification_content = f"'{skill_test.title}' yetkinlik testini tamamladın. Sonucunu görmek için tıkla."
            
            crud.notification.create_notification(
                db=db,
                user_id=db_test_result.user_id, # Bildirimi alacak kişi (testi çözen)
                type=NotificationType.SKILL_TEST_RESULT,
                content=notification_content,
                related_entity_id=db_test_result.id # Tıklayınca test sonucuna gitmesi için
            )
    except Exception as e:
        # print() -> logger.error() olarak değiştirildi
        logger.error(f"Test sonucu (ID={result_id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ

    # 5. Adım: Tamamlanmış test sonucunu döndür
    return db_test_result

def get_completed_test_by_user_and_test(db: Session, user_id: uuid.UUID, test_id: uuid.UUID):
    """
    Belirli bir kullanıcının, belirli bir testi daha önce tamamlayıp tamamlamadığını kontrol eder.
    """
    return db.query(models.TestResult).filter(
        and_(
            models.TestResult.user_id == user_id,
            models.TestResult.test_id == test_id,
            models.TestResult.status == models.TestStatus.COMPLETED
        )
    ).first()