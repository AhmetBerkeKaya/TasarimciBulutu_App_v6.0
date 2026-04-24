# app/routers/project.py

from fastapi import APIRouter, Depends, HTTPException, status, Request, Body, BackgroundTasks # 🚀 EKLENDİ
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app import crud, schemas
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel, UserRole
from app.models.skill import Skill as SkillModel # 🚀 BİLDİRİM SORGUSU İÇİN EKLENDİ
from app.crud import audit as audit_crud 
from app.utils.push_sender import send_expo_push_notification # 🚀 BİLDİRİM MOTORU

limiter = Limiter(key_func=get_remote_address)

router = APIRouter(
    prefix="/projects",
    tags=["projects"]
)

# --- Proje Oluşturma ve Listeleme Endpoint'leri ---

@router.post("/", response_model=schemas.Project, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/hour")
def create_project(
    request: Request, 
    project: schemas.ProjectCreate, 
    background_tasks: BackgroundTasks, # 🚀 EKLENDİ
    db: Session = Depends(get_db), 
    current_user: UserModel = Depends(get_current_user)
):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can create projects.")
    
    created_project = crud.project.create_project(db=db, project=project, owner_id=current_user.id)
    
    if created_project:
        audit_crud.create_audit_log(
            db=db,
            user_id=current_user.id,
            action="PROJECT_CREATED",
            target_entity="projects",
            target_id=str(created_project.id),
            details=f"Yeni proje oluşturuldu: {created_project.title}",
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )

        # 🚀 AKILLI EŞLEŞTİRME VE BİLDİRİM MOTORU
        if hasattr(created_project, 'required_skills') and created_project.required_skills:
            skill_ids = [skill.id for skill in created_project.required_skills]
            if skill_ids:
                # Sadece ilgili yeteneği olan freelancerları bul (Push izni açık olanlar)
                matched_users = db.query(UserModel).filter(
                    UserModel.role == UserRole.freelancer,
                    UserModel.push_enabled == True,
                    UserModel.expo_push_token.isnot(None),
                    UserModel.skills.any(SkillModel.id.in_(skill_ids))
                ).all()

                for user in matched_users:
                    background_tasks.add_task(
                        send_expo_push_notification,
                        token=user.expo_push_token,
                        title="Yeteneklerine Uygun Yeni İlan! 🎯",
                        body=f"{current_user.name} firması uzmanlık alanınla ilgili yeni bir proje yayınladı: {created_project.title}",
                        data={"type": "project", "related_entity_id": str(created_project.id)}
                    )
    
    return created_project

@router.get("/me", response_model=List[schemas.Project])
@limiter.limit("30/minute")
def read_my_projects(request: Request, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role == UserRole.client:
        return crud.project.get_projects_by_user(db, user_id=current_user.id)
    elif current_user.role == UserRole.freelancer:
        return crud.project.get_projects_for_freelancer(db, user_id=current_user.id)
    return []

@router.get("/", response_model=List[schemas.Project])
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

@router.put("/{project_id}", response_model=schemas.Project, summary="Firmanın projesini günceller")
@limiter.limit("20/hour")
def update_project(
    request: Request,
    project_id: UUID,
    project_update: schemas.ProjectUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can update projects.")
    
    db_project = crud.project.get_project(db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    if db_project.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only update your own projects.")
    
    updated_project = crud.project.update_project(db=db, project_id=project_id, project_update=project_update)
    
    if not updated_project:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update project.")

    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="PROJECT_UPDATED",
        target_entity="projects",
        target_id=str(updated_project.id),
        details=f"Proje güncellendi: {updated_project.title}",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
        
    return updated_project

@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Firmanın projesini siler")
@limiter.limit("5/hour")
def delete_project(
    request: Request,
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can delete projects.")

    db_project = crud.project.get_project(db, project_id=project_id)
    if not db_project:
        return {"detail": "Project not found or already deleted"} 
    
    if db_project.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only delete your own projects.")
    
    project_title = db_project.title 
    crud.project.delete_project(db=db, project_id=project_id)
    
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="PROJECT_DELETED",
        target_entity="projects",
        target_id=str(project_id),
        details=f"Proje silindi: {project_title}",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    return {}

@router.put("/{project_id}/deliver", response_model=schemas.Project, summary="Freelancer işi teslim eder")
@limiter.limit("20/hour")
def deliver_project_as_freelancer(request: Request, project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.freelancer:
        raise HTTPException(status_code=403, detail="Only freelancers can deliver projects.")
    
    updated_project = crud.project.deliver_project(db=db, project_id=project_id, freelancer_id=current_user.id)
    if not updated_project:
        raise HTTPException(status_code=404, detail="Project not found, not in progress, or you are not the assigned freelancer.")
    
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="PROJECT_DELIVERED",
        target_entity="projects",
        target_id=str(project_id),
        details=f"Proje teslim edildi.",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    return updated_project

@router.put("/{project_id}/accept", response_model=schemas.Project, summary="Firma teslimatı onaylar ve projeyi tamamlar")
@limiter.limit("20/hour")
def accept_delivery_and_complete_project(request: Request, project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=403, detail="Only clients can accept deliveries.")
    
    updated_project = crud.project.accept_and_complete_project(db=db, project_id=project_id, owner_id=current_user.id)
    if not updated_project:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Project is not in progress or you are not the assigned freelancer.")
    
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="PROJECT_COMPLETED",
        target_entity="projects",
        target_id=str(project_id),
        details=f"Proje onaylandı ve tamamlandı.",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

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
    
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="REVISION_REQUESTED",
        target_entity="projects",
        target_id=str(project_id),
        details=f"Revizyon istendi. Sebep: {reason}",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    return updated_project