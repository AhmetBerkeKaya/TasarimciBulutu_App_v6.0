from sqlalchemy.orm import Session
from app import models, schemas
import uuid
from app.models.showcase import ProcessingStatus
from . import audit as audit_crud
from app import models, schemas, crud
from app.models.notification import NotificationType

def create_showcase_post(db: Session, post: schemas.showcase.ShowcasePostCreate | schemas.showcase.ShowcasePostInit, user_id: uuid.UUID, status: ProcessingStatus = ProcessingStatus.COMPLETED) -> models.showcase.ShowcasePost:
    
    db_post = models.showcase.ShowcasePost(
        title=post.title,
        description=post.description,
        user_id=user_id,
        processing_status=status
    )
    
    if isinstance(post, schemas.showcase.ShowcasePostCreate):
        db_post.file_url=post.file_url
        db_post.thumbnail_url=post.thumbnail_url
        db_post.model_url=post.model_url
        db_post.model_format=post.model_format

    db.add(db_post)

    db.flush() 
    
    audit_crud.create_audit_log(
        db,
        user_id=user_id, # İşlemden etkilenen kullanıcı (gönderi sahibi)
        action="SHOWCASE_POST_CREATED",
        details={"post_id": str(db_post.id), "title": db_post.title}
    )


    db.commit()
    db.refresh(db_post)
    return db_post

def get_showcase_post(db: Session, post_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    return db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()

def get_all_showcase_posts(db: Session, skip: int = 0, limit: int = 100) -> list[models.showcase.ShowcasePost]:
    return db.query(models.showcase.ShowcasePost).order_by(models.showcase.ShowcasePost.created_at.desc()).offset(skip).limit(limit).all()

def delete_showcase_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    
    # Silme yetkisi kontrolü
    if db_post and db_post.user_id == user_id:
        audit_crud.create_audit_log(
            db,
            user_id=db_post.user_id, # İşlemden etkilenen kullanıcı (gönderi sahibi)
            actor_id=user_id, # İşlemi yapan kullanıcı
            action="SHOWCASE_POST_DELETED",
            details={"post_id": str(db_post.id), "title": db_post.title}
        )
        db.delete(db_post)
        db.commit()
        return db_post  
    return None

def like_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostLike | None:
    """
    Bir gönderiyi beğenir. Sadece başkası beğendiğinde gönderi sahibine bildirim gönderir.
    """
    db_post = get_showcase_post(db, post_id)
    
    # Sadece gönderi mevcut değilse işlem yapma
    if not db_post:
        return None

    # Kullanıcının daha önce beğenip beğenmediğini kontrol et
    db_like = db.query(models.showcase.PostLike).filter(
        models.showcase.PostLike.post_id == post_id, 
        models.showcase.PostLike.user_id == user_id
    ).first()
    
    # Zaten beğenilmişse, mevcut beğeniyi döndür
    if db_like: 
        return db_like
    
    # 1. Adım: Yeni beğeniyi oluştur ve kaydet
    new_like = models.showcase.PostLike(post_id=post_id, user_id=user_id)
    db.add(new_like)
    db.commit()
    db.refresh(new_like)

    # 2. Adım: Sadece başkası gönderiyi beğendiğinde bildirim gönder
    if db_post.user_id != user_id:
        try:
            liker = db.query(models.User).filter(models.User.id == user_id).first()
            if liker:
                notification_content = f"{liker.name}, '{db_post.title}' başlıklı gönderinizi beğendi."
                
                crud.notification.create_notification(
                    db=db,
                    user_id=db_post.user_id,
                    actor_id=user_id,
                    type=NotificationType.POST_LIKED,
                    content=notification_content,
                    related_entity_id=db_post.id
                )
        except Exception as e:
            print(f"Beğeni sonrası bildirim oluşturulurken hata oluştu: {e}")

    # 3. Adım: Oluşturulan beğeni nesnesini döndür
    return new_like

def unlike_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    db_like = db.query(models.showcase.PostLike).filter(models.showcase.PostLike.post_id == post_id, models.showcase.PostLike.user_id == user_id).first()
    if db_like: db.delete(db_like); db.commit(); return True
    return False

# --- GÜNCELLENMİŞ FONKSİYON ---
def create_comment(db: Session, comment: schemas.showcase.CommentCreate, user_id: uuid.UUID) -> models.showcase.PostComment:
    """
    Yeni bir yorum veya yanıt oluşturur.
    Eğer bir yanıtsa, hem yorum sahibine hem de gönderi sahibine bildirim gönderir.
    """
    # 1. Adım: Yorumu veritabanına kaydet
    db_comment = models.showcase.PostComment(
        content=comment.content,
        post_id=comment.post_id,
        parent_comment_id=comment.parent_comment_id,
        user_id=user_id
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)

    # 2. Adım: İlgili kişilere bildirim gönder
    try:
        commenter = db.query(models.User).filter(models.User.id == user_id).first()
        post = get_showcase_post(db, comment.post_id)

        if not commenter or not post:
            return db_comment

        parent_comment_owner_id = None # Çift bildirim engellemek için

        # BİLDİRİM 1: Eğer bu bir yanıtsa, YORUM SAHİBİNE BİLDİRİM GÖNDER
        if comment.parent_comment_id:
            parent_comment = get_comment(db, comment.parent_comment_id)
            if parent_comment and parent_comment.user_id != user_id:
                parent_comment_owner_id = parent_comment.user_id # Yorum sahibinin ID'sini kaydet
                
                notification_content = f"{commenter.name}, yorumunuza yanıt verdi."
                crud.notification.create_notification(
                    db=db,
                    user_id=parent_comment.user_id,
                    actor_id=user_id,
                    type=NotificationType.COMMENT_REPLIED,
                    content=notification_content,
                    related_entity_id=post.id
                )
        
        # BİLDİRİM 2: GÖNDERİ SAHİBİNE BİLDİRİM GÖNDER
        # Koşullar:
        # 1. Kişi kendi gönderisine yorum yapmıyor olmalı.
        # 2. Eğer bu bir yanıtsa ve gönderi sahibi aynı zamanda yorumun da sahibiyse,
        #    ona zaten yukarıda bildirim gönderildiği için tekrar gönderme.
        if post.user_id != user_id and post.user_id != parent_comment_owner_id:
            notification_content = f"{commenter.name}, '{post.title}' gönderinize bir yorum yaptı."
            crud.notification.create_notification(
                db=db,
                user_id=post.user_id,
                actor_id=user_id,
                type=NotificationType.POST_COMMENTED,
                content=notification_content,
                related_entity_id=post.id
            )

    except Exception as e:
        print(f"Yorum sonrası bildirim oluşturulurken hata oluştu: {e}")

    # 3. Adım: Oluşturulan yorum nesnesini döndür
    return db_comment

def get_comments_for_post(db: Session, post_id: uuid.UUID) -> list[models.showcase.PostComment]:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.post_id == post_id).order_by(models.showcase.PostComment.created_at.asc()).all()

