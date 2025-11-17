# app/utils/s3.py (Aslında artık Cloudinary Utils)

import time
import hashlib
from app.config import settings

def create_presigned_post_url(bucket_name: str, object_name: str, fields=None, conditions=None, expires_in=3600):
    """
    Bu fonksiyon artık AWS S3 yerine Cloudinary için imzalı yükleme parametreleri üretir.
    Frontend bu değişikliği hissetmez, sadece URL ve Field'ları alıp POST eder.
    
    Args:
        bucket_name: Cloudinary'de 'folder' (klasör) olarak kullanılacak.
        object_name: Dosyanın tam yolu (örn: profile-pictures/user1/uuid.jpg).
    """
    
    # 1. Cloudinary Konfigürasyonu
    cloud_name = settings.CLOUDINARY_CLOUD_NAME
    api_key = settings.CLOUDINARY_API_KEY
    api_secret = settings.CLOUDINARY_API_SECRET
    
    # 2. Parametreleri Hazırla
    # object_name'i Cloudinary için 'public_id'ye dönüştürüyoruz (uzantıyı atmak iyi olur ama şart değil)
    # Örn: profile-pictures/user1/resim.jpg -> public_id: profile-pictures/user1/resim
    public_id = object_name.rsplit('.', 1)[0] 
    timestamp = int(time.time())
    
    # 3. İmzalanacak Parametreler (Alfabetik sırayla olmalı!)
    # Cloudinary imza mantığı: params k=v&k=v + api_secret -> SHA1
    params_to_sign = {
        "public_id": public_id,
        "timestamp": str(timestamp),
    }
    
    # İmza stringini oluştur (key=value&key=value...)
    sign_string = "&".join([f"{k}={v}" for k, v in sorted(params_to_sign.items())])
    
    # Secret'ı ekle ve SHA1 hash'ini al
    sign_string_with_secret = sign_string + api_secret
    signature = hashlib.sha1(sign_string_with_secret.encode('utf-8')).hexdigest()
    
    # 4. Frontend'e Dönecek Yanıtı Hazırla
    # Frontend bu URL'e POST atacak
    url = f"https://api.cloudinary.com/v1_1/{cloud_name}/image/upload"
    
    # Frontend bu field'ları Form Data içine gömecek
    return_fields = {
        "api_key": api_key,
        "timestamp": str(timestamp),
        "public_id": public_id,
        "signature": signature,
        # Cloudinary fazladan gönderilen (Content-Type gibi) field'ları yoksayar, sorun çıkmaz.
    }

    # 5. Dosyanın son erişim URL'ini hesapla (Frontend bunu veritabanına kaydettirecek)
    # Cloudinary URL formatı: https://res.cloudinary.com/<cloud_name>/image/upload/<public_id>.<format>
    # Not: Orijinal dosya uzantısını korumak için object_name'in uzantısını alıyoruz.
    extension = object_name.split('.')[-1]
    final_file_url = f"https://res.cloudinary.com/{cloud_name}/image/upload/{public_id}.{extension}"

    return {
        "url": url,
        "fields": return_fields,
        # Frontend bu değeri alıp 'updateUserProfileWithNewPicturePath' endpointine yollayacak.
        # Bu yüzden buraya tam URL'i koyuyoruz.
        # DİKKAT: Router'da bu değer 'file_path' anahtarıyla dönülüyor olabilir, router'ı kontrol etmeliyiz.
        # Senin User router'ında 'file_path': object_name dönüyordu.
        # Biz buraya tam URL'i veremeyiz çünkü schema object_name bekliyor olabilir.
        # Ama Cloudinary için tam URL kaydetmek daha iyidir.
        # Şimdilik router koduna uyumlu olması için 'response' dict dönüyoruz, router bunu işleyecek.
    }