import os
import boto3
import urllib.parse
import time
import psycopg2
from urllib.parse import urlparse
import requests
import uuid
import json
import base64
import zipfile
from io import BytesIO

# --- AYARLAR ---
APS_CLIENT_ID = os.environ.get('APS_CLIENT_ID')
APS_CLIENT_SECRET = os.environ.get('APS_CLIENT_SECRET')
DATABASE_URL_FROM_ENV = os.environ.get('DATABASE_URL')
PROCESSED_BUCKET_NAME = os.environ.get('PROCESSED_BUCKET_NAME')
AWS_REGION = os.environ.get('AWS_REGION', 'eu-north-1')

s3 = boto3.client('s3')
SUPPORTED_ROOT_FILES = [
    # Nötr ve Mesh Formatları
    '.obj', '.stl', '.step', '.stp', '.iges', '.igs', '.fbx', '.x_t', '.x_b',
    # Modern ve Web Formatları
    '.gltf', '.glb', '.3ds', '.x3d',
    # Popüler CAD Formatları
    '.sldprt', '.sldasm', '.ipt', '.iam', '.rvt', '.catpart', '.catproduct', '.cgr',
    '.prt', '.asm' # Creo ve NX için genel uzantılar
]
# ==============================================================================
# ANA LAMBDA HANDLER
# ==============================================================================
def lambda_handler(event, context):
    post_id = None
    access_token = None
    bucket_key = None
    object_urn = None # URN'yi burada tanımlıyoruz
    
    try:
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
        print(f"Yeni ZIP dosyası algılandı: {source_key}")
        
        post_id = os.path.splitext(os.path.basename(source_key))[0]
        update_database_status(post_id, 'PROCESSING')
        
        access_token = get_access_token()

        s3_object = s3.get_object(Bucket=source_bucket, Key=source_key)
        file_content = s3_object['Body'].read()
        
        root_filename = None
        with zipfile.ZipFile(BytesIO(file_content)) as z:
            file_list = z.namelist()
            print(f"ZIP içeriği: {file_list}")
            
            # Desteklenen dosya formatlarından herhangi birini ara
            for ext in SUPPORTED_ROOT_FILES:
                found_files = [f for f in file_list if f.lower().endswith(ext)]
                if found_files:
                    # En kısa dosya yoluna sahip olanı ana dosya olarak seç (genellikle kök dizindedir)
                    root_filename = min(found_files, key=len)
                    print(f"Desteklenen ana dosya bulundu: {root_filename}")
                    break
        
        if not root_filename:
            supported_formats_str = ', '.join(SUPPORTED_ROOT_FILES)
            raise Exception(f"ZIP içinde desteklenen bir dosya bulunamadı. Desteklenenler: {supported_formats_str}")

        bucket_key = f"temp{int(time.time())}{str(uuid.uuid4()).replace('-', '')}".lower()[:63]
        object_key = f"{post_id}.zip"
        create_bucket_oss(bucket_key, access_token)
        upload_response = upload_object_oss(bucket_key, object_key, file_content, len(file_content), access_token)
        
        print("Nesne yüklendi, çeviri işini başlatmadan önce 5 saniye bekleniyor...")
        time.sleep(5)
        
        # ================== URN'Yİ BURADA ALIYORUZ ==================
        object_urn = base64.b64encode(upload_response['objectId'].encode()).decode().rstrip('=')
        # ==========================================================
        
        submit_translation_job(object_urn, access_token, root_filename)

        manifest = wait_for_job_completion(object_urn, access_token)
        
        model_url, thumbnail_url, model_format = process_derivatives(manifest, object_urn, access_token, post_id)

        if model_url and thumbnail_url:
            # ================== URN'Yİ VERİTABANINA GÖNDERİYORUZ ==================
            update_database_record(post_id, 'COMPLETED', model_url, thumbnail_url, model_format, object_urn)
            # ===================================================================
            print("✅✅✅ İşlem başarıyla tamamlandı. Veritabanı güncellendi. ✅✅✅")
        else:
            raise Exception("Derivative dosyaları (model veya thumbnail) manifest içinde bulunamadı.")

        return {"status": "success", "postId": post_id}

    except Exception as e:
        print(f"KRİTİK HATA: {e}")
        import traceback
        traceback.print_exc()
        if post_id:
            update_database_status(post_id, 'FAILED')
        raise e
    finally:
        if access_token and bucket_key:
            try:
                cleanup_bucket_oss(bucket_key, access_token)
            except Exception as cleanup_error:
                print(f"Cleanup hatası (önemli değil): {cleanup_error}")

