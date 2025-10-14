# app/utils/encryption.py

from cryptography.fernet import Fernet
from app.config import settings

# .env dosyasından gelen anahtarı kullanarak bir Fernet instance'ı oluşturuyoruz.
# Bu instance, uygulama çalıştığı sürece yeniden kullanılacak.
try:
    key = settings.ENCRYPTION_KEY.encode()
    fernet = Fernet(key)
except Exception as e:
    raise ValueError("ENCRYPTION_KEY geçerli bir Fernet anahtarı değil. Lütfen .env dosyanızı kontrol edin.") from e

def encrypt(data: str) -> str:
    """Verilen string veriyi şifreler."""
    if not isinstance(data, str):
        raise TypeError("Şifrelenecek veri string olmalıdır.")
    return fernet.encrypt(data.encode()).decode()

def decrypt(token: str) -> str:
    """Şifrelenmiş bir token'ı çözer."""
    if not isinstance(token, str):
        raise TypeError("Çözülecek token string olmalıdır.")
    return fernet.decrypt(token.encode()).decode()
