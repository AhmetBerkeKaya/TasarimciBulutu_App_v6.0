import smtplib
import os
from email.mime.text import MIMEText
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

SMTP_SERVER = os.getenv("MAIL_SERVER", "smtp.sendgrid.net")
SMTP_PORT = int(os.getenv("MAIL_PORT", 465))
SMTP_USERNAME = os.getenv("MAIL_USERNAME", "apikey")
SMTP_PASSWORD = os.getenv("MAIL_PASSWORD")
MAIL_FROM = os.getenv("MAIL_FROM")
MAIL_TO = MAIL_FROM # Kendine gönder

print(f"--- Mail Testi Başlıyor ---")
print(f"Sunucu: {SMTP_SERVER}:{SMTP_PORT}")
print(f"Gönderen: {MAIL_FROM}")

try:
    msg = MIMEText("Bu bir test mailidir.")
    msg['Subject'] = "Tasarimci Bulutu SMTP Test"
    msg['From'] = MAIL_FROM
    msg['To'] = MAIL_TO

    if SMTP_PORT == 465:
        # SSL Bağlantısı
        print("SSL ile bağlanılıyor...")
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            print("Giriş yapılıyor...")
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            print("Mail gönderiliyor...")
            server.sendmail(MAIL_FROM, [MAIL_TO], msg.as_string())
            print("✅ BAŞARILI: Mail gönderildi!")
    else:
        # TLS Bağlantısı (587)
        print("TLS ile bağlanılıyor...")
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            print("Giriş yapılıyor...")
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            print("Mail gönderiliyor...")
            server.sendmail(MAIL_FROM, [MAIL_TO], msg.as_string())
            print("✅ BAŞARILI: Mail gönderildi!")

except Exception as e:
    print(f"❌ HATA OLUŞTU: {e}")