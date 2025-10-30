# app/crud/skill_test.py (GÜNCELLENMİŞ HALİ)

import logging # <-- EKLENDİ
import uuid
from sqlalchemy.orm import Session
from app import models, schemas

# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def get_skill_test(db: Session, test_id: uuid.UUID):
    """
    ID'ye göre tek bir yetkinlik testini, ilişkili soruları ve şıklarıyla birlikte getirir.
    """
    logger.info(f"Yetkinlik testi getiriliyor: TestID={test_id}") # <-- EKLENDİ
    return db.query(models.SkillTest).filter(models.SkillTest.id == test_id).first()

def get_skill_tests(db: Session, skip: int = 0, limit: int = 100):
    """
    Tüm yetkinlik testlerinin bir listesini getirir (sorular olmadan, sadece ana bilgiler).
    """
    logger.info(f"Tüm yetkinlik testleri listeleniyor: Skip={skip}, Limit={limit}") # <-- EKLENDİ
    return db.query(models.SkillTest).offset(skip).limit(limit).all()

# --- BU FONKSİYONU GÜNCELLENDİ (Loglama ve Hata Yönetimi) ---
def create_skill_test(db: Session, test: schemas.SkillTestCreate) -> models.SkillTest | None: # <-- 'None' eklendi
    """
    Yeni bir yetkinlik testi, soruları ve şıklarıyla birlikte oluşturur.
    (Bu fonksiyon daha çok admin paneli için kullanışlıdır.)
    """
    logger.info(f"Yeni yetkinlik testi oluşturuluyor: Başlık='{test.title}', Yazılım='{test.software}'") # <-- EKLENDİ
    
    try:
        # SkillTest için ID'yi manuel atıyoruz
        db_test = models.SkillTest(
            id=uuid.uuid4(), 
            title=test.title,
            description=test.description,
            software=test.software
        )
        db.add(db_test)
        # db.flush() komutunu döngülerin sonuna taşıyarak tek seferde işlemek daha verimli olabilir
        # Ancak mevcut yapıyı bozmamak adına bırakıyorum.

        for question_in in test.questions:
            # Question için ID'yi manuel atıyoruz
            db_question = models.Question(
                id=uuid.uuid4(), 
                question_text=question_in.question_text,
                test_id=db_test.id
            )
            db.add(db_question)

            for choice_in in question_in.choices:
                # Choice için ID'yi manuel atıyoruz
                db_choice = models.Choice(
                    id=uuid.uuid4(),
                    choice_text=choice_in.choice_text,
                    is_correct=choice_in.is_correct,
                    question_id=db_question.id
                )
                db.add(db_choice)

        db.commit()
        db.refresh(db_test)
        logger.info(f"Yetkinlik testi başarıyla oluşturuldu: ID={db_test.id}, Başlık='{test.title}'") # <-- EKLENDİ
        return db_test
    except Exception as e:
        logger.error(f"Yetkinlik testi (Başlık='{test.title}') oluşturulurken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ (Tüm işlemi geri al)
        return None