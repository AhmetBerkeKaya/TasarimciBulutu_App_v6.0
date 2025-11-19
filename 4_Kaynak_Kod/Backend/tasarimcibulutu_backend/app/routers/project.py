# app/routers/project.py

from fastapi import APIRouter, Depends, HTTPException, status, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import Body
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from app import crud, schemas
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel, UserRole

limiter = Limiter(key_func=get_remote_address)

router = APIRouter(
    prefix="/projects",
    tags=["projects"]
)

# --- Proje Oluşturma ve Listeleme Endpoint'leri ---

@router.post("/", response_model=schemas.Project, status_code=status.HTTP_201_CREATED)
# Proje oluşturma kritik bir işlemdir, spam'i önlemek için sıkı bir limit koyalım.
@limiter.limit("10/hour")
def create_project(request: Request, project: schemas.ProjectCreate, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can create projects.")
    return crud.project.create_project(db=db, project=project, owner_id=current_user.id)

@router.get("/me", response_model=List[schemas.Project])
# Kullanıcının kendi projelerini listelemesi, genel listelemeye göre daha az sıklıkta kullanılır.
@limiter.limit("30/minute")
def read_my_projects(request: Request, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role == UserRole.client:
        return crud.project.get_projects_by_user(db, user_id=current_user.id)
    elif current_user.role == UserRole.freelancer:
        return crud.project.get_projects_for_freelancer(db, user_id=current_user.id)
    return []

@router.get("/", response_model=List[schemas.Project])
# Genel proje listesi en sık çağrılacak endpoint'tir. Scraping'i önlemek için global limitten daha sıkı olabilir.
@limiter.limit("60/minute")
def read_projects(
    request: Request,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    category: Optional[str] = None,
    min_budget: Optional[float] = None,
    max_budget: Optional[float] = None,
    sort_by: Optional[str] = None
):
    projects = crud.project.get_projects(
        db=db,
        skip=skip,
        limit=limit,
        search=search,
        category=category,
        min_budget=min_budget,
        max_budget=max_budget,
        sort_by=sort_by
    )
    return projects


@router.get("/{project_id}", response_model=schemas.Project)
# Tek bir proje detayını okumak daha az yoğundur.
@limiter.limit("120/minute")
def read_project(request: Request, project_id: UUID, db: Session = Depends(get_db)):
    db_project = crud.project.get_project(db=db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project

@router.get("/{project_id}/applications", response_model=List[schemas.Application])
@limiter.limit("60/minute")
def get_project_applications(request: Request, project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    project = crud.project.get_project(db, project_id=project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view applications for your own projects")
    return crud.application.get_applications_by_project(db, project_id=project_id)


# --- YENİ: Proje Güncelleme Endpoint'i ---
@router.put("/{project_id}", response_model=schemas.Project, summary="Firmanın projesini günceller")
@limiter.limit("20/hour")
def update_project(
    request: Request,
    project_id: UUID,
    project_update: schemas.ProjectUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    # 1. Yetki Kontrolü
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can update projects.")
    
    # Projeyi çek ve sahibini kontrol et
    db_project = crud.project.get_project(db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    if db_project.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only update your own projects.")
    
    # 2. CRUD fonksiyonunu çağır
    updated_project = crud.project.update_project(db=db, project_id=project_id, project_update=project_update)
    
    if not updated_project:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update project.")
        
    return updated_project

# --- YENİ: Proje Silme Endpoint'i ---
@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Firmanın projesini siler")
@limiter.limit("5/hour") # Silme işlemi daha kısıtlı olmalı
def delete_project(
    request: Request,
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    # 1. Yetki Kontrolü
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can delete projects.")

    # Projeyi çek ve sahibini kontrol et
    db_project = crud.project.get_project(db, project_id=project_id)
    if not db_project:
        # Silinmek istenen proje yoksa bile 204 dönebiliriz (idempotency)
        return {"detail": "Project not found or already deleted"} 
    
    if db_project.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only delete your own projects.")
    
    # 2. CRUD fonksiyonunu çağır
    crud.project.delete_project(db=db, project_id=project_id)
    
    # 204 No Content döndüğü için başarılı yanıt otomatik oluşur
    return {}

@router.put("/{project_id}/deliver", response_model=schemas.Project, summary="Freelancer işi teslim eder")
@limiter.limit("20/hour")
def deliver_project_as_freelancer(request: Request, project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.freelancer:
        raise HTTPException(status_code=403, detail="Only freelancers can deliver projects.")
    updated_project = crud.project.deliver_project(db=db, project_id=project_id, freelancer_id=current_user.id)
    if not updated_project:
        raise HTTPException(status_code=404, detail="Project not found, not in progress, or you are not the assigned freelancer.")
    return updated_project

@router.put("/{project_id}/accept", response_model=schemas.Project, summary="Firma teslimatı onaylar ve projeyi tamamlar")
@limiter.limit("20/hour")
def accept_delivery_and_complete_project(request: Request, project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=403, detail="Only clients can accept deliveries.")
    updated_project = crud.project.accept_and_complete_project(db=db, project_id=project_id, owner_id=current_user.id)
    if not updated_project:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Project is not in progress or you are not the assigned freelancer.")
    return updated_project

@router.put("/{project_id}/request-revision", response_model=schemas.Project, summary="Firma revizyon talep eder")
@limiter.limit("20/hour")
def request_revision_as_client(
    request: Request, 
    project_id: UUID, 
    reason: str = Body(..., embed=True), 
    db: Session = Depends(get_db), 
    current_user: UserModel = Depends(get_current_user)
):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=403, detail="Only clients can request revisions.")
    
    updated_project = crud.project.request_revision(
        db=db, 
        project_id=project_id, 
        owner_id=current_user.id,
        reason=reason 
    )
    
    if not updated_project:
        raise HTTPException(status_code=404, detail="Project not found, not pending review, or you are not the owner.")
    return updated_project