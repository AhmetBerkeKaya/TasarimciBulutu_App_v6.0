# /tests/test_auth.py
from urllib import response
import pytest # <-- BU SATIRI EKLEYİN
from fastapi import status
from fastapi.testclient import TestClient # TestClient'ı doğrudan import etmek iyi bir pratik

# Not: Testlerde gerçek şifreler yerine test verileri kullanıyoruz.
TEST_USER_EMAIL = "logintest@example.com"
TEST_USER_PASSWORD = "ValidPassword123!"

@pytest.fixture(scope="function")
def login_user_setup(client: TestClient):
# ==========================
    user_data = { ... } # İçerik aynı
    response = client.post("/users/", json=user_data)
    assert response.status_code == status.HTTP_201_CREATED, f"Login testi için kullanıcı oluşturulamadı: {response.json()}"
    yield TEST_USER_EMAIL

def test_login_success(client: TestClient, login_user_setup): # Fixture'ı ekledik
    """
    Başarılı kullanıcı girişini test eder (200 OK).
    """
    # FastAPI'nin OAuth2PasswordRequestForm'u 'username' ve 'password'
    # alanlarını form verisi olarak bekler (JSON değil).
    login_data = {
        "username": TEST_USER_EMAIL, # E-posta 'username' alanına gider
        "password": TEST_USER_PASSWORD
    }

    # /token endpoint'ine POST isteği yap (form verisi olarak)
    response = client.post("/token", data=login_data)
    if response.status_code == status.HTTP_401_UNAUTHORIZED:
            print("401 Hata Detayı:", response.json())
    # --- KONTROLLER ---
    # 1. Durum kodunun 200 (OK) olduğunu doğrula
    assert response.status_code == status.HTTP_200_OK

    # 2. Yanıtta 'access_token' ve 'token_type' anahtarlarının olduğunu doğrula
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer" # Kodunuzun 'bearer' döndürdüğünü varsayıyorum

def test_login_wrong_password(client: TestClient, login_user_setup): # Fixture'ı ekledik
    """
    Yanlış şifre ile girişi test eder (401 Unauthorized).
    """
    login_data = {
        "username": TEST_USER_EMAIL,
        "password": "YanlisSifre!" # Şifre yanlış
    }
    response = client.post("/token", data=login_data)

    # --- KONTROLLER ---
    # 1. Durum kodunun 401 (Unauthorized) olduğunu doğrula
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # 2. Hata detayını kontrol et (opsiyonel)
    error_data = response.json()
    assert "detail" in error_data
    # Kodunuzda 'Incorrect email or password' gibi bir mesaj varsa
    # assert "Incorrect" in error_data["detail"]

def test_login_nonexistent_user(client: TestClient):
    """
    Kayıtlı olmayan bir e-posta ile girişi test eder (401 Unauthorized).
    """
    login_data = {
        "username": "yokboylebireposta@example.com", # E-posta kayıtlı değil
        "password": "HerhangiBirSifre"
    }
    response = client.post("/token", data=login_data)

    # --- KONTROLLER ---
    # 1. Durum kodunun 401 (Unauthorized) olduğunu doğrula
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # 2. Hata detayını kontrol et (opsiyonel)
    error_data = response.json()
    assert "detail" in error_data
    # assert "Incorrect" in error_data["detail"]