# ==============================================================================
# YARDIMCI FONKSİYONLAR
# ==============================================================================

def get_db_connection():
    result = urlparse(DATABASE_URL_FROM_ENV)
    return psycopg2.connect(dbname=result.path[1:], user=result.username, password=result.password, host=result.hostname, port=result.port)

def update_database_status(post_id, status):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE showcase_posts SET processing_status = %s, updated_at = NOW() WHERE id = %s", (status, post_id))
    print(f"Veritabanı durumu güncellendi: {post_id} -> {status}")

# ================== BU FONKSİYON GÜNCELLENDİ ==================
def update_database_record(post_id, status, model_url, thumbnail_url, model_format, model_urn):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            query = """
                UPDATE showcase_posts 
                SET 
                    processing_status = %s, 
                    model_url = %s, 
                    thumbnail_url = %s, 
                    model_format = %s, 
                    model_urn = %s, 
                    updated_at = NOW() 
                WHERE id = %s
            """
            cur.execute(query, (status, model_url, thumbnail_url, model_format, model_urn, post_id))
    print(f"Veritabanı kaydı güncellendi: {post_id}")
# =============================================================

# ... (get_access_token, create_bucket_oss, upload_object_oss, submit_translation_job, wait_for_job_completion fonksiyonları aynı) ...
def get_access_token():
    token_url = "https://developer.api.autodesk.com/authentication/v2/token"
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {
        'grant_type': 'client_credentials', 'client_id': APS_CLIENT_ID,
        'client_secret': APS_CLIENT_SECRET,
        'scope': 'data:read data:write data:create bucket:create code:all'
    }
    response = requests.post(token_url, headers=headers, data=data)
    response.raise_for_status()
    return response.json()['access_token']

def create_bucket_oss(bucket_key, access_token):
    url = "https://developer.api.autodesk.com/oss/v2/buckets"
    headers = {'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'}
    payload = {"bucketKey": bucket_key, "policyKey": "transient"}
    response = requests.post(url, headers=headers, json=payload)
    if response.status_code not in [200, 409]:
        response.raise_for_status()
    print(f"OSS Bucket oluşturuldu/mevcut: {bucket_key}")

def upload_object_oss(bucket_key, object_key, file_content, file_size, access_token):
    url = f"https://developer.api.autodesk.com/oss/v2/buckets/{bucket_key}/objects/{object_key}/signeds3upload"
    headers = {'Authorization': f'Bearer {access_token}'}
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    signed_data = response.json()
    
    upload_url = signed_data.get('url')
    if not upload_url:
        upload_url = signed_data['urls'][0]
        
    requests.put(upload_url, headers={'Content-Type':'application/zip'}, data=file_content).raise_for_status()
    
    finalize_url = f"https://developer.api.autodesk.com/oss/v2/buckets/{bucket_key}/objects/{object_key}/signeds3upload"
    payload = {"uploadKey": signed_data['uploadKey']}
    response = requests.post(finalize_url, headers=headers, json=payload)
    response.raise_for_status()
    print(f"Dosya OSS'ye yüklendi: {object_key}")
    return response.json()

def submit_translation_job(object_urn, access_token, root_filename):
    url = "https://developer.api.autodesk.com/modelderivative/v2/designdata/job"
    headers = {'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json', 'x-ads-force': 'true'}
    payload = {
        "input": {
            "urn": object_urn,
            "compressedUrn": True,
            "rootFilename": root_filename
        },
        "output": {
            "formats": [
                {"type": "svf", "views": ["3d"]},
                {"type": "thumbnail", "width": 400, "height": 400}
            ]
        }
    }
    print("----- GÖNDERİLEN İŞ PAYLOAD'I (NİHAİ) -----")
    print(json.dumps(payload, indent=2))
    print("---------------------------------------------")
    
    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()
    return response.json()

