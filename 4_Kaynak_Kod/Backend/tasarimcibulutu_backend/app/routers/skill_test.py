# app/routers/skill_test.py
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import schemas, models
from app.crud import skill_test as crud_skill_test # isimlendirmenize göre
from app.crud import test_result as crud_test_result # isimlendirmenize göre
from app.dependencies import get_db
from app.dependencies import get_db, get_current_user
router = APIRouter(
    prefix="/skill-tests",
    tags=["Skill Tests"],
    responses={404: {"description": "Not found"}},
)

# --- Test ve Soru Yönetimi (Admin için daha uygun) ---
@router.post("/", response_model=schemas.SkillTest, status_code=status.HTTP_201_CREATED)
def create_skill_test(
    test: schemas.SkillTestCreate, 
    db: Session = Depends(get_db)
    # TODO: Buraya bir admin yetki kontrolü eklenebilir
):
    """
    Yeni bir yetkinlik testi, soruları ve şıklarıyla birlikte oluşturur.
    """
    return crud_skill_test.create_skill_test(db=db, test=test)

# --- Kullanıcıların Erişeceği Endpoint'ler ---

@router.get("/", response_model=List[schemas.SkillTestSimple])
def read_skill_tests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Platformdaki tüm mevcut yetkinlik testlerini listeler.
    """
    tests = crud_skill_test.get_skill_tests(db, skip=skip, limit=limit)
    return tests

@router.get("/{test_id}", response_model=schemas.SkillTest)
def read_skill_test(test_id: uuid.UUID, db: Session = Depends(get_db)):
    """
    Belirli bir yetkinlik testinin detaylarını (sorular ve şıklar dahil) getirir.
    Testi başlatmadan önce kullanıcıya gösterilecek olan ekrandır.
    """
    db_test = crud_skill_test.get_skill_test(db, test_id=test_id)
    if db_test is None:
        raise HTTPException(status_code=404, detail="Skill test not found")
    return db_test

@router.post(
    "/{test_id}/start", 
    response_model=schemas.TestResult, 
    status_code=status.HTTP_201_CREATED
)
def start_skill_test(
    test_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    # --- YENİ KONTROL ---
    existing_result = crud_test_result.get_completed_test_by_user_and_test(
        db, user_id=current_user.id, test_id=test_id
    )
    if existing_result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu testi daha önce tamamladınız. Tekrar çözemezsiniz."
        )
    # --- KONTROL BİTTİ ---

    db_test = crud_skill_test.get_skill_test(db, test_id=test_id)
    if db_test is None:
        raise HTTPException(status_code=404, detail="Skill test not found")
    
    return crud_test_result.create_test_result(db=db, user_id=current_user.id, test_id=test_id)

@router.post("/results/{result_id}/submit", response_model=schemas.TestResult)
def submit_skill_test(
    result_id: uuid.UUID,
    submission: schemas.TestSubmission,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Kullanıcının cevaplarını alır, testi sonlandırır ve puanı hesaplar.
    """
    db_result = crud_test_result.get_test_result(db, result_id=result_id)
    if db_result is None:
        raise HTTPException(status_code=404, detail="Test result not found")
    
    # Güvenlik kontrolü: Testi başlatan kullanıcı ile gönderen kullanıcı aynı mı?
    if db_result.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to submit this test")
        
    # Güvenlik kontrolü: Test zaten tamamlanmış mı?
    if db_result.status == models.TestStatus.COMPLETED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This test has already been completed")

    return crud_test_result.calculate_and_complete_test(db=db, result_id=result_id, submission=submission)