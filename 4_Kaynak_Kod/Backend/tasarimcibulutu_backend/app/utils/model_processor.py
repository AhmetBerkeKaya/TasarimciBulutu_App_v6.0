# app/utils/model_processor.py

import time
import uuid
import base64
import zipfile
import requests
from io import BytesIO
from sqlalchemy.orm import Session
from app import crud, models
from app.utils.aps import aps_client
from app.utils import s3 as s3_utils # Cloudinary yüklemesi için (ismini s3 bıraktık ama içi Cloudinary)
from app.models.showcase import ProcessingStatus
from app.database import SessionLocal # <-- EKLENDİ

# Desteklenen dosya uzantıları (Eski lambda kodundan alındı)
SUPPORTED_ROOT_FILES = [
    '.obj', '.stl', '.step', '.stp', '.iges', '.igs', '.fbx', '.x_t', '.x_b',
    '.gltf', '.glb', '.3ds', '.x3d',
    '.sldprt', '.sldasm', '.ipt', '.iam', '.rvt', '.catpart', '.catproduct', '.cgr',
    '.prt', '.asm'
]

def process_3d_model_background(post_id: str, file_url: str):
    """
    Arka planda çalışacak ana fonksiyon.
    1. Dosyayı Cloudinary'den (veya URL'den) indirir.
    2. Autodesk'e yükler ve çevirir.
    3. Sonuçları (Thumbnail, SVF) indirip tekrar Cloudinary'ye yükler.
    4. Veritabanını günceller.
    """
    print(f"🚀 Model İşleme Başladı! Post ID: {post_id}")
    db = SessionLocal() # Yeni oturum aç

    try:
        # Durumu güncelle: PROCESSING
        crud.showcase.update_post_status(db, post_id, ProcessingStatus.PROCESSING)
        
        # 1. Dosyayı İndir
        print(f"⬇️ Dosya indiriliyor: {file_url}")
        response = requests.get(file_url)
        response.raise_for_status()
        file_content = response.content
        
        # 2. ZIP Analizi (Ana dosyayı bul)
        root_filename = None
        with zipfile.ZipFile(BytesIO(file_content)) as z:
            file_list = z.namelist()
            for ext in SUPPORTED_ROOT_FILES:
                found = [f for f in file_list if f.lower().endswith(ext)]
                if found:
                    root_filename = min(found, key=len)
                    break
        
        if not root_filename:
            raise Exception("ZIP içinde desteklenen 3D model bulunamadı.")
        
        print(f"🔍 Ana dosya bulundu: {root_filename}")

        # 3. Autodesk OSS'ye Yükle
        bucket_key = f"temp{int(time.time())}{str(uuid.uuid4()).replace('-', '')}".lower()[:63]
        object_key = f"{post_id}.zip"
        
        aps_client.create_bucket(bucket_key)
        upload_res = aps_client.upload_object(bucket_key, object_key, file_content)
        
        # URN oluştur (base64 encode)
        object_urn = base64.b64encode(upload_res['objectId'].encode()).decode().rstrip('=')
        
        # 4. Çeviri İşini Başlat
        print("⏳ Çeviri işi başlatılıyor...")
        aps_client.translate_object(object_urn, root_filename)
        
        # 5. İşin Bitmesini Bekle (Polling)
        manifest = None
        status = "pending"
        start_time = time.time()
        
        while status not in ['success', 'failed', 'timeout']:
            if time.time() - start_time > 1800: # 30 dakika timeout
                status = 'timeout'
                break
            
            time.sleep(10) # 10 saniyede bir kontrol et
            manifest = aps_client.check_manifest(object_urn)
            if manifest:
                status = manifest.get('status')
                progress = manifest.get('progress', '')
                print(f"Job durumu: {status} (%{progress})")
        
        if status != 'success':
            raise Exception(f"Çeviri başarısız oldu. Durum: {status}")

        # 6. Sonuçları (Derivative) İşle
        print("✅ Çeviri tamamlandı. Dosyalar indiriliyor...")
        token = aps_client.get_access_token()
        headers = {'Authorization': f'Bearer {token}'}
        base_url = f"https://developer.api.autodesk.com/modelderivative/v2/designdata/{object_urn}/manifest"
        
        model_url = None
        thumbnail_url = None
        model_format = "svf" # Varsayılan

        # Recursive arama fonksiyonu (Lambda'dan alındı)
        def find_derivative(children, role):
            for child in children:
                if child.get('role') == role: return child
                if 'children' in child:
                    found = find_derivative(child['children'], role)
                    if found: return found
            return None

        derivatives = manifest.get('derivatives', [])
        
        # Thumbnail İşle
        thumb_node = find_derivative(derivatives, 'thumbnail')
        if thumb_node:
            urn = thumb_node['urn']
            # İçeriği indir
            content = requests.get(f"{base_url}/{urn}", headers=headers).content
            # Cloudinary'ye yükle (Burada requests.post ile direkt Cloudinary API'sine atabiliriz veya s3_utils kullanabiliriz)
            # s3_utils.create_presigned_post_url sadece URL veriyor, yükleme yapmıyor.
            # Python içinden Cloudinary yüklemesi için 'cloudinary' kütüphanesini kullanmak en kolayıdır.
            # Ama kütüphane eklemek istemezsek, requests ile POST atabiliriz.
            
            # --- BASİT YOL: CLOUDINARY KÜTÜPHANESİ KULLANMAK (ÖNERİLEN) ---
            # requirements.txt'ye 'cloudinary' eklemediysek, requests ile yapalım.
            # Ama Cloudinary'ye requests ile yüklemek imza (signature) gerektirir.
            # s3_utils içindeki 'create_presigned_post_url' fonksiyonundaki mantığı kullanarak
            # parametreleri üretip requests.post atacağız.
            
            # HIZLI ÇÖZÜM: s3_utils dosyasını import edip oradaki parametreleri alalım.
            params = s3_utils.create_presigned_post_url(
                bucket_name="processed", 
                object_name=f"thumbnails/{post_id}.png"
            )
            
            # Cloudinary'ye Yükle
            files = {'file': ('thumbnail.png', content, 'image/png')}
            # params['fields'] içindeki her şeyi data olarak ekle
            c_res = requests.post(params['url'], data=params['fields'], files=files)
            if c_res.status_code == 200:
                # Cloudinary yanıtından secure_url'i al
                thumbnail_url = c_res.json()['secure_url']
                print(f"🖼️ Thumbnail yüklendi: {thumbnail_url}")

        # Model (SVF) İşle
        model_node = find_derivative(derivatives, 'graphics')
        if model_node:
            urn = model_node['urn']
            content = requests.get(f"{base_url}/{urn}", headers=headers).content
            
            # Uzantıyı belirle
            mime = model_node.get('mime')
            ext = '.svf' if mime == 'application/autodesk-svf' else '.glb'
            model_format = 'svf' if mime == 'application/autodesk-svf' else 'glb'

            # Cloudinary'ye Yükle (Raw dosya olarak)
            # Cloudinary varsayılan olarak "image" yükler. "raw" (diğer dosyalar) için URL farklıdır.
            # s3_utils fonksiyonumuz 'image/upload' url'i dönüyordu. Onu 'raw/upload' yapmamız lazım.
            # Bunu manuel düzeltelim.
            
            params = s3_utils.create_presigned_post_url(
                bucket_name="processed", 
                object_name=f"models/{post_id}{ext}"
            )
            # URL'i 'image' -> 'raw' olarak değiştir
            upload_url = params['url'].replace('/image/upload', '/raw/upload')
            
            files = {'file': (f"model{ext}", content, 'application/octet-stream')}
            c_res = requests.post(upload_url, data=params['fields'], files=files)
            
            if c_res.status_code == 200:
                model_url = c_res.json()['secure_url']
                print(f"📦 Model yüklendi: {model_url}")

        # 7. Veritabanını Güncelle (Bitiş)
        if model_url and thumbnail_url:
            crud.showcase.update_post_processed_data(
                db, post_id, 
                model_url=model_url, 
                thumbnail_url=thumbnail_url, 
                model_format=model_format,
                model_urn=object_urn # İsteğe bağlı
            )
            crud.showcase.update_post_status(db, post_id, ProcessingStatus.COMPLETED)
            print("✅✅✅ İŞLEM BAŞARIYLA TAMAMLANDI ✅✅✅")
        else:
            raise Exception("Model veya Thumbnail oluşturulamadı.")

    except Exception as e:
        print(f"❌ HATA OLUŞTU: {e}")
        crud.showcase.update_post_status(db, post_id, ProcessingStatus.FAILED)
    finally:
        # Temizlik
        try:
            aps_client.cleanup_bucket(bucket_key)
        except:
            pass