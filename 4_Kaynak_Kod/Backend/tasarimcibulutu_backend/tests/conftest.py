# /tests/conftest.py

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.database import Base
from app.dependencies import get_db

# --- Test Veritabanı Kurulumu ---
# Gerçek veritabanı yerine, sadece bu test süresince hafızada (RAM) yaşayacak
# bir SQLite veritabanı kullanacağız. Bu, çok daha hızlıdır ve asıl verilerinizi güvende tutar.
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool, # SQLite için bu gerekli
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Testler boyunca kullanılacak sahte (override) 'get_db' fonksiyonu
def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

# --- Pytest "Fixture"ları ---

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    # Testler başlamadan önce, hafızadaki veritabanında tüm tabloları oluştur
    Base.metadata.create_all(bind=engine)
    yield
    # Testler bittikten sonra tabloları geri sil
    Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(setup_test_db):
    # 'get_db' bağımlılığını, bizim sahte 'override_get_db' fonksiyonumuzla değiştir.
    # Artık tüm API çağrıları gerçek veritabanı yerine hafızadaki test veritabanını kullanacak.
    app.dependency_overrides[get_db] = override_get_db
    
    # FastAPI için bir test istemcisi oluştur
    with TestClient(app) as test_client:
        yield test_client
    
    # Temizlik: Bir sonraki teste temiz bir sayfa açmak için
    # 'get_db' bağımlılığını eski haline getir.
    app.dependency_overrides.clear()