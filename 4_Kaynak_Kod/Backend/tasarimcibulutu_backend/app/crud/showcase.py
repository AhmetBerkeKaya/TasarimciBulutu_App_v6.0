# app/crud/showcase.py (TAM GÜNCEL HALİ)

from typing import Optional
import logging
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
import uuid
from app.models.showcase import ProcessingStatus
from . import audit as audit_crud
from app import models, schemas, crud
from app.models.notification import NotificationType
from sqlalchemy import or_, desc, asc
from app.models.showcase import ProcessingStatus, ShowcasePost # Direkt import
from app.models.user import User
from app.models.skill import Skill

# === LOGGER ===
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# ==============

def create_showcase_post(db: Session, post: schemas.showcase.ShowcasePostCreate | schemas.showcase.ShowcasePostInit, user_id: uuid.UUID, status: ProcessingStatus = ProcessingStatus.COMPLETED) -> models.showcase.ShowcasePost | None:
    logger.info(f"Yeni vitrin gönderisi oluşturuluyor: KullanıcıID={user_id}, Başlık='{post.title}'")
    
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
            user_id=user_id,
            action="SHOWCASE_POST_CREATED",
            details={"post_id": str(db_post.id), "title": db_post.title}
        )

        db.commit()
        db.refresh(db_post)
        logger.info(f"Vitrin gönderisi başarıyla oluşturuldu: ID={db_post.id}, KullanıcıID={user_id}")
        return db_post
    except Exception as e:
        logger.error(f"Vitrin gönderisi (KullanıcıID={user_id}) oluşturulurken HATA: {e}")
        db.rollback()
        return None

