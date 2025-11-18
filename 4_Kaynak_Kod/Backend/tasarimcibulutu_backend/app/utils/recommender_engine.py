# app/utils/recommender_engine.py

import logging
from sqlalchemy.orm import Session, subqueryload
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.project import Project, ProjectStatus
from app.models.recommendation import ProjectRecommendation
from app.core.recommender import calculate_match_score
from app.models.portfolio import PortfolioItem
from app.models.test_result import TestResult
from app.models.notification import Notification, NotificationType  # Bildirim için

# Loglama ayarı
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

MINIMUM_SCORE_THRESHOLD = 20

def run_recommendation_engine_background():
    """
    Arka planda çalışan Öneri Motoru.
    AWS Lambda yerine artık bu fonksiyonu çağırıyoruz.
    """
    logger.info("🚀 Öneri Motoru (Background Task) başlatıldı.")
    
    # Her arka plan görevi kendi DB oturumunu açmalı ve kapatmalıdır.
    db: Session = SessionLocal()
    
    try:
        # 1. Verileri Çek
        # Sadece 'freelancer' rolündeki aktif kullanıcıları ve ilişkili verilerini al
        active_freelancers = db.query(User).filter(User.role == UserRole.freelancer).options(
            subqueryload(User.skills),
            subqueryload(User.portfolio_items).subqueryload(PortfolioItem.demonstrated_skills),
            subqueryload(User.test_results).subqueryload(TestResult.skill_test)
        ).all()

        # Sadece 'open' (Açık) durumdaki projeleri al
        open_projects = db.query(Project).filter(Project.status == ProjectStatus.OPEN).options(
            subqueryload(Project.required_skills)
        ).all()
        
        logger.info(f"Analiz edilecek: {len(active_freelancers)} Freelancer, {len(open_projects)} Proje.")

        if not active_freelancers or not open_projects:
            logger.info("Yeterli veri yok, işlem sonlandırılıyor.")
            return

        total_recommendations = 0

        # 2. Hesaplama Döngüsü
        for freelancer in active_freelancers:
            new_recommendations = []
            
            for project in open_projects:
                # app/core/recommender.py içindeki fonksiyonu kullanıyoruz
                score = calculate_match_score(freelancer, project)
                
                if score >= MINIMUM_SCORE_THRESHOLD:
                    new_recommendations.append(
                        ProjectRecommendation(
                            user_id=freelancer.id,
                            project_id=project.id,
                            score=score
                        )
                    )
            
            # 3. Veritabanını Güncelle (Atomik İşlem)
            # Bu kullanıcı için eski önerileri sil, yenilerini ekle
            if new_recommendations:
                # Önce eskileri temizle
                db.query(ProjectRecommendation).filter(ProjectRecommendation.user_id == freelancer.id).delete(synchronize_session=False)
                
                # Yenileri ekle
                db.bulk_save_objects(new_recommendations)
                db.commit()
                
                total_recommendations += len(new_recommendations)
                
                # İSTEĞE BAĞLI: Çok yüksek puanlı bir eşleşme varsa BİLDİRİM gönder
                # Örn: 80 puan üzeri "Sana çok uygun bir proje var!" diyebiliriz.
                for rec in new_recommendations:
                    if rec.score >= 80:
                        # Daha önce bildirim gitmemişse gönder (Bu mantık geliştirilebilir)
                        pass 

        logger.info(f"✅ Öneri Motoru tamamlandı. Toplam {total_recommendations} öneri oluşturuldu.")

    except Exception as e:
        logger.error(f"❌ Öneri Motoru Hatası: {e}", exc_info=True)
        db.rollback()
    finally:
        db.close() # Oturumu mutlaka kapat