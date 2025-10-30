# /tests/test_user.py

from fastapi import status # HTTP durum kodlarını (200, 201, 400) adlarıyla kullanmak için

# 'client' parametresi, 'conftest.py' dosyasından otomatik olarak gelir
def test_create_user_success(client):
    """
    Başarılı bir kullanıcı kaydını test eder (201 Created).
    """
    # ========================================================================
    # ===                     DEĞİŞİKLİK BURADA                            ===
    # ========================================================================
    # user.py şemanıza göre düzeltilmiş veri
    user_data = {
        "email": "testuser@example.com",
        "password": "SuperGucluSifre123!",
        "name": "Test Kullanıcısı",          # 'full_name' -> 'name' olarak düzeltildi
        "role": "freelancer",             # 'user_type' -> 'role' olarak düzeltildi
        "phone_number": "+905551234567"   # Zorunlu 'phone_number' alanı eklendi
    }
    # ========================================================================
    
    # /users/ endpoint'ine POST isteği yapıyoruz
    response = client.post("/users/", json=user_data)
    if response.status_code != status.HTTP_201_CREATED:
        print("Hata Detayları:", response.json()) # <--- BU SATIRI EKLEYİN
    # --- KONTROLLER ---
    
    # 1. HTTP durum kodunun 201 (Created) olduğunu doğrula
    # Not: Eğer sizin kodunuz 200 (OK) dönüyorsa, burayı 200 yapın.
    assert response.status_code == status.HTTP_201_CREATED
    
    # 2. Dönen yanıtı (JSON) kontrol et
    data = response.json()
    assert data["email"] == "testuser@example.com"
    assert data["name"] == "Test Kullanıcısı" # 'full_name' -> 'name' olarak düzeltildi
    assert data["role"] == "freelancer"     # 'user_type' -> 'role' olarak düzeltildi
    
    # 3. Yanıtta 'id' anahtarının olduğunu doğrula
    assert "id" in data
    
    # 4. GÜVENLİK KONTROLÜ: Yanıtta 'password' OLMADIĞINI doğrula.
    assert "password" not in data
    assert "hashed_password" not in data


def test_create_user_duplicate_email(client):
    """
    Aynı e-posta ile ikinci kez kayıt olmayı dener (400 Bad Request).
    """
    # ========================================================================
    # ===                     DEĞİŞİKLİK BURADA                            ===
    # ========================================================================
    # user.py şemanıza göre düzeltilmiş veri
    user_data = {
        "email": "duplicate@example.com",
        "password": "SuperGucluSifre123!",
        "name": "Test Kullanıcısı",          # 'full_name' -> 'name' olarak düzeltildi
        "role": "freelancer",             # 'user_type' -> 'role' olarak düzeltildi
        "phone_number": "+905551234568"   # Zorunlu 'phone_number' alanı eklendi (farklı numara)
    }
    # ========================================================================
    response_1 = client.post("/users/", json=user_data)
    if response_1.status_code != status.HTTP_201_CREATED:
        print("Hata Detayları (İlk İstek):", response_1.json())
    # İlk kaydın başarılı olduğunu doğrula
    assert response_1.status_code == status.HTTP_201_CREATED
    
    # Şimdi, FARKLI şifre/isim ama AYNI e-posta ile ikinci kez POST isteği yap
    user_data_2 = {
        "email": "duplicate@example.com", # <--- E-posta aynı
        "password": "BaskaSifre456!",
        "name": "İkinci Kullanıcı",
        "role": "freelancer",
        "phone_number": "+905551234569"
    }
    response_2 = client.post("/users/", json=user_data_2)
    
    # --- KONTROLLER ---
    
    # 1. Bu kez, HTTP durum kodunun 400 (Bad Request) olduğunu doğrula
    assert response_2.status_code == status.HTTP_400_BAD_REQUEST
    
    # 2. Dönen hata mesajını kontrol et
    error_data = response_2.json()
    assert "detail" in error_data
    assert "Email already registered" in error_data["detail"] # Kodunuzda bu mesajın olduğunu varsayıyorum