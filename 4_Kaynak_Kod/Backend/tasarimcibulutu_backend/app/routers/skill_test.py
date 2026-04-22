import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import schemas, models
from app.crud import skill_test as crud_skill_test 
from app.crud import test_result as crud_test_result 
from app.dependencies import get_db, get_current_user
from app.models.test_result import TestStatus 

router = APIRouter(
    prefix="/skill-tests",
    tags=["Skill Tests"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=schemas.SkillTest, status_code=status.HTTP_201_CREATED)
def create_skill_test(test: schemas.SkillTestCreate, db: Session = Depends(get_db)):
    return crud_skill_test.create_skill_test(db=db, test=test)

@router.get("/", response_model=List[schemas.SkillTestSimple])
def read_skill_tests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud_skill_test.get_skill_tests(db, skip=skip, limit=limit)

@router.get("/{test_id}", response_model=schemas.SkillTest)
def read_skill_test(test_id: uuid.UUID, db: Session = Depends(get_db)):
    db_test = crud_skill_test.get_skill_test(db, test_id=test_id)
    if db_test is None:
        raise HTTPException(status_code=404, detail="Skill test not found")
    return db_test

@router.post("/{test_id}/start", response_model=schemas.TestResult, status_code=status.HTTP_201_CREATED)
def start_skill_test(
    test_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    existing_result = db.query(models.TestResult).filter(
        models.TestResult.user_id == current_user.id,
        models.TestResult.test_id == test_id
    ).first()

    if existing_result:
        if existing_result.status == TestStatus.COMPLETED: 
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bu testi daha önce tamamladınız. Tekrar çözemezsiniz."
            )
        else:
            # 🚀 HARİKA DOKUNUŞ: Yarım bırakılan testte hata fırlatma, testi geri döndür!
            # Böylece frontend süreyi hesaplayıp kaldığı yerden devam ettirebilir.
            return existing_result

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
    db_result = crud_test_result.get_test_result(db, result_id=result_id)
    if db_result is None:
        raise HTTPException(status_code=404, detail="Test result not found")
    
    if db_result.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to submit this test")
        
    if db_result.status == TestStatus.COMPLETED: 
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This test has already been completed")

    return crud_test_result.calculate_and_complete_test(db=db, result_id=result_id, submission=submission)