# app/schemas/showcase.py DOSYASININ NİHAİ HALİ

import uuid
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional, Literal
from datetime import datetime
from .user import UserSummary
from app.models.showcase import ProcessingStatus 

class CommentCreateBody(BaseModel):
    content: str
    parent_comment_id: Optional[str] = None

class CommentLike(BaseModel):
    user_id: uuid.UUID
    comment_id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)

class CommentBase(BaseModel):
    content: str

class CommentCreate(CommentBase):
    post_id: uuid.UUID
    parent_comment_id: Optional[str] = None

class Comment(CommentBase):
    id: uuid.UUID
    user_id: uuid.UUID
    post_id: uuid.UUID
    created_at: datetime
    author: UserSummary
    replies: List['Comment'] = []
    likes: List[CommentLike] = []
    model_config = ConfigDict(from_attributes=True)

class PostLike(BaseModel):
    user_id: uuid.UUID
    post_id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)

# ================== ANA DEĞİŞİKLİK BURADA ==================
class ShowcasePost(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    file_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    model_url: Optional[str] = None
    model_format: Optional[str] = None
    # --- EKSİK ALAN EKLENDİ ---
    model_urn: Optional[str] = None 
    # --------------------------
    processing_status: ProcessingStatus
    owner: UserSummary
    likes: List[PostLike] = []
    comments: List[Comment] = []
    model_config = ConfigDict(from_attributes=True)
# ==========================================================

class PresignedUrlResponse(BaseModel):
    url: str
    fields: dict
    final_file_url: str
    file_format: Optional[str] = None 

class PresignedUrlRequest(BaseModel):
    filename: str
    content_type: str
    file_category: Literal['image', 'model'] 

class ShowcasePostBase(BaseModel):
    title: str
    description: Optional[str] = None

class ShowcasePostCreate(BaseModel):
    title: str
    description: Optional[str] = None
    file_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    model_url: Optional[str] = None
    model_format: Optional[str] = None

class ShowcasePostUpdate(ShowcasePostBase):
    pass

class ShowcasePostInit(BaseModel):
    title: str
    description: Optional[str] = None
    original_filename: str

class PresignedUrlData(BaseModel):
    url: str
    fields: dict

class ShowcasePostInitResponse(BaseModel):
    post_id: uuid.UUID
    upload_data: PresignedUrlData

Comment.model_rebuild()
