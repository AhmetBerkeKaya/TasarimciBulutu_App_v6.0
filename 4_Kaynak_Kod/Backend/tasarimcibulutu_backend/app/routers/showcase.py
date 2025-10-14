# =======================================================================
# DOSYA 2: app/routers/showcase.py (Rate Limiting İyileştirildi)
# =======================================================================
import uuid
import os
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List

from app import crud, schemas, models
from app.dependencies import get_db, get_current_user
from app.utils import s3 as s3_utils
from app.config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.models.showcase import ProcessingStatus

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(
    prefix="/showcase",
    tags=["Showcase"]
)

ALLOWED_FILE_EXTENSIONS = {".zip"}

@router.post("/posts/initialize-upload", response_model=schemas.showcase.ShowcasePostInitResponse)
@limiter.limit("20/hour") # YENİ: Spam gönderi oluşturma denemelerini engeller
def initialize_post_upload(
    request: Request, # <-- Limiter için request parametresi eklendi
    post_init_data: schemas.showcase.ShowcasePostInit,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    _, file_extension = os.path.splitext(post_init_data.original_filename.lower())
    if file_extension not in ALLOWED_FILE_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed extensions are: {', '.join(ALLOWED_FILE_EXTENSIONS)}"
        )

    db_post = crud.showcase.create_showcase_post(db, post=post_init_data, user_id=current_user.id, status=ProcessingStatus.PENDING)

    raw_file_key = f"uploads-raw/{db_post.id}{file_extension}"

    raw_file_s3_url = f"https://{settings.AWS_S3_BUCKET_NAME}.s3.{settings.AWS_REGION}.amazonaws.com/{raw_file_key}"
    crud.showcase.update_post_raw_file_url(db, post_id=db_post.id, file_url=raw_file_s3_url)
    
    upload_data = s3_utils.create_presigned_post_url(
        bucket_name=settings.AWS_S3_BUCKET_NAME,
        object_name=raw_file_key,
        conditions=[["content-length-range", 1, 524288000]],
        expires_in=3600
    )

    if not upload_data:
        raise HTTPException(status_code=500, detail="Could not generate upload URL")

    return schemas.showcase.ShowcasePostInitResponse(
        post_id=db_post.id,
        upload_data=schemas.showcase.PresignedUrlData(**upload_data)
    )

# ... (dosyanın geri kalanı aynı, zaten limitleri vardı) ...
@router.post("/posts", response_model=schemas.showcase.ShowcasePost, status_code=status.HTTP_201_CREATED)
@limiter.limit("20/hour")
def create_post(
    request: Request,
    post: schemas.showcase.ShowcasePostCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    return crud.showcase.create_showcase_post(db=db, post=post, user_id=current_user.id)

@router.get("/posts", response_model=List[schemas.showcase.ShowcasePost])
@limiter.limit("60/minute")
def read_all_posts(request: Request, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    return crud.showcase.get_all_showcase_posts(db=db, skip=skip, limit=limit)

@router.get("/posts/{post_id}", response_model=schemas.showcase.ShowcasePost)
@limiter.limit("120/minute")
def read_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db)):
    db_post = crud.showcase.get_showcase_post(db, post_id=post_id)
    if not db_post: raise HTTPException(status_code=404, detail="Post not found")
    return db_post

@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("10/hour")
def delete_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    deleted_post = crud.showcase.delete_showcase_post(db, post_id=post_id, user_id=current_user.id)
    if not deleted_post:
        raise HTTPException(status_code=403, detail="Post not found or you don't have permission to delete it")
    return

@router.post("/posts/{post_id}/like", response_model=schemas.showcase.PostLike, status_code=status.HTTP_201_CREATED)
@limiter.limit("100/minute")
def like_a_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    like = crud.showcase.like_post(db, post_id=post_id, user_id=current_user.id)
    if not like:
        raise HTTPException(status_code=404, detail="Post not found")
    return like

@router.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("100/minute")
def unlike_a_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    success = crud.showcase.unlike_post(db, post_id=post_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Like not found")
    return

@router.post("/posts/{post_id}/comments", response_model=schemas.showcase.Comment, status_code=status.HTTP_201_CREATED)
@limiter.limit("30/hour")
def create_a_comment(
    request: Request,
    post_id: uuid.UUID,
    comment_data: schemas.showcase.CommentCreateBody,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    comment_create_schema = schemas.showcase.CommentCreate(
        content=comment_data.content,
        post_id=post_id,
        parent_comment_id=comment_data.parent_comment_id
    )
    return crud.showcase.create_comment(db, comment=comment_create_schema, user_id=current_user.id)

@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("20/hour")
def delete_a_comment(request: Request, comment_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    deleted_comment = crud.showcase.delete_comment(db, comment_id=comment_id, user_id=current_user.id)
    if not deleted_comment:
        raise HTTPException(status_code=403, detail="Comment not found or you don't have permission to delete it")
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
    if not like:
        raise HTTPException(status_code=404, detail="Comment not found")
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
    if not success:
        raise HTTPException(status_code=404, detail="Like not found")
    return