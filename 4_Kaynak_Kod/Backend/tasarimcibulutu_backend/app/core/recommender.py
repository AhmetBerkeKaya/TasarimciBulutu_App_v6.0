# app/core/recommender.py

from app.models.user import User
from app.models.project import Project
from app.models.test_result import TestStatus

SCORE_WEIGHTS = {
    "REQUIRED_SKILL_MATCH": 20,   # Yetenek eşleşmesi puanı arttırıldı
    "PORTFOLIO_SKILL_BONUS": 15, 
    "VERIFIED_SKILL_BONUS": 40,   # Sertifikalı yetenek çok değerli
    "CATEGORY_MATCH": 25          # Kategori uyumu önemli
}

def calculate_match_score(freelancer: User, project: Project) -> int:
    total_score = 0

    # --- VERİ HAZIRLIĞI (Set kullanarak performans artışı) ---
    # Freelancer'ın beyan ettiği yetenekler
    freelancer_skill_ids = {s.id for s in freelancer.skills}
    
    # Portfolyosunda kanıtladığı yetenekler
    freelancer_portfolio_skill_ids = set()
    for item in freelancer.portfolio_items:
        for s in item.demonstrated_skills:
            freelancer_portfolio_skill_ids.add(s.id)

    # Test ile kanıtladığı yetenekler
    freelancer_verified_skill_ids = set()
    for result in freelancer.test_results:
        if result.status == TestStatus.COMPLETED and result.skill_test and result.skill_test.id:
             # Not: TestResult -> SkillTest -> Skill bağlantısı varsa skill.id'ye gitmek lazım
             # Şimdilik basit tutuyoruz, ileride buraya skill_id eklenebilir.
             pass 

    # --- 1. KATEGORİ UYUMU ---
    # Freelancer'ın portfolyosunda proje kategorisi geçiyor mu?
    # Veya Freelancer'ın bio'sunda var mı?
    user_text = (freelancer.bio or "").lower()
    if project.category and project.category.lower() in user_text:
        total_score += SCORE_WEIGHTS["CATEGORY_MATCH"]

    # --- 2. YETENEK EŞLEŞMESİ ---
    if project.required_skills:
        matched_skills = 0
        for req_skill in project.required_skills:
            skill_score = 0
            
            # Yeteneğe sahip mi?
            if req_skill.id in freelancer_skill_ids:
                skill_score += SCORE_WEIGHTS["REQUIRED_SKILL_MATCH"]
                
                # Portfolyoda var mı?
                if req_skill.id in freelancer_portfolio_skill_ids:
                    skill_score += SCORE_WEIGHTS["PORTFOLIO_SKILL_BONUS"]
                
                # (Opsiyonel) Testi var mı?
                # if req_skill.id in freelancer_verified_skill_ids: ...

            if skill_score > 0:
                matched_skills += 1
                total_score += skill_score
        
        # Bonus: Tüm yetenekleri karşılıyorsa ekstra puan
        if matched_skills == len(project.required_skills):
            total_score += 10

    return total_score