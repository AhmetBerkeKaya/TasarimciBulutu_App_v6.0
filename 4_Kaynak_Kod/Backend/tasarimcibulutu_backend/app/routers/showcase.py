# app/routers/showcase.py

import uuid
import os
import json 
from fastapi import APIRouter, Depends, HTTPException, status, Request, UploadFile, File, Form, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from supabase import create_client, Client

from app import crud, schemas, models
from app.dependencies import get_db, get_current_user
from app.utils import s3 as s3_utils
from app.utils import model_processor
from app.config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.models.showcase import ProcessingStatus
from app.models.user import UserRole
from app.crud import audit as audit_crud 

# 🚀 YENİ İMPORT: Bildirim Motorumuz
from app.utils.push_sender import send_expo_push_notification

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(
    prefix="/showcase",
    tags=["Showcase"]
)

ALLOWED_FILE_EXTENSIONS = {".zip"}

def check_freelancer_permission(user: models.User):
    if user.role != UserRole.freelancer:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sadece Freelancer hesapları vitrine gönderi yükleyebilir."
        )

# =======================================================================
# 1. INITIALIZE UPLOAD
# =======================================================================
@router.post("/posts/initialize-upload", response_model=schemas.showcase.ShowcasePostInitResponse)
@limiter.limit("20/hour")
def initialize_post_upload(
    request: Request,
    post_init_data: schemas.showcase.ShowcasePostInit,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    check_freelancer_permission(current_user)

    _, file_extension = os.path.splitext(post_init_data.original_filename.lower())
    
    if file_extension not in ALLOWED_FILE_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed extensions are: {', '.join(ALLOWED_FILE_EXTENSIONS)}"
        )

    db_post = crud.showcase.create_showcase_post(db, post=post_init_data, user_id=current_user.id, status=ProcessingStatus.PENDING)

    if not db_post:
         raise HTTPException(status_code=500, detail="Database error: Post could not be created.")

    raw_file_key = f"uploads-raw/{db_post.id}{file_extension}"

    if file_extension == ".zip":
        try:
            project_id = settings.SUPABASE_URL.split("https://")[1].split(".")[0]
            raw_file_url = f"https://{project_id}.supabase.co/storage/v1/object/public/raw-files/{raw_file_key}"
        except IndexError:
            raw_file_url = f"{settings.SUPABASE_URL}/storage/v1/object/public/raw-files/{raw_file_key}"
    else:
        raw_file_url = f"https://res.cloudinary.com/{settings.CLOUDINARY_CLOUD_NAME}/image/upload/{raw_file_key}"

    crud.showcase.update_post_raw_file_url(db, post_id=db_post.id, file_url=raw_file_url)
    
    upload_data = s3_utils.create_presigned_post_url(
        bucket_name="raw-files",
        object_name=raw_file_key,
        conditions=[["content-length-range", 1, 524288000]],
        expires_in=3600
    )

    if not upload_data:
        raise HTTPException(status_code=500, detail="Could not generate upload URL")
        
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="SHOWCASE_POST_INIT",
        target_entity="showcase_posts",
        target_id=str(db_post.id),
        details=json.dumps({
            "post_id": str(db_post.id),
            "title": db_post.title,
            "filename": post_init_data.original_filename
        }), 
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    return schemas.showcase.ShowcasePostInitResponse(
        post_id=db_post.id,
        upload_data=schemas.showcase.PresignedUrlData(**upload_data)
    )

# =======================================================================
# 2. CREATE POST
# =======================================================================
@router.post("/posts", response_model=schemas.showcase.ShowcasePost, status_code=status.HTTP_201_CREATED)
@limiter.limit("20/hour")
def create_post(
    request: Request,
    post: schemas.showcase.ShowcasePostCreate, 
    background_tasks: BackgroundTasks, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    check_freelancer_permission(current_user)
    db_post = crud.showcase.create_showcase_post(db=db, post=post, user_id=current_user.id)
    
    if db_post:
        audit_crud.create_audit_log(
            db=db,
            user_id=current_user.id,
            action="SHOWCASE_POST_CREATED",
            target_entity="showcase_posts",
            target_id=str(db_post.id),
            details=json.dumps({
                "post_id": str(db_post.id),
                "title": db_post.title
            }),
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )

    if post.file_url and post.file_url.endswith('.zip'):
        background_tasks.add_task(
            model_processor.process_3d_model_background, 
            post_id=str(db_post.id), 
            file_url=post.file_url
        )
    
    return db_post

# =======================================================================
# 3. LIST POSTS
# =======================================================================
@router.get("/posts", response_model=List[schemas.showcase.ShowcasePost])
@limiter.limit("60/minute")
def read_all_posts(
    request: Request, 
    skip: int = 0, 
    limit: int = 20, 
    search: Optional[str] = None,
    sort_by: Optional[str] = 'newest', 
    db: Session = Depends(get_db)
):
    return crud.showcase.get_all_showcase_posts(
        db=db, 
        skip=skip, 
        limit=limit, 
        search=search,
        sort_by=sort_by
    )

# =======================================================================
# 4. READ SINGLE POST
# =======================================================================
@router.get("/posts/{post_id}", response_model=schemas.showcase.ShowcasePost)
@limiter.limit("120/minute")
def read_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db)):
    db_post = crud.showcase.get_showcase_post(db, post_id=post_id)
    if not db_post: raise HTTPException(status_code=404, detail="Post not found")
    return db_post

