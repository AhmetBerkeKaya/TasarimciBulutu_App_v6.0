# app/core/recommender.py

from app.models.user import User
from app.models.project import Project
from app.models.test_result import TestStatus

# --- PUANLAMA AĞIRLIKLARI ---
# Bu değerleri daha sonra kolayca ayarlayarak motorun davranışını değiştirebiliriz.
SCORE_WEIGHTS = {
    "REQUIRED_SKILL_MATCH": 15,   # Projenin aradığı bir yeteneğe sahip olma
    "PORTFOLIO_SKILL_BONUS": 10,  # Aranan yeteneği portfolyoda sergileme bonusu
    "VERIFIED_SKILL_BONUS": 30,   # Aranan yeteneğin test ile doğrulanmış olması bonusu ("ProAEC Onaylı")
    "CATEGORY_MATCH": 5           # Proje kategorisi ile freelancer'ın genel kategori uyumu
}


def calculate_match_score(freelancer: User, project: Project) -> int:
    """
    Bir freelancer ve bir proje arasındaki uygunluk puanını hesaplar.
    
    Args:
        freelancer (User): Puanlanacak freelancer'ın SQLAlchemy nesnesi.
        project (Project): Puanlanacak projenin SQLAlchemy nesnesi.

    Returns:
        int: Hesaplanan toplam uygunluk puanı.
    """
    total_score = 0

    # Verimlilik için freelancer'ın yeteneklerini, portfolyo yeteneklerini
    # ve doğrulanmış yeteneklerini birer set'e çevirelim.
    # Set'ler üzerinde arama yapmak listelere göre çok daha hızlıdır.
    freelancer_skills = {skill.id for skill in freelancer.skills}
    
    freelancer_portfolio_skills = {
        skill.id
        for item in freelancer.portfolio_items
        for skill in item.demonstrated_skills
    }

    # "Tamamlanmış" test sonuçlarından doğrulanan yeteneklerin ID'lerini al
    # ÖNEMLİ: test_result -> skill_test -> skill ilişkisinin doğru çalıştığını varsayıyoruz.
    # skill_test modelinde skill_id ForeignKey'i olmalı.
    freelancer_verified_skills = {
        result.skill_test.skill_id
        for result in freelancer.test_results
        if result.status == TestStatus.COMPLETED and result.skill_test.skill_id is not None
    }
    
    if not project.required_skills:
        # Eğer projenin aradığı bir yetenek belirtilmemişse, puanlama yapma.
        return 0

    # --- PUANLAMA MANTIĞI ---

    # 1. Gerekli Yetenek Eşleşmesi
    for required_skill in project.required_skills:
        if required_skill.id in freelancer_skills:
            # Freelancer, projenin aradığı bir yeteneğe sahip
            total_score += SCORE_WEIGHTS["REQUIRED_SKILL_MATCH"]
            
            # 2. Portfolyo Bonusu: Bu yeteneği portfolyosunda sergilemiş mi?
            if required_skill.id in freelancer_portfolio_skills:
                total_score += SCORE_WEIGHTS["PORTFOLIO_SKILL_BONUS"]
            
            # 3. Doğrulanmış Yetenek Bonusu: Bu yetenek için testi geçmiş mi?
            if required_skill.id in freelancer_verified_skills:
                total_score += SCORE_WEIGHTS["VERIFIED_SKILL_BONUS"]

    # 4. Kategori Uyum Bonusu (Basit bir kontrol)
    # Proje kategorisi, freelancer'ın portfolyo başlıklarında veya açıklamalarında geçiyor mu?
    # (Bu kısım gelecekte daha da geliştirilebilir, NLP kullanılabilir)
    if project.category:
        freelancer_text_blob = " ".join(
            item.title + " " + (item.description or "")
            for item in freelancer.portfolio_items
        )
        if project.category.lower() in freelancer_text_blob.lower():
            total_score += SCORE_WEIGHTS["CATEGORY_MATCH"]

    return total_score