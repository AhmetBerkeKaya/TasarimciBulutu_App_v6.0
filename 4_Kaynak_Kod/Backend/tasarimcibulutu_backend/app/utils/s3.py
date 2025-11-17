# app/utils/s3.py

import time
import hashlib
from app.config import settings

def create_presigned_post_url(bucket_name: str, object_name: str, fields=None, conditions=None, expires_in=3600):
    """
    Resimler için Cloudinary URL'i, ZIP dosyaları için Backend Proxy URL'i döner.
    """
    
    # --- 1. KARAR ANI: ZIP Mİ RESİM Mİ? ---
    is_zip = object_name.lower().endswith('.zip')
    
    if is_zip:
        # === ROTA A: ZIP DOSYASI (SUPABASE İÇİN PROXY) ===
        
        # 1. Proxy URL (Android Emulator / Deploy)
        proxy_url = f"{settings.API_BASE_URL}/showcase/upload-proxy"
        
        # 2. Supabase Public URL'ini oluştur (Frontend bunu 'final_file_url' olarak bekliyor)
        # Format: https://<project_id>.supabase.co/storage/v1/object/public/<bucket>/<path>
        try:
            # settings.SUPABASE_URL genelde "https://xyz.supabase.co" şeklindedir.
            project_id = settings.SUPABASE_URL.split("https://")[1].split(".")[0]
            # DİKKAT: Router'da bucket adı 'raw-files' olarak sabitlendiği için burada da öyle kullanıyoruz.
            # Eğer dinamik gelirse 'bucket_name' parametresini kullan.
            final_url = f"https://{project_id}.supabase.co/storage/v1/object/public/raw-files/{object_name}"
        except:
            # URL parse edilemezse fallback (manuel kontrol gerekebilir)
            final_url = ""

        return {
            "url": proxy_url,
            "fields": {
                "file_path": object_name, # Dosyanın asıl adını field olarak saklıyoruz
                "bucket": "raw-files"     # Supabase bucket adı
            },
            # --- İŞTE EKSİK OLAN PARÇA BURASIYDI ---
            "final_file_url": final_url,
            "file_format": "zip"
        }

    else:
        # === ROTA B: RESİM DOSYASI (CLOUDINARY) ===
        cloud_name = settings.CLOUDINARY_CLOUD_NAME
        api_key = settings.CLOUDINARY_API_KEY
        api_secret = settings.CLOUDINARY_API_SECRET
        
        public_id = object_name.rsplit('.', 1)[0] 
        timestamp = int(time.time())
        
        params_to_sign = {
            "public_id": public_id,
            "timestamp": str(timestamp),
        }
        
        sign_string = "&".join([f"{k}={v}" for k, v in sorted(params_to_sign.items())])
        sign_string_with_secret = sign_string + api_secret
        signature = hashlib.sha1(sign_string_with_secret.encode('utf-8')).hexdigest()
        
        url = f"https://api.cloudinary.com/v1_1/{cloud_name}/image/upload"
        
        extension = object_name.split('.')[-1]
        final_file_url = f"https://res.cloudinary.com/{cloud_name}/image/upload/{public_id}.{extension}"

        return {
            "url": url,
            "fields": {
                "api_key": api_key,
                "timestamp": str(timestamp),
                "public_id": public_id,
                "signature": signature,
            },
            "final_file_url": final_file_url,
            "file_format": extension
        }