def get_showcase_post(db: Session, post_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    return db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()

# app/crud/showcase.py İÇİNDEKİ get_all_showcase_posts FONKSİYONU

# app/crud/showcase.py İÇİNDEKİ get_all_showcase_posts FONKSİYONU

def get_all_showcase_posts(
    db: Session, 
    skip: int = 0, 
    limit: int = 100, 
    search: Optional[str] = None,
    skill: Optional[str] = None,
    sort_by: Optional[str] = 'newest' 
) -> list[ShowcasePost]:
    
    logger.info(f"🔍 Arama İsteği: Search='{search}', Sort='{sort_by}'")
    
    # 1. Temel sorguyu oluştur (Henüz filtreleme yok)
    query = db.query(ShowcasePost).options(
        joinedload(ShowcasePost.owner),
        joinedload(ShowcasePost.skills)
    )

    # 2. Sıralamayı uygula
    if sort_by == 'oldest':
        query = query.order_by(asc(ShowcasePost.created_at))
    else:
        query = query.order_by(desc(ShowcasePost.created_at))
    
    # 3. Tüm veriyi çek (Pagination olmadan, çünkü filtreleyip sayfalayacağız)
    # Not: Veri çoksa bu performans sorunu yaratır ama şifreli arama için mecburuz.
    # İleride ElasticSearch gibi bir çözüm gerekir.
    all_posts = query.all() 
    
    # 4. Python Tarafında Filtreleme (Şifreli veriler çözüldükten sonra)
    filtered_posts = []
    
    if search:
        search_lower = search.lower()
        for post in all_posts:
            # Başlık ve Açıklama (Normal string)
            title_match = post.title.lower().find(search_lower) != -1
            desc_match = post.description and post.description.lower().find(search_lower) != -1
            
            # Kullanıcı Adı (Şifreli string, erişince otomatik çözülür)
            owner_name_match = post.owner.name.lower().find(search_lower) != -1
            
            if title_match or desc_match or owner_name_match:
                filtered_posts.append(post)
    else:
        filtered_posts = all_posts

    # 5. Yetenek Filtresi (Varsa)
    if skill:
        skill_lower = skill.lower()
        filtered_posts = [
            p for p in filtered_posts 
            if any(s.name.lower().find(skill_lower) != -1 for s in p.skills)
        ]

    # 6. Sayfalama (Pagination) Manuel Yapılır
    start = skip
    end = skip + limit
    return filtered_posts[start:end]

def delete_showcase_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    logger.info(f"Vitrin gönderisi siliniyor: ID={post_id}, KullanıcıID={user_id}")
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    
    if not db_post:
        logger.warning(f"Silinmek istenen vitrin gönderisi bulunamadı: ID={post_id}")
        return None
    
    if db_post.user_id != user_id:
        logger.warning(f"Vitrin gönderisi silme yetkisi reddedildi: ID={post_id}, KullanıcıID={user_id}")
        return None
        
    try:
        audit_crud.create_audit_log(
            db,
            user_id=db_post.user_id,
            actor_id=user_id,
            action="SHOWCASE_POST_DELETED",
            details={"post_id": str(db_post.id), "title": db_post.title}
        )
        db.delete(db_post)
        db.commit()
        logger.info(f"Vitrin gönderisi başarıyla silindi: ID={post_id}")
        return db_post
    except Exception as e:
        logger.error(f"Vitrin gönderisi (ID={post_id}) silinirken HATA: {e}")
        db.rollback()
        return None

def like_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostLike | None:
    logger.info(f"Gönderi beğeniliyor: GönderiID={post_id}, KullanıcıID={user_id}")
    db_post = get_showcase_post(db, post_id)
    
    if not db_post:
        logger.warning(f"Beğenilmek istenen gönderi bulunamadı: ID={post_id}")
        return None

    db_like = db.query(models.showcase.PostLike).filter(
        models.showcase.PostLike.post_id == post_id, 
        models.showcase.PostLike.user_id == user_id
    ).first()
    
    if db_like: 
        logger.info(f"Gönderi zaten beğenilmiş: GönderiID={post_id}, KullanıcıID={user_id}")
        return db_like
    
    new_like = None
    try:
        new_like = models.showcase.PostLike(post_id=post_id, user_id=user_id)
        db.add(new_like)
        db.commit()
        db.refresh(new_like)
    except Exception as e:
        logger.error(f"Gönderi (ID={post_id}) beğenilirken veritabanı HATA: {e}")
        db.rollback()
        return None

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
            logger.error(f"Beğeni (GönderiID={post_id}) sonrası bildirim HATA: {e}")

    return new_like

def unlike_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    logger.info(f"Gönderi beğenisi geri alınıyor: GönderiID={post_id}, KullanıcıID={user_id}")
    db_like = db.query(models.showcase.PostLike).filter(models.showcase.PostLike.post_id == post_id, models.showcase.PostLike.user_id == user_id).first()
    if db_like: 
        try:
            db.delete(db_like)
            db.commit()
            logger.info(f"Gönderi beğenisi başarıyla geri alındı: GönderiID={post_id}, KullanıcıID={user_id}")
            return True
        except Exception as e:
            logger.error(f"Gönderi beğenisi (ID={post_id}) geri alınırken HATA: {e}")
            db.rollback()
            return False
    return False

def create_comment(db: Session, comment: schemas.showcase.CommentCreate, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    logger.info(f"Yeni yorum oluşturuluyor: GönderiID={comment.post_id}, KullanıcıID={user_id}, ParentID={comment.parent_comment_id}")
    
    db_comment = None
    try:
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
        logger.error(f"Yorum (GönderiID={comment.post_id}) oluşturulurken veritabanı HATA: {e}")
        db.rollback()
        return None

    try:
        commenter = db.query(models.User).filter(models.User.id == user_id).first()
        post = get_showcase_post(db, comment.post_id)

        if not commenter or not post:
            return db_comment

        parent_comment_owner_id = None

        if comment.parent_comment_id:
            parent_comment = get_comment(db, comment.parent_comment_id)
            if parent_comment and parent_comment.user_id != user_id:
                parent_comment_owner_id = parent_comment.user_id
                notification_content = f"{commenter.name}, yorumunuza yanıt verdi."
                crud.notification.create_notification(
                    db=db,
                    user_id=parent_comment.user_id,
                    actor_id=user_id,
                    type=NotificationType.COMMENT_REPLIED,
                    content=notification_content,
                    related_entity_id=post.id
                )
        
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
        logger.error(f"Yorum (ID={db_comment.id}) sonrası bildirim HATA: {e}")

    return db_comment

def get_comments_for_post(db: Session, post_id: uuid.UUID) -> list[models.showcase.PostComment]:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.post_id == post_id).order_by(models.showcase.PostComment.created_at.asc()).all()

def delete_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    logger.info(f"Yorum siliniyor: YorumID={comment_id}, KullanıcıID={user_id}")
    db_comment = db.query(models.showcase.PostComment).options(
        joinedload(models.showcase.PostComment.post)
    ).filter(models.showcase.PostComment.id == comment_id).first()
    
    if not db_comment:
        logger.warning(f"Silinmek istenen yorum bulunamadı: ID={comment_id}")
        return None
        
    if db_comment.user_id == user_id or db_comment.post.user_id == user_id:
        try:
            db.delete(db_comment)
            db.commit()
            logger.info(f"Yorum başarıyla silindi: ID={comment_id}")
            return db_comment
        except Exception as e:
            logger.error(f"Yorum (ID={comment_id}) silinirken HATA: {e}")
            db.rollback()
            return None
    else:
        logger.warning(f"Yorum silme yetkisi reddedildi: YorumID={comment_id}, KullanıcıID={user_id}")
        return None

def get_comment(db: Session, comment_id: uuid.UUID) -> models.showcase.PostComment | None:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()

def like_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.CommentLike | None:
    logger.info(f"Yorum beğeniliyor: YorumID={comment_id}, KullanıcıID={user_id}")
    db_comment = get_comment(db, comment_id)
    if not db_comment or db_comment.user_id == user_id:
        logger.warning(f"Yorum beğenilemedi (bulunamadı veya kendi yorumu): YorumID={comment_id}, KullanıcıID={user_id}")
        return None

    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    
    if db_like:
        logger.info(f"Yorum zaten beğenilmiş: YorumID={comment_id}, KullanıcıID={user_id}")
        return db_like
    
    new_like = None
    try:
        new_like = models.showcase.CommentLike(comment_id=comment_id, user_id=user_id)
        db.add(new_like)
        db.commit()
        db.refresh(new_like)
    except Exception as e:
        logger.error(f"Yorum (ID={comment_id}) beğenilirken veritabanı HATA: {e}")
        db.rollback()
        return None

    try:
        liker = db.query(models.User).filter(models.User.id == user_id).first()
        if liker:
            notification_content = f"{liker.name}, yorumunuzu beğendi."
            crud.notification.create_notification(
                db=db,
                user_id=db_comment.user_id,
                actor_id=user_id,
                type=NotificationType.COMMENT_LIKED,
                content=notification_content,
                related_entity_id=db_comment.post_id
            )
    except Exception as e:
        logger.error(f"Yorum beğenme (YorumID={comment_id}) sonrası bildirim HATA: {e}")

    return new_like

def unlike_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    logger.info(f"Yorum beğenisi geri alınıyor: YorumID={comment_id}, KullanıcıID={user_id}")
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    if db_like:
        try:
            db.delete(db_like)
            db.commit()
            logger.info(f"Yorum beğenisi başarıyla geri alındı: YorumID={comment_id}, KullanıcıID={user_id}")
            return True
        except Exception as e:
            logger.error(f"Yorum beğenisi (YorumID={comment_id}) geri alınırken HATA: {e}")
            db.rollback()
            return False
    return False

def update_post_raw_file_url(db: Session, post_id: uuid.UUID, file_url: str):
    logger.info(f"Gönderi raw file_url güncelleniyor: GönderiID={post_id}")
    # Modeli burada models.showcase.ShowcasePost olarak güncelledim, tutarlılık için
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    if db_post:
        try:
            db_post.file_url = file_url
            db.commit()
            db.refresh(db_post)
            logger.info(f"Gönderi raw file_url başarıyla güncellendi: GönderiID={post_id}")
            return db_post
        except Exception as e:
            logger.error(f"Gönderi raw file_url (ID={post_id}) güncellenirken HATA: {e}")
            db.rollback()
            return None
    return db_post

# ===========================================================
# ===         MODEL PROCESSOR İÇİN GEREKLİ EKLENTİLER       ===
# ===========================================================

def update_post_status(db: Session, post_id: uuid.UUID | str, status: ProcessingStatus):
    """Gönderinin işleme durumunu günceller."""
    logger.info(f"Gönderi durumu güncelleniyor: GönderiID={post_id}, Durum={status}")
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    if db_post:
        try:
            db_post.processing_status = status
            db.commit()
            db.refresh(db_post)
            logger.info(f"Gönderi durumu başarıyla güncellendi: {status}")
            return db_post
        except Exception as e:
            logger.error(f"Gönderi durumu güncellenirken HATA: {e}")
            db.rollback()
            return None
    return None

def update_post_processed_data(
    db: Session, 
    post_id: uuid.UUID | str, 
    model_url: str, 
    thumbnail_url: str, 
    model_format: str,
    model_urn: str = None
):
    """İşlenmiş model verilerini (APS çıktısı) kaydeder."""
    logger.info(f"İşlenmiş veri kaydediliyor: GönderiID={post_id}")
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    if db_post:
        try:
            db_post.model_url = model_url
            db_post.thumbnail_url = thumbnail_url
            db_post.model_format = model_format
            db_post.model_urn = model_urn
            db.commit()
            db.refresh(db_post)
            logger.info("İşlenmiş veri başarıyla kaydedildi.")
            return db_post
        except Exception as e:
            logger.error(f"İşlenmiş veri kaydedilirken HATA: {e}")
            db.rollback()
            return None
    return None