def wait_for_job_completion(object_urn, access_token, timeout_seconds=1800):
    start_time = time.time()
    while time.time() - start_time < timeout_seconds:
        url = f"https://developer.api.autodesk.com/modelderivative/v2/designdata/{object_urn}/manifest"
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            manifest = response.json()
            status = manifest.get('status')
            progress = manifest.get('progress', '')
            print(f"Job durumu: {status} - İlerleme: {progress}")
            if status == 'success': return manifest
            if status == 'failed': raise Exception(f"Translation job başarısız: {manifest.get('derivatives')}")
        elif response.status_code != 404:
            response.raise_for_status()
        time.sleep(20)
    raise Exception("Translation job zaman aşımına uğradı.")


def find_derivative_recursively(children, role_to_find):
    for child in children:
        if child.get('role') == role_to_find:
            return child
        if 'children' in child:
            found = find_derivative_recursively(child['children'], role_to_find)
            if found:
                return found
    return None

def process_derivatives(manifest, object_urn, access_token, post_id):
    model_url, thumbnail_url, model_format = None, None, None
    base_url = f"https://developer.api.autodesk.com/modelderivative/v2/designdata/{object_urn}/manifest"
    headers = {'Authorization': f'Bearer {access_token}'}

    print("----- ALINAN MANIFEST DOSYASI (NİHAİ) -----")
    print(json.dumps(manifest, indent=2))
    print("---------------------------------------------")

    thumbnail_child = find_derivative_recursively(manifest.get('derivatives', []), 'thumbnail')
    if thumbnail_child:
        try:
            derivative_urn = thumbnail_child['urn']
            content = requests.get(f"{base_url}/{derivative_urn}", headers=headers).content
            key = f"thumbnails/{post_id}.png"
            s3.put_object(Bucket=PROCESSED_BUCKET_NAME, Key=key, Body=content, ContentType='image/png')
            thumbnail_url = f"https://{PROCESSED_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{key}"
            print(f"✅ Thumbnail bulundu ve S3'e yüklendi: {thumbnail_url}")
        except Exception as e:
            print(f"❌ Thumbnail işlenirken hata oluştu: {e}")
    else:
        print("❌ Manifest içinde 'thumbnail' rolüne sahip dosya bulunamadı.")

    model_child = find_derivative_recursively(manifest.get('derivatives', []), 'graphics')
    if model_child:
        try:
            derivative_urn = model_child['urn']
            mime_type = model_child.get('mime')
            if mime_type == 'application/autodesk-svf':
                model_format = 'svf'
                file_extension = '.svf'
            elif mime_type == 'model/gltf-binary':
                model_format = 'glb'
                file_extension = '.glb'
            else:
                model_format = 'unknown'
                file_extension = ''

            content = requests.get(f"{base_url}/{derivative_urn}", headers=headers).content
            key = f"models-processed/{post_id}{file_extension}"
            s3.put_object(Bucket=PROCESSED_BUCKET_NAME, Key=key, Body=content, ContentType=mime_type)
            model_url = f"https://{PROCESSED_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{key}"
            print(f"✅ Model ({model_format}) bulundu ve S3'e yüklendi: {model_url}")
        except Exception as e:
            print(f"❌ Model işlenirken hata oluştu: {e}")
    else:
        print("❌ Manifest içinde 'graphics' rolüne sahip dosya bulunamadı.")

    return model_url, thumbnail_url, model_format

def cleanup_bucket_oss(bucket_key, access_token):
    print(f"Geçici OSS bucket siliniyor: {bucket_key}")
    url = f"https://developer.api.autodesk.com/oss/v2/buckets/{bucket_key}"
    headers = {'Authorization': f'Bearer {access_token}'}
    requests.delete(url, headers=headers)
