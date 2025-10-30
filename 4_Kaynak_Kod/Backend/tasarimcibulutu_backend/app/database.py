# app/database.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import declarative_base
from .config import settings
from sqlalchemy.types import TypeDecorator
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy import JSON

engine = create_engine(
    settings.DATABASE_URL,
    # pool_recycle: Belirli bir süre sonra (örn: 1 saat) eskiyen bağlantıları
    # proaktif olarak yeniler. Bu, uzun süre açık kalan bağlantıların
    # ağ cihazları tarafından kapatılmasını önler.
    pool_recycle=3600,

    # pool_pre_ping: Bir bağlantı havuzdan alınmadan hemen önce,
    # canlı olup olmadığını test etmek için basit bir sorgu gönderir.
    # Eğer bağlantı kopmuşsa, onu atar ve yerine yenisini koyar.
    # Bu, "server closed connection" hatasına karşı en sağlam çözümdür.
    pool_pre_ping=True
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class JSONB_or_JSON(TypeDecorator):
    """
    PostgreSQL için JSONB, SQLite için JSON kullanan bir çevirmen.
    """
    impl = JSONB
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "sqlite":
            # DÜZELTME: 'process' çağrısını kaldırdık.
            # Sadece 'JSON()' nesnesini döndürüyoruz.
            return JSON()
        else:
            # DÜZELTME: 'process' çağrısını kaldırdık.
            # Sadece 'self.impl' (yani JSONB nesnesini) döndürüyoruz.
            return self.impl