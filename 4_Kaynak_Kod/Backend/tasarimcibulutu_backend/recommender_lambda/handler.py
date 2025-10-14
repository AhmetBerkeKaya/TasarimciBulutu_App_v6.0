# recommender_lambda/handler.py

import logging
from sqlalchemy.orm import Session, subqueryload
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.project import Project, ProjectStatus
from app.models.recommendation import ProjectRecommendation
from app.core.recommender import calculate_match_score
from app.models.portfolio import PortfolioItem
from app.models.test_result import TestResult

# Loglama ayarlarını yapılandıralım
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Önerinin kaydedilmesi için gereken minimum puan.
# Bu eşiği geçemeyen eşleşmeler, kullanıcıya önerilmeye değmez olarak kabul edilir.
MINIMUM_SCORE_THRESHOLD = 20

def get_db():
    """Veritabanı oturumu için yardımcı fonksiyon."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def handler(event, context):
    """
    AWS Lambda'nın ana giriş noktası.
    Tüm aktif freelancer'lar ve açık projeler için öneri puanlarını hesaplar ve kaydeder.
    """
    logger.info("Öneri hesaplama işlemi başlatıldı.")
    db: Session = next(get_db())

    try:
        # 1. Gerekli Verileri Veritabanından Çek
        # Sadece 'freelancer' rolündeki aktif kullanıcıları alıyoruz.
        # İlişkili verileri (skills, portfolio_items, test_results) tek sorguda çekmek için 'subqueryload' kullanıyoruz.
        # Bu, N+1 sorgu problemini önler ve performansı ciddi şekilde artırır.
        active_freelancers = db.query(User).filter(User.role == UserRole.freelancer).options(
            subqueryload(User.skills),
            subqueryload(User.portfolio_items).subqueryload(PortfolioItem.demonstrated_skills), # Düzeltildi
            subqueryload(User.test_results).subqueryload(TestResult.skill_test) # Düzeltildi
        ).all()

        # Sadece 'open' durumundaki projeleri alıyoruz.
        open_projects = db.query(Project).filter(Project.status == ProjectStatus.OPEN).options(
            subqueryload(Project.required_skills)
        ).all()
        
        logger.info(f"{len(active_freelancers)} aktif freelancer ve {len(open_projects)} açık proje bulundu.")

        if not active_freelancers or not open_projects:
            logger.info("Puanlanacak yeterli kullanıcı veya proje bulunamadı. İşlem sonlandırılıyor.")
            return {"status": "success", "message": "No users or projects to process."}

        # 2. Her Freelancer için Puanlama ve Kaydetme
        for freelancer in active_freelancers:
            new_recommendations = []
            
            for project in open_projects:
                score = calculate_match_score(freelancer, project)
                
                if score >= MINIMUM_SCORE_THRESHOLD:
                    new_recommendations.append(
                        ProjectRecommendation(
                            user_id=freelancer.id,
                            project_id=project.id,
                            score=score
                        )
                    )
            
            if not new_recommendations:
                # Eğer bu kullanıcı için hiçbir öneri bulunamadıysa bir sonraki kullanıcıya geç
                continue
            
            # 3. Eski Önerileri Temizle ve Yenileri Ekle
            # Bu işlemi her kullanıcı için döngü sonunda yaparak veritabanı yükünü dağıtıyoruz.
            logger.info(f"Kullanıcı {freelancer.id} için {len(new_recommendations)} yeni öneri bulundu. Veritabanı güncelleniyor...")
            
            # Atomik bir işlem için: önce sil, sonra ekle
            db.query(ProjectRecommendation).filter(ProjectRecommendation.user_id == freelancer.id).delete(synchronize_session=False)
            
            db.bulk_save_objects(new_recommendations)
            db.commit()

        logger.info("Öneri hesaplama işlemi başarıyla tamamlandı.")
        return {"status": "success"}

    except Exception as e:
        logger.error(f"Öneri hesaplama sırasında bir hata oluştu: {e}", exc_info=True)
        db.rollback()
        # Hata durumunda Lambda'nın başarısız olduğunu bildirmek önemlidir.
        raise e
    finally:
        db.close()