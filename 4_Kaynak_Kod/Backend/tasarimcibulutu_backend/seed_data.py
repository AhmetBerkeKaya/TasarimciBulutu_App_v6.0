# tasarimcibulutu_backend/seed_data.py

import sys
import os
import random
from datetime import datetime, timedelta, timezone

from faker import Faker
from sqlalchemy import text

# Proje dizinini yola ekle
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.project import Project, ProjectStatus, ProjectCategory, project_skill_association, ProjectRevision
from app.models.application import Application, ApplicationStatus
from app.models.showcase import ShowcasePost, ProcessingStatus
from app.models.skill import user_skill_association, showcase_skill_association
from app.models.portfolio import PortfolioItem, portfolio_item_skill_association
from app.models.audit import AuditLog
from app.models.notification import Notification
from app.models.message import Message
from app.models.review import Review
from app.models.test_result import TestResult
from app.models.work_experience import WorkExperience
from app import security

# Faker Ayarları
fake = Faker('tr_TR')

# Sabitler
NUM_CLIENTS = 10
NUM_FREELANCERS = 15
NUM_PROJECTS = 50
NUM_SHOWCASE = 30

# --- YENİ: GARANTİLİ GEÇERLİ TELEFON ÜRETİCİSİ ---
def generate_valid_tr_phone():
    # Sadece gerçek ve aktif operatör kodları
    prefixes = [
        "530", "531", "532", "533", "534", "535", "536", "537", "538", "539", # Turkcell
        "540", "541", "542", "543", "544", "545", "546", "547", "548", "549", # Vodafone
        "501", "505", "506", "507", "551", "552", "553", "554", "555", "559"  # Turk Telekom
    ]
    prefix = random.choice(prefixes)
    # Kalan 7 hane
    number = "".join([str(random.randint(0, 9)) for _ in range(7)])
    # Validatörün sevdiği format: +90...
    return f"+90{prefix}{number}"
# --------------------------------------------------

def clean_database(db):
    print("🧹 Veritabanı temizleniyor (Admin hariç)...")
    try:
        # Ara tabloları temizle
        db.execute(project_skill_association.delete())
        db.execute(showcase_skill_association.delete())
        db.execute(user_skill_association.delete())
        db.execute(portfolio_item_skill_association.delete())
        
        # Bağımlı verileri sil
        db.query(ProjectRevision).delete()
        db.query(Application).delete()
        db.query(Review).delete()
        db.query(Notification).delete()
        db.query(Message).delete()
        db.query(TestResult).delete()
        db.query(WorkExperience).delete()
        
        # Ana içerikleri sil
        db.query(ShowcasePost).delete()
        db.query(PortfolioItem).delete()
        db.query(Project).delete()
        db.query(AuditLog).delete()
        
        # Kullanıcıları sil (Admin hariç)
        db.query(User).filter(User.email != "admin@proaec.com").delete()
        
        db.commit()
        print("✨ Temizlik tamamlandı.")
    except Exception as e:
        db.rollback()
        print(f"❌ Temizlik hatası: {str(e)}")
        raise e

