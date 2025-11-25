# tasarimcibulutu_backend/create_admin.py

import sys
import os

# Proje dizinini yola ekle
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.user import User, UserRole
from app import security 

def create_or_update_super_admin():
    db = SessionLocal()
    
    email = "admin@proaec.com.tr"
    password = "123456" 
    phone = "+905555555555" # Geçerli format
    
    print(f"🔍 Kullanıcı aranıyor: {email} ...")
    
    # Kullanıcıyı bul
    user = db.query(User).filter(User.email == email).first()
    
    if user:
        print(f"♻️  Kullanıcı bulundu. Bilgileri GÜNCELLENİYOR...")
        # Silmek yerine güncelliyoruz (Audit Log hatasını önler)
        user.password_hash = security.get_password_hash(password)
        user.role = UserRole.admin
        user.phone_number = phone
        user.is_verified = True
        user.is_active = True
        user.name = "Super Admin"
        # updated_at güncelle
        user.updated_at = security.datetime.now(security.timezone.utc)
        
        db.commit()
        db.refresh(user)
        print("✅ GÜNCELLEME BAŞARILI! Mevcut kullanıcı Admin yapıldı.")
        
    else:
        print(f"🆕 Kullanıcı bulunamadı. Yeni oluşturuluyor...")
        new_admin = User(
            email=email,
            password_hash=security.get_password_hash(password),
            name="Super Admin",
            phone_number=phone,
            role=UserRole.admin,
            is_verified=True,
            is_active=True,
            created_at=security.datetime.now(security.timezone.utc),
            updated_at=security.datetime.now(security.timezone.utc)
        )
        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)
        print("✅ OLUŞTURMA BAŞARILI! Yeni Admin eklendi.")

    print(f"📧 Email: {email}")
    print(f"🔑 Şifre: {password}")
    
    db.close()

if __name__ == "__main__":
    create_or_update_super_admin()