def delete_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    db_comment = db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()
    if db_comment and (db_comment.user_id == user_id or db_comment.post.user_id == user_id):
        db.delete(db_comment); db.commit(); return db_comment
    return None

def get_comment(db: Session, comment_id: uuid.UUID) -> models.showcase.PostComment | None:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()

def like_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.CommentLike | None:
    """
    Bir yorumu beğenir. Sadece başkası beğendiğinde yorum sahibine bildirim gönderir.
    """
    db_comment = get_comment(db, comment_id)
    # Beğenilecek yorum yoksa veya kişi kendi yorumunu beğeniyorsa işlem yapma
    if not db_comment or db_comment.user_id == user_id:
        return None

    # Kullanıcının daha önce beğenip beğenmediğini kontrol et
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    
    # Zaten beğenilmişse, mevcut beğeniyi döndür
    if db_like:
        return db_like
        
    # 1. Adım: Yeni beğeniyi oluştur ve kaydet
    new_like = models.showcase.CommentLike(comment_id=comment_id, user_id=user_id)
    db.add(new_like)
    db.commit()
    db.refresh(new_like)

    # 2. Adım: Yorum sahibine bildirim gönder
    try:
        liker = db.query(models.User).filter(models.User.id == user_id).first()
        if liker:
            notification_content = f"{liker.name}, yorumunuzu beğendi."
            
            crud.notification.create_notification(
                db=db,
                user_id=db_comment.user_id,     # Bildirimi alacak kişi (yorum sahibi)
                actor_id=user_id,               # Eylemi yapan kişi (beğenen kullanıcı)
                type=NotificationType.COMMENT_LIKED,
                content=notification_content,
                related_entity_id=db_comment.post_id # Tıklayınca gönderiye gitmesi için
            )
    except Exception as e:
        print(f"Yorum beğenme sonrası bildirim oluşturulurken hata oluştu: {e}")

    # 3. Adım: Oluşturulan beğeni nesnesini döndür
    return new_like
def unlike_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    if db_like:
        db.delete(db_like)
        db.commit()
        return True
    return False

def update_post_raw_file_url(db: Session, post_id: uuid.UUID, file_url: str):
    db_post = db.query(models.ShowcasePost).filter(models.ShowcasePost.id == post_id).first()
    if db_post:
        db_post.file_url = file_url
        db.commit()
        db.refresh(db_post)
    return db_post
