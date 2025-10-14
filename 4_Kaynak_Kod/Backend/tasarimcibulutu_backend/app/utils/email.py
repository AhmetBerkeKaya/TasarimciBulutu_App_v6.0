# app/utils/email.py

from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
from app.config import settings
from typing import List

# SendGrid ayarlarını kullanarak bağlantı konfigürasyonunu oluştur
conf = ConnectionConfig(
    MAIL_USERNAME = settings.MAIL_USERNAME,
    MAIL_PASSWORD = settings.MAIL_PASSWORD,
    MAIL_FROM = settings.MAIL_FROM,
    MAIL_PORT = settings.MAIL_PORT,
    MAIL_SERVER = settings.MAIL_SERVER,
    MAIL_STARTTLS = settings.MAIL_STARTTLS,
    MAIL_SSL_TLS = settings.MAIL_SSL_TLS,
    USE_CREDENTIALS = True,
    VALIDATE_CERTS = True
)

async def send_password_reset_email(recipient_email: str, reset_code: str):
    """
    Kullanıcıya şifre sıfırlama kodunu içeren bir e-posta gönderir.
    """
    html_body = f"""
    <html>
        <body style="font-family: Arial, sans-serif; text-align: center; color: #333;">
            <div style="max-width: 600px; margin: auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
                <h2 style="color: #0056b3;">TasarimciBulutu Şifre Sıfırlama</h2>
                <p>Merhaba,</p>
                <p>Şifrenizi sıfırlamak için bir talepte bulundunuz. Aşağıdaki kodu kullanarak şifrenizi yenileyebilirsiniz.</p>
                <p style="font-size: 24px; font-weight: bold; letter-spacing: 5px; background-color: #f2f2f2; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    {reset_code}
                </p>
                <p>Bu kodu şifre sıfırlama ekranına girmeniz yeterlidir. Kod, {settings.RESET_TOKEN_EXPIRE_MINUTES} dakika sonra geçersiz olacaktır.</p>
                <p style="font-size: 0.9em; color: #777;">Eğer bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz.</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 0.8em; color: #aaa;">TasarimciBulutu Ekibi</p>
            </div>
        </body>
    </html>
    """

    message = MessageSchema(
        subject="TasarimciBulutu Şifre Sıfırlama Talebi",
        recipients=[recipient_email],
        body=html_body,
        subtype="html"
    )

    fm = FastMail(conf)
    try:
        await fm.send_message(message)
        print(f"Password reset email sent to {recipient_email}")
    except Exception as e:
        print(f"Failed to send email to {recipient_email}: {e}")

