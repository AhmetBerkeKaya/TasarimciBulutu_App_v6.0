# app/utils/s3.py

import time
import hashlib
import requests # 🚀 SİLME İSTEKLERİ İÇİN EKLENDİ
from app.config import settings

def create_presigned_post_url(bucket_name: str, object_name: str, fields=None, conditions=None, expires_in=3600):
    """
    Resimler için Cloudinary URL'i, ZIP dosyaları için Backend Proxy URL'i döner.
    """
    
    # --- 1. KARAR ANI: ZIP Mİ RESİM Mİ? ---
    is_zip = object_name.lower().endswith('.zip')
    
    if is_zip:
        # === ROTA A: ZIP DOSYASI (SUPABASE İÇİN PROXY) ===
        proxy_url = f"{settings.API_BASE_URL}/showcase/upload-proxy"
        
        try:
            project_id = settings.SUPABASE_URL.split("https://")[1].split(".")[0]
            final_url = f"https://{project_id}.supabase.co/storage/v1/object/public/raw-files/{object_name}"
        except:
            final_url = ""

        return {
            "url": proxy_url,
            "fields": {
                "file_path": object_name, 
                "bucket": "raw-files"     
            },
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

# =====================================================================
# 🚀 YENİ EKLENDİ: AKILLI DOSYA İMHA MOTORU (CLOUDINARY & SUPABASE)
# =====================================================================
def delete_file_from_storage(file_url: str) -> bool:
    """
    Verilen URL'in Cloudinary mi yoksa Supabase mi olduğunu anlar ve 
    ilgili sunucuya giderek dosyayı fiziksel olarak tamamen siler.
    """
    if not file_url:
        return False

    try:
        # 1. DURUM: CLOUDINARY'DEN SİLME (Resimler)
        if "cloudinary.com" in file_url:
            parts = file_url.split('/upload/')
            if len(parts) > 1:
                path_part = parts[1]
                # Versiyon numarasını (v1234567/) atlıyoruz
                if path_part.startswith('v') and '/' in path_part:
                    path_part = path_part.split('/', 1)[1]
                
                public_id = path_part.rsplit('.', 1)[0] 
                
                cloud_name = settings.CLOUDINARY_CLOUD_NAME
                api_key = settings.CLOUDINARY_API_KEY
                api_secret = settings.CLOUDINARY_API_SECRET
                timestamp = int(time.time())
                
                params_to_sign = {
                    "public_id": public_id,
                    "timestamp": str(timestamp),
                }
                sign_string = "&".join([f"{k}={v}" for k, v in sorted(params_to_sign.items())])
                sign_string_with_secret = sign_string + api_secret
                signature = hashlib.sha1(sign_string_with_secret.encode('utf-8')).hexdigest()
                
                destroy_url = f"https://api.cloudinary.com/v1_1/{cloud_name}/image/destroy"
                data = {
                    "public_id": public_id,
                    "api_key": api_key,
                    "timestamp": str(timestamp),
                    "signature": signature
                }
                resp = requests.post(destroy_url, data=data)
                return resp.status_code == 200

        # 2. DURUM: SUPABASE'DEN SİLME (ZIP, PDF vb.)
        elif "supabase.co" in file_url:
            parts = file_url.split('/object/public/')
            if len(parts) > 1:
                bucket_and_path = parts[1] 
                bucket_name = bucket_and_path.split('/')[0] 
                file_path = bucket_and_path.split('/', 1)[1] 
                
                # Service Key (Kuralsız Silme Yetkisi) ile istek atıyoruz
                delete_url = f"{settings.SUPABASE_URL}/storage/v1/object/{bucket_name}/{file_path}"
                headers = {
                    "Authorization": f"Bearer {settings.SUPABASE_KEY}",
                }
                resp = requests.delete(delete_url, headers=headers)
                return resp.status_code == 200

        return False
    except Exception as e:
        print(f"❌ Dosya silinirken hata oluştu: {e}")
        return False