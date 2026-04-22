import logging
import uuid
import json
from sqlalchemy.orm import Session
from app import models, schemas, crud
from app.models.notification import NotificationType
from app.crud import audit as audit_crud 
from datetime import datetime, timezone
from decimal import Decimal
from sqlalchemy import and_

# 🚀 KRİTİK İMPORT: TestStatus doğrudan kendi dosyasından çekiliyor!
from app.models.test_result import TestStatus 

# === LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# ==============

def create_test_result(db: Session, user_id: uuid.UUID, test_id: uuid.UUID) -> models.TestResult | None:
    logger.info(f"Yeni test sonucu kaydı oluşturuluyor: KullanıcıID={user_id}, TestID={test_id}")
    try:
        db_test_result = models.TestResult(
            user_id=user_id,
            test_id=test_id,
            status=TestStatus.IN_PROGRESS  # 🚀 models. TAKISI SİLİNDİ
        )
        db.add(db_test_result)
        db.commit()
        db.refresh(db_test_result)

        audit_crud.create_audit_log(
            db=db,
            user_id=user_id,
            action="SKILL_TEST_STARTED",
            target_entity="test_results",
            target_id=str(db_test_result.id),
            details=json.dumps({
                "test_id": str(test_id),
                "status": "IN_PROGRESS"
            })
        )

        return db_test_result
    except Exception as e:
        logger.error(f"Test sonucu kaydı oluşturulurken HATA: {e}")
        db.rollback()
        return None

def get_test_result(db: Session, result_id: uuid.UUID):
    return db.query(models.TestResult).filter(models.TestResult.id == result_id).first()

def calculate_and_complete_test(db: Session, result_id: uuid.UUID, submission: schemas.TestSubmission):
    logger.info(f"Test sonucu hesaplanıyor: SonuçID={result_id}")
    
    db_test_result = get_test_result(db, result_id)
    if not db_test_result:
        logger.warning(f"Hesaplanmak istenen test sonucu bulunamadı: ID={result_id}")
        return None

    correct_answers = db.query(models.Choice).join(models.Question).filter(
        models.Question.test_id == db_test_result.test_id,
        models.Choice.is_correct == True
    ).all()
    
    correct_choices_map = {str(choice.question_id): str(choice.id) for choice in correct_answers}
    
    score = 0
    total_questions = len(correct_choices_map)
    
    for answer in submission.answers:
        question_id_str = str(answer.question_id)
        selected_choice_id_str = str(answer.selected_choice_id)
        
        if correct_choices_map.get(question_id_str) == selected_choice_id_str:
            score += 1
            
    final_score = (Decimal(score) / Decimal(total_questions)) * 100 if total_questions > 0 else 0
    
    logger.info(f"Test tamamlandı. Skor: {final_score} ({score}/{total_questions})")

    try:
        db_test_result.score = final_score
        db_test_result.status = TestStatus.COMPLETED  # 🚀 models. TAKISI SİLİNDİ
        db_test_result.completed_at = datetime.now(timezone.utc)
        
        db.add(db_test_result)
        db.commit()
        db.refresh(db_test_result)

        audit_crud.create_audit_log(
            db=db,
            user_id=db_test_result.user_id,
            action="SKILL_TEST_COMPLETED",
            target_entity="test_results",
            target_id=str(db_test_result.id),
            details=json.dumps({
                "test_id": str(db_test_result.test_id),
                "score": float(final_score),
                "correct_count": score,
                "total_questions": total_questions,
                "result": "PASSED" if final_score >= 70 else "FAILED"
            })
        )
        
        if final_score >= 70:
             logger.info(f"Kullanıcı testi geçti! Rozet verilmesi için tetikleyici çalışabilir.")

    except Exception as e:
        logger.error(f"Test sonucu kaydedilirken HATA: {e}")
        db.rollback()
        return None

    try:
        skill_test = db.query(models.SkillTest).filter(models.SkillTest.id == db_test_result.test_id).first()
        if skill_test:
            msg_prefix = "Tebrikler!" if final_score >= 70 else "Test tamamlandı."
            notification_content = f"{msg_prefix} '{skill_test.title}' testinden {int(final_score)} puan aldın."
            
            crud.notification.create_notification(
                db=db,
                user_id=db_test_result.user_id,
                type=NotificationType.SKILL_TEST_RESULT,
                content=notification_content,
                related_entity_id=db_test_result.id
            )
    except Exception as e:
        logger.error(f"Bildirim gönderilirken hata: {e}")

    return db_test_result

def get_completed_test_by_user_and_test(db: Session, user_id: uuid.UUID, test_id: uuid.UUID):
    return db.query(models.TestResult).filter(
        and_(
            models.TestResult.user_id == user_id,
            models.TestResult.test_id == test_id,
            models.TestResult.status == TestStatus.COMPLETED  # 🚀 models. TAKISI SİLİNDİ (Hatayı çıkaran yer)
        )
    ).first()