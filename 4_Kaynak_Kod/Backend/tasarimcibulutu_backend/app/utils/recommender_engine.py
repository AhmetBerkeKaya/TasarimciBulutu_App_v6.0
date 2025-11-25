# app/utils/recommender_engine.py

import logging
from sqlalchemy.orm import Session, subqueryload
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.project import Project, ProjectStatus
from app.models.recommendation import ProjectRecommendation
from app.models.portfolio import PortfolioItem
from app.models.test_result import TestResult
from app.core.recommender import calculate_match_score

logger = logging.getLogger(__name__)

# Eşik Puanı (Bunun altındakileri önerme)
MINIMUM_SCORE_THRESHOLD = 0 

def run_recommendation_engine_background():
    """
    Bu fonksiyon arka planda çalışarak tüm freelancerlar için
    proje önerilerini hesaplar ve veritabanına yazar.
    """
    db = SessionLocal()
    logger.info("🚀 Öneri motoru çalışmaya başladı...")
    
    try:
        # 1. Aktif Freelancerları Çek (İlişkileriyle birlikte)
        freelancers = db.query(User).filter(
            User.role == UserRole.freelancer,
            User.is_active == True
        ).options(
            subqueryload(User.skills),
            subqueryload(User.portfolio_items).subqueryload(PortfolioItem.demonstrated_skills),
            subqueryload(User.test_results).subqueryload(TestResult.skill_test)
        ).all()

        # 2. Açık Projeleri Çek
        projects = db.query(Project).filter(
            Project.status == ProjectStatus.OPEN.value # Enum value'su string olarak
        ).options(
            subqueryload(Project.required_skills)
        ).all()

        if not freelancers or not projects:
            logger.warning("⚠️ Öneri hesaplamak için yeterli kullanıcı veya proje yok.")
            return

        total_recommendations = 0

        # 3. Hesaplama Döngüsü
        for freelancer in freelancers:
            new_recs = []
            
            for project in projects:
                # Kendi projesini kendine önerme
                if project.user_id == freelancer.id:
                    continue

                score = calculate_match_score(freelancer, project)
                
                if score >= MINIMUM_SCORE_THRESHOLD:
                    new_recs.append(
                        ProjectRecommendation(
                            user_id=freelancer.id,
                            project_id=project.id,
                            score=score
                        )
                    )
            
            if new_recs:
                # Eski önerileri sil
                db.query(ProjectRecommendation).filter(
                    ProjectRecommendation.user_id == freelancer.id
                ).delete()
                
                # Yenileri ekle
                db.bulk_save_objects(new_recs)
                total_recommendations += len(new_recs)
        
        db.commit()
        logger.info(f"✅ Öneri motoru tamamlandı. Toplam {total_recommendations} öneri kaydedildi.")

    except Exception as e:
        logger.error(f"❌ Öneri motoru hatası: {e}")
        db.rollback()
    finally:
        db.close()