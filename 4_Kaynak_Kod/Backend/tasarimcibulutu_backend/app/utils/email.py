import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import settings

# Eğer send_password_reset_email fonksiyonun farklı bir yerdeyse,
# sadece aşağıdaki "html_content" değişkenini oraya kopyalaman yeterli.

def send_password_reset_email(recipient_email: str, reset_code: str):
    subject = "🔒 Şifre Sıfırlama Talebi - Tasarımcı Bulutu"
    
    # --- PROFESYONEL HTML ŞABLONU ---
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f7f6; }}
            .container {{ max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }}
            .header {{ background: linear-gradient(135deg, #2563EB 0%, #1E40AF 100%); padding: 30px; text-align: center; color: white; }}
            .header h1 {{ margin: 0; font-size: 24px; letter-spacing: 1px; }}
            .content {{ padding: 40px 30px; color: #333333; line-height: 1.6; }}
            .code-box {{ background-color: #F3F4F6; border: 2px dashed #2563EB; border-radius: 8px; text-align: center; padding: 20px; margin: 30px 0; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1E40AF; }}
            .footer {{ background-color: #F8FAFC; padding: 30px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }}
            .brand-info {{ margin-top: 20px; padding-top: 20px; border-top: 1px solid #E2E8F0; text-align: left; }}
            .brand-info h3 {{ color: #2563EB; font-size: 16px; margin-bottom: 10px; }}
            .btn {{ display: inline-block; padding: 12px 24px; background-color: #2563EB; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; margin-top: 20px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1 style="color: black;">Tasarımcı Bulutu</h1>
                <p style="margin: 5px 0 0 0; font-size: 14px; opacity: 0.9; color: black">Türkiye'nin Tasarım Platformu</p>
            </div>
            <div class="content">
                <h2 style="color: #1E293B; margin-top: 0;">Şifre Sıfırlama Talebi</h2>
                <p>Merhaba,</p>
                <p>Tasarımcı Bulutu hesabınız için bir şifre sıfırlama talebi aldık. Hesabınızın güvenliği bizim için önemlidir. Aşağıdaki tek kullanımlık kodu kullanarak yeni şifrenizi belirleyebilirsiniz:</p>
                
                <div class="code-box">
                    {reset_code}
                </div>

                <p style="font-size: 14px; color: #666;">
                    ⚠️ <strong>Güvenlik Uyarısı:</strong> Bu kod <strong>15 dakika</strong> boyunca geçerlidir. Kodu kimseyle paylaşmayınız. Tasarımcı Bulutu ekibi sizden asla şifrenizi e-posta yoluyla istemez.
                </p>
                <p style="font-size: 14px; color: #999;">
                    Eğer bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz. Hesabınız güvendedir.
                </p>

                <div class="brand-info">
                    <h3>Tasarımcı Bulutu Nedir?</h3>
                    <p style="font-size: 13px; margin: 0;">
                        Tasarımcı Bulutu; mimar, mühendis ve tasarımcıları, proje ihtiyacı olan firmalarla buluşturan Türkiye'nin lider yetkinlik doğrulama ve iş platformudur. Güvenilir yetenek havuzumuz ve gelişmiş proje yönetim araçlarımızla sektörün dijital dönüşümüne öncülük ediyoruz.
                    </p>
                </div>
            </div>
            <div class="footer">
                <p>&copy; 2025 Tasarımcı Bulutu. Tüm Hakları Saklıdır.</p>
                <p>Bu e-posta otomatik olarak gönderilmiştir, lütfen yanıtlamayınız.</p>
            </div>
        </div>
    </body>
    </html>
    """
    # ---------------------------------------

    message = MIMEMultipart("alternative")
    message["Subject"] = subject
    message["From"] = settings.MAIL_FROM
    message["To"] = recipient_email
    message.attach(MIMEText(html_content, "html"))

    try:
        with smtplib.SMTP(settings.MAIL_SERVER, settings.MAIL_PORT) as server:
            server.starttls()
            server.login(settings.MAIL_USERNAME, settings.MAIL_PASSWORD)
            server.sendmail(settings.MAIL_FROM, recipient_email, message.as_string())
            print("✅ Email sent successfully")
    except Exception as e:
        print(f"❌ Failed to send email: {e}")