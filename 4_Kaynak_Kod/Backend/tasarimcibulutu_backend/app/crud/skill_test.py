# app/crud/skill_test.py

import uuid # <-- BU SATIRI EN ÜSTE EKLEYİN
from sqlalchemy.orm import Session
from app import models, schemas

def get_skill_test(db: Session, test_id: uuid.UUID):
    """
    ID'ye göre tek bir yetkinlik testini, ilişkili soruları ve şıklarıyla birlikte getirir.
    """
    return db.query(models.SkillTest).filter(models.SkillTest.id == test_id).first()

def get_skill_tests(db: Session, skip: int = 0, limit: int = 100):
    """
    Tüm yetkinlik testlerinin bir listesini getirir (sorular olmadan, sadece ana bilgiler).
    """
    return db.query(models.SkillTest).offset(skip).limit(limit).all()

# --- BU FONKSİYONU GÜNCELLEYİN ---
def create_skill_test(db: Session, test: schemas.SkillTestCreate):
    """
    Yeni bir yetkinlik testi, soruları ve şıklarıyla birlikte oluşturur.
    (Bu fonksiyon daha çok admin paneli için kullanışlıdır.)
    """
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
    return db_test