def create_seed_data():
    db = SessionLocal()
    
    try:
        # 1. Temizlik
        clean_database(db)
        
        print("🌱 Veri tohumlama başladı...")

        clients = []
        freelancers = []
        hashed_pwd = security.get_password_hash("123456")

        # --- 2. KULLANICILAR ---
        print("👤 Kullanıcılar ekleniyor...")
        
        # Firmalar
        for _ in range(NUM_CLIENTS):
            company_name = fake.company()
            user = User(
                email=f"client_{random.randint(10000,99999)}@example.com",
                password_hash=hashed_pwd,
                name=company_name, 
                role=UserRole.client,
                bio=fake.bs(),
                is_active=True,
                is_verified=True,
                phone_number=generate_valid_tr_phone(), # YENİ FONKSİYON
                profile_picture_url=f"https://ui-avatars.com/api/?name={company_name}&background=random",
                created_at=fake.date_time_between(start_date='-1y', end_date='now', tzinfo=timezone.utc),
                updated_at=datetime.now(timezone.utc)
            )
            db.add(user)
            clients.append(user)

        # Freelancerlar
        for _ in range(NUM_FREELANCERS):
            first_name = fake.first_name()
            last_name = fake.last_name()
            full_name = f"{first_name} {last_name}"
            
            user = User(
                email=f"freelancer_{random.randint(10000,99999)}@example.com",
                password_hash=hashed_pwd,
                name=full_name,
                role=UserRole.freelancer,
                bio=fake.job(),
                is_active=True,
                is_verified=random.choice([True, True, False]), 
                phone_number=generate_valid_tr_phone(), # YENİ FONKSİYON
                profile_picture_url=f"https://ui-avatars.com/api/?name={full_name}&background=random",
                created_at=fake.date_time_between(start_date='-1y', end_date='now', tzinfo=timezone.utc),
                updated_at=datetime.now(timezone.utc)
            )
            db.add(user)
            freelancers.append(user)

        db.commit()
        
        # ID'leri al
        for u in clients: db.refresh(u)
        for u in freelancers: db.refresh(u)

        # --- 3. PROJELER VE BAŞVURULAR ---
        print("mb Projeler ve Başvurular ekleniyor...")
        
        categories = list(ProjectCategory) 
        statuses = [ProjectStatus.OPEN, ProjectStatus.IN_PROGRESS, ProjectStatus.COMPLETED, ProjectStatus.CANCELLED]

        for _ in range(NUM_PROJECTS):
            owner = random.choice(clients)
            created_date = fake.date_time_between(start_date='-6M', end_date='now', tzinfo=timezone.utc)
            status = random.choices(statuses, weights=[30, 20, 40, 10], k=1)[0]
            
            budget_min = random.randint(5, 50) * 1000 
            budget_max = budget_min + random.randint(5, 20) * 1000

            project = Project(
                user_id=owner.id,
                title=fake.catch_phrase(),
                description=fake.paragraph(nb_sentences=3),
                category=random.choice(categories).value,
                budget_min=budget_min,
                budget_max=budget_max,
                status=status.value,
                deadline=created_date + timedelta(days=random.randint(15, 90)),
                created_at=created_date,
                updated_at=created_date
            )
            db.add(project)
            db.commit()
            db.refresh(project)

            # Başvurular
            num_apps = random.randint(1, 5)
            applicants = random.sample(freelancers, k=min(num_apps, len(freelancers)))
            has_accepted = False

            for freelancer in applicants:
                app_status = ApplicationStatus.pending
                proposed_budget = random.randint(budget_min, budget_max)

                if status in [ProjectStatus.COMPLETED, ProjectStatus.IN_PROGRESS] and not has_accepted:
                    app_status = ApplicationStatus.accepted
                    has_accepted = True
                elif status == ProjectStatus.CANCELLED:
                    app_status = ApplicationStatus.rejected
                else:
                    app_status = random.choice([ApplicationStatus.pending, ApplicationStatus.rejected])

                application = Application(
                    project_id=project.id,
                    freelancer_id=freelancer.id,
                    cover_letter=fake.paragraph(),
                    proposed_budget=proposed_budget,
                    proposed_duration=random.randint(7, 60),
                    status=app_status,
                    created_at=created_date + timedelta(days=random.randint(1, 5))
                )
                db.add(application)

        # --- 4. VİTRİN ---
        print("🖼️ Vitrin içerikleri ekleniyor...")
        image_urls = [
            "https://images.unsplash.com/photo-1600585154340-be6161a56a0c",
            "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c",
            "https://images.unsplash.com/photo-1503387762-592deb58ef4e",
            "https://images.unsplash.com/photo-1511818966892-d556758af421",
            "https://images.unsplash.com/photo-1581091226825-a6a2a5aee158"
        ]

        for _ in range(NUM_SHOWCASE):
            owner = random.choice(freelancers)
            post_date = fake.date_time_between(start_date='-3M', end_date='now', tzinfo=timezone.utc)
            
            post = ShowcasePost(
                user_id=owner.id,
                title=fake.sentence(nb_words=4).replace(".", ""),
                description=fake.text(),
                category=random.choice(['Mimari', 'Makine', 'Endüstriyel Tasarım', '3D Baskı']),
                file_url=random.choice(image_urls),
                thumbnail_url=random.choice(image_urls),
                processing_status=random.choice([ProcessingStatus.COMPLETED, ProcessingStatus.COMPLETED, ProcessingStatus.PROCESSING]),
                created_at=post_date,
                updated_at=post_date
            )
            db.add(post)

        db.commit()
        print("\n✅ İŞLEM BAŞARIYLA TAMAMLANDI! 🚀")

    except Exception as e:
        print(f"\n❌ HATA: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_seed_data()