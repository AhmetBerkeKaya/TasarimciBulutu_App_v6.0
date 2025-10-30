from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import UUID4

from app import crud, schemas, database

router = APIRouter(
    prefix="/test_results",
    tags=["test_results"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.TestResult)
def create_test_result(test_result: schemas.TestResultCreate, db: Session = Depends(get_db)):
    return crud.create_test_result(db, result=test_result)

@router.get("/", response_model=List[schemas.TestResult])
def read_test_results(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    test_results = crud.get_test_results(db, skip=skip, limit=limit)
    return test_results

@router.get("/{test_result_id}", response_model=schemas.TestResult)
def read_test_result(test_result_id: UUID4, db: Session = Depends(get_db)):
    db_test_result = crud.get_test_result(db, result_id=test_result_id)
    if not db_test_result:
        raise HTTPException(status_code=404, detail="Test result not found")
    return db_test_result


@router.delete("/{test_result_id}", response_model=schemas.TestResult)
def delete_test_result(test_result_id: UUID4, db: Session = Depends(get_db)):
    deleted_test_result = crud.delete_test_result(db, result_id=test_result_id)
    if not deleted_test_result:
        raise HTTPException(status_code=404, detail="Test result not found")
    return deleted_test_result