# =======================================================================
# 5. DELETE POST
# =======================================================================
@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("10/hour")
def delete_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    deleted_post = crud.showcase.delete_showcase_post(db, post_id=post_id, user_id=current_user.id)
    if not deleted_post:
        raise HTTPException(status_code=403, detail="Post not found or you don't have permission to delete it")
    
    audit_crud.create_audit_log(
        db=db,
        user_id=current_user.id,
        action="SHOWCASE_POST_DELETED",
        target_entity="showcase_posts",
        target_id=str(post_id),
        details="Vitrin gönderisi silindi.", 
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
    
    return

# =======================================================================
# 6. LIKE / UNLIKE
# =======================================================================
@router.post("/posts/{post_id}/like", response_model=schemas.showcase.PostLike, status_code=status.HTTP_201_CREATED)
@limiter.limit("100/minute")
def like_a_post(
    request: Request, 
    post_id: uuid.UUID, 
    background_tasks: BackgroundTasks, # 🚀 EKLENDİ
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    like = crud.showcase.like_post(db, post_id=post_id, user_id=current_user.id)
    if not like: raise HTTPException(status_code=404, detail="Post not found")

    # 🚀 AKILLI BİLDİRİM (BEĞENİ)
    post = crud.showcase.get_showcase_post(db, post_id=post_id)
    if post and post.owner and post.owner.id != current_user.id:
        if post.owner.push_enabled and post.owner.expo_push_token:
            background_tasks.add_task(
                send_expo_push_notification,
                token=post.owner.expo_push_token,
                title="Yeni Beğeni! ❤️",
                body=f"{current_user.name} bir vitrin gönderini beğendi.",
                data={"type": "like", "related_entity_id": str(post_id)}
            )

    return like

@router.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("100/minute")
def unlike_a_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    success = crud.showcase.unlike_post(db, post_id=post_id, user_id=current_user.id)
    if not success: raise HTTPException(status_code=404, detail="Like not found")
    return

# =======================================================================
# 7. COMMENTS
# =======================================================================
@router.post("/posts/{post_id}/comments", response_model=schemas.showcase.Comment, status_code=status.HTTP_201_CREATED)
@limiter.limit("30/hour")
def create_a_comment(
    request: Request,
    post_id: uuid.UUID,
    comment_data: schemas.showcase.CommentCreateBody,
    background_tasks: BackgroundTasks, # 🚀 EKLENDİ
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    comment_create_schema = schemas.showcase.CommentCreate(
        content=comment_data.content,
        post_id=post_id,
        parent_comment_id=comment_data.parent_comment_id
    )
    comment = crud.showcase.create_comment(db, comment=comment_create_schema, user_id=current_user.id)
    
    if comment:
        audit_crud.create_audit_log(
            db=db,
            user_id=current_user.id,
            action="COMMENT_CREATED",
            target_entity="comments",
            target_id=str(comment.id),
            details=json.dumps({"content": comment_data.content[:50]}),
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )

        # 🚀 AKILLI BİLDİRİM (YORUM)
        post = crud.showcase.get_showcase_post(db, post_id=post_id)
        if post and post.owner and post.owner.id != current_user.id:
            if post.owner.push_enabled and post.owner.expo_push_token:
                preview = comment_data.content[:40] + ("..." if len(comment_data.content) > 40 else "")
                background_tasks.add_task(
                    send_expo_push_notification,
                    token=post.owner.expo_push_token,
                    title="Yeni Yorum! 💬",
                    body=f"{current_user.name}: {preview}",
                    data={"type": "comment", "related_entity_id": str(post_id)}
                )
    
    return comment

@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("20/hour")
def delete_a_comment(request: Request, comment_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    deleted_comment = crud.showcase.delete_comment(db, comment_id=comment_id, user_id=current_user.id)
    if not deleted_comment: raise HTTPException(status_code=403, detail="Comment not found or not permitted")
    return

@router.post("/comments/{comment_id}/like", response_model=schemas.showcase.CommentLike, status_code=status.HTTP_201_CREATED)
@limiter.limit("100/minute")
def like_a_comment(
    request: Request,
    comment_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    like = crud.showcase.like_comment(db, comment_id=comment_id, user_id=current_user.id)
    if not like: raise HTTPException(status_code=404, detail="Comment not found")
    return like

@router.delete("/comments/{comment_id}/like", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("100/minute")
def unlike_a_comment(
    request: Request,
    comment_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    success = crud.showcase.unlike_comment(db, comment_id=comment_id, user_id=current_user.id)
    if not success: raise HTTPException(status_code=404, detail="Like not found")
    return

# =======================================================================
# 8. PROXY UPLOAD ENDPOINT
# =======================================================================
@router.post("/upload-proxy", status_code=status.HTTP_200_OK)
@limiter.limit("10/hour")
async def upload_proxy(
    request: Request,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    file_path: str = Form(...), 
    bucket: str = Form(...)     
):
    try:
        file_content = await file.read()
        supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        
        supabase.storage.from_(bucket).upload(
            path=file_path,
            file=file_content,
            file_options={"content-type": "application/zip"}
        )
        
        try:
            filename = file_path.split('/')[-1]
            post_id = filename.rsplit('.', 1)[0]
            project_id = settings.SUPABASE_URL.split("https://")[1].split(".")[0]
            file_url = f"https://{project_id}.supabase.co/storage/v1/object/public/{bucket}/{file_path}"
            
            background_tasks.add_task(
                model_processor.process_3d_model_background, 
                post_id=post_id, 
                file_url=file_url
            )
        except Exception as trigger_error:
            print(f"⚠️ Model işleme tetiklenirken hata: {trigger_error}")
        
        return {"message": "Upload successful and processing started via proxy"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))