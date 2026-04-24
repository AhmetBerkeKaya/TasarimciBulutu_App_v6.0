import uuid
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks # 🚀 EKLENDİ
from sqlalchemy.orm import Session
from typing import List

from app import schemas, models
from app.crud import skill_test as crud_skill_test 
from app.crud import test_result as crud_test_result 
from app.dependencies import get_db, get_current_user
from app.models.test_result import TestStatus 
from app.models.user import UserRole # 🚀 EKLENDİ
from app.models.skill import Skill as SkillModel # 🚀 EKLENDİ
from app.utils.push_sender import send_expo_push_notification # 🚀 EKLENDİ

router = APIRouter(
    prefix="/skill-tests",
    tags=["Skill Tests"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=schemas.SkillTest, status_code=status.HTTP_201_CREATED)
def create_skill_test(
    test: schemas.SkillTestCreate, 
    background_tasks: BackgroundTasks, # 🚀 EKLENDİ
    db: Session = Depends(get_db)
):
    created_test = crud_skill_test.create_skill_test(db=db, test=test)
    
    # 🚀 AKILLI EŞLEŞTİRME VE BİLDİRİM MOTORU
    if created_test and created_test.skill_id:
        # Sadece bu yeteneğe sahip olan freelancerlara bildir
        matched_users = db.query(models.User).filter(
            models.User.role == UserRole.freelancer,
            models.User.push_enabled == True,
            models.User.expo_push_token.isnot(None),
            models.User.skills.any(SkillModel.id == created_test.skill_id)
        ).all()
        
        for user in matched_users:
            background_tasks.add_task(
                send_expo_push_notification,
                token=user.expo_push_token,
                title="Yeni Yetkinlik Testi! 📝",
                body=f"Uzmanı olduğun alanda yeni bir test eklendi: {created_test.title}. Hemen çöz ve rozetini al!",
                data={"type": "skill_test", "related_entity_id": str(created_test.id)}
            )
            
    return created_test

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