# app/crud/showcase.py (GÜNCELLENMİŞ HALİ)
from typing import Optional
import logging # <-- EKLENDİ
from sqlalchemy.orm import Session, joinedload # <-- joinedload EKLENDİ
from app import models, schemas
import uuid
from app.models.showcase import ProcessingStatus
from . import audit as audit_crud
from app import models, schemas, crud
from app.models.notification import NotificationType
from sqlalchemy import or_
# === YENİ LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Bu modül için de INFO seviyesini ayarlıyoruz
# ===================

def create_showcase_post(db: Session, post: schemas.showcase.ShowcasePostCreate | schemas.showcase.ShowcasePostInit, user_id: uuid.UUID, status: ProcessingStatus = ProcessingStatus.COMPLETED) -> models.showcase.ShowcasePost | None:
    logger.info(f"Yeni vitrin gönderisi oluşturuluyor: KullanıcıID={user_id}, Başlık='{post.title}'") # <-- EKLENDİ
    
    try:
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
        logger.info(f"Vitrin gönderisi başarıyla oluşturuldu: ID={db_post.id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return db_post
    except Exception as e:
        logger.error(f"Vitrin gönderisi (KullanıcıID={user_id}) oluşturulurken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

def get_showcase_post(db: Session, post_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    return db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()

def get_all_showcase_posts(db: Session, skip: int = 0, limit: int = 100, search: Optional[str] = None) -> list[models.showcase.ShowcasePost]:
    logger.info(f"Vitrin gönderileri listeleniyor: Skip={skip}, Limit={limit}, Search='{search}'") # <-- Loglamayı da güncelleyelim
    
    query = db.query(models.showcase.ShowcasePost).order_by(models.showcase.ShowcasePost.created_at.desc())
    
    # === YENİ ARAMA MANTIĞI ===
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                models.showcase.ShowcasePost.title.ilike(search_term),
                models.showcase.ShowcasePost.description.ilike(search_term)
            )
        )
    # ==========================
        
    return query.offset(skip).limit(limit).all()

def delete_showcase_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    logger.info(f"Vitrin gönderisi siliniyor: ID={post_id}, KullanıcıID={user_id}") # <-- EKLENDİ
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    
    if not db_post:
        logger.warning(f"Silinmek istenen vitrin gönderisi bulunamadı: ID={post_id}") # <-- EKLENDİ
        return None
    
    # Silme yetkisi kontrolü
    if db_post.user_id != user_id:
        logger.warning(f"Vitrin gönderisi silme yetkisi reddedildi: ID={post_id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return None
        
    try:
        audit_crud.create_audit_log(
            db,
            user_id=db_post.user_id, # İşlemden etkilenen kullanıcı (gönderi sahibi)
            actor_id=user_id, # İşlemi yapan kullanıcı
            action="SHOWCASE_POST_DELETED",
            details={"post_id": str(db_post.id), "title": db_post.title}
        )
        db.delete(db_post)
        db.commit()
        logger.info(f"Vitrin gönderisi başarıyla silindi: ID={post_id}") # <-- EKLENDİ
        return db_post
    except Exception as e:
        logger.error(f"Vitrin gönderisi (ID={post_id}) silinirken HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

def like_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostLike | None:
    """
    Bir gönderiyi beğenir. Sadece başkası beğendiğinde gönderi sahibine bildirim gönderir.
    """
    logger.info(f"Gönderi beğeniliyor: GönderiID={post_id}, KullanıcıID={user_id}") # <-- EKLENDİ
    db_post = get_showcase_post(db, post_id)
    
    # Sadece gönderi mevcut değilse işlem yapma
    if not db_post:
        logger.warning(f"Beğenilmek istenen gönderi bulunamadı: ID={post_id}") # <-- EKLENDİ
        return None

    # Kullanıcının daha önce beğenip beğenmediğini kontrol et
    db_like = db.query(models.showcase.PostLike).filter(
        models.showcase.PostLike.post_id == post_id, 
        models.showcase.PostLike.user_id == user_id
    ).first()
    
    # Zaten beğenilmişse, mevcut beğeniyi döndür
    if db_like: 
        logger.info(f"Gönderi zaten beğenilmiş: GönderiID={post_id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return db_like
    
    new_like = None
    try:
        # 1. Adım: Yeni beğeniyi oluştur ve kaydet
        new_like = models.showcase.PostLike(post_id=post_id, user_id=user_id)
        db.add(new_like)
        db.commit()
        db.refresh(new_like)
    except Exception as e:
        logger.error(f"Gönderi (ID={post_id}) beğenilirken veritabanı HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

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
            # print() -> logger.error() olarak değiştirildi
            logger.error(f"Beğeni (GönderiID={post_id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ

    # 3. Adım: Oluşturulan beğeni nesnesini döndür
    return new_like

def unlike_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    logger.info(f"Gönderi beğenisi geri alınıyor: GönderiID={post_id}, KullanıcıID={user_id}") # <-- EKLENDİ
    db_like = db.query(models.showcase.PostLike).filter(models.showcase.PostLike.post_id == post_id, models.showcase.PostLike.user_id == user_id).first()
    if db_like: 
        try:
            db.delete(db_like)
            db.commit()
            logger.info(f"Gönderi beğenisi başarıyla geri alındı: GönderiID={post_id}, KullanıcıID={user_id}") # <-- EKLENDİ
            return True
        except Exception as e:
            logger.error(f"Gönderi beğenisi (ID={post_id}) geri alınırken HATA: {e}") # <-- EKLENDİ
            db.rollback() # <-- EKLENDİ
            return False
    return False

# --- GÜNCELLENMİŞ FONKSİYON ---
def create_comment(db: Session, comment: schemas.showcase.CommentCreate, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    """
    Yeni bir yorum veya yanıt oluşturur.
    Eğer bir yanıtsa, hem yorum sahibine hem de gönderi sahibine bildirim gönderir.
    """
    logger.info(f"Yeni yorum oluşturuluyor: GönderiID={comment.post_id}, KullanıcıID={user_id}, ParentID={comment.parent_comment_id}") # <-- EKLENDİ
    
    db_comment = None
    try:
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
    except Exception as e:
        logger.error(f"Yorum (GönderiID={comment.post_id}) oluşturulurken veritabanı HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

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
        # print() -> logger.error() olarak değiştirildi
        logger.error(f"Yorum (ID={db_comment.id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ

    # 3. Adım: Oluşturulan yorum nesnesini döndür
    return db_comment

def get_comments_for_post(db: Session, post_id: uuid.UUID) -> list[models.showcase.PostComment]:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.post_id == post_id).order_by(models.showcase.PostComment.created_at.asc()).all()

def delete_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    logger.info(f"Yorum siliniyor: YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
    
    # Silme yetkisi kontrolü için post bilgisini de çekmeliyiz (N+1 önlemek için joinedload)
    db_comment = db.query(models.showcase.PostComment).options(
        joinedload(models.showcase.PostComment.post)
    ).filter(models.showcase.PostComment.id == comment_id).first()
    
    if not db_comment:
        logger.warning(f"Silinmek istenen yorum bulunamadı: ID={comment_id}") # <-- EKLENDİ
        return None
        
    if db_comment.user_id == user_id or db_comment.post.user_id == user_id:
        try:
            db.delete(db_comment)
            db.commit()
            logger.info(f"Yorum başarıyla silindi: ID={comment_id}") # <-- EKLENDİ
            return db_comment
        except Exception as e:
            logger.error(f"Yorum (ID={comment_id}) silinirken HATA: {e}") # <-- EKLENDİ
            db.rollback() # <-- EKLENDİ
            return None
    else:
        logger.warning(f"Yorum silme yetkisi reddedildi: YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return None


def get_comment(db: Session, comment_id: uuid.UUID) -> models.showcase.PostComment | None:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()

def like_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.CommentLike | None:
    """
    Bir yorumu beğenir. Sadece başkası beğendiğinde yorum sahibine bildirim gönderir.
    """
    logger.info(f"Yorum beğeniliyor: YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
    
    db_comment = get_comment(db, comment_id)
    # Beğenilecek yorum yoksa veya kişi kendi yorumunu beğeniyorsa işlem yapma
    if not db_comment or db_comment.user_id == user_id:
        logger.warning(f"Yorum beğenilemedi (bulunamadı veya kendi yorumu): YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return None

    # Kullanıcının daha önce beğenip beğenmediğini kontrol et
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    
    # Zaten beğenilmişse, mevcut beğeniyi döndür
    if db_like:
        logger.info(f"Yorum zaten beğenilmiş: YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
        return db_like
    
    new_like = None
    try:
        # 1. Adım: Yeni beğeniyi oluştur ve kaydet
        new_like = models.showcase.CommentLike(comment_id=comment_id, user_id=user_id)
        db.add(new_like)
        db.commit()
        db.refresh(new_like)
    except Exception as e:
        logger.error(f"Yorum (ID={comment_id}) beğenilirken veritabanı HATA: {e}") # <-- EKLENDİ
        db.rollback() # <-- EKLENDİ
        return None

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
        # print() -> logger.error() olarak değiştirildi
        logger.error(f"Yorum beğenme (YorumID={comment_id}) sonrası bildirim HATA: {e}") # <-- GÜNCELLENDİ

    # 3. Adım: Oluşturulan beğeni nesnesini döndür
    return new_like

def unlike_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    logger.info(f"Yorum beğenisi geri alınıyor: YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
    
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    if db_like:
        try:
            db.delete(db_like)
            db.commit()
            logger.info(f"Yorum beğenisi başarıyla geri alındı: YorumID={comment_id}, KullanıcıID={user_id}") # <-- EKLENDİ
            return True
        except Exception as e:
            logger.error(f"Yorum beğenisi (YorumID={comment_id}) geri alınırken HATA: {e}") # <-- EKLENDİ
            db.rollback() # <-- EKLENDİ
            return False
    return False

def update_post_raw_file_url(db: Session, post_id: uuid.UUID, file_url: str):
    logger.info(f"Gönderi raw file_url güncelleniyor: GönderiID={post_id}") # <-- EKLENDİ
    db_post = db.query(models.ShowcasePost).filter(models.ShowcasePost.id == post_id).first()
    if db_post:
        try:
            db_post.file_url = file_url
            db.commit()
            db.refresh(db_post)
            logger.info(f"Gönderi raw file_url başarıyla güncellendi: GönderiID={post_id}") # <-- EKLENDİ
            return db_post
        except Exception as e:
            logger.error(f"Gönderi raw file_url (ID={post_id}) güncellenirken HATA: {e}") # <-- EKLENDİ
            db.rollback() # <-- EKLENDİ
            return None
    return db_post