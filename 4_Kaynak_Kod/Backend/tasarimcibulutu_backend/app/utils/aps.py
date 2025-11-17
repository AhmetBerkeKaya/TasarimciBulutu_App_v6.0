# app/utils/aps.py

import requests
import base64
import json
import time
from app.config import settings

class AutodeskClient:
    def __init__(self):
        self.client_id = settings.APS_CLIENT_ID
        self.client_secret = settings.APS_CLIENT_SECRET
        self.base_url = "https://developer.api.autodesk.com"
        self._access_token = None
        self._token_expires_at = 0

    def get_access_token(self):
        """Token alır veya süresi dolmuşsa yeniler."""
        if self._access_token and time.time() < self._token_expires_at:
            return self._access_token

        url = f"{self.base_url}/authentication/v2/token"
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        data = {
            'grant_type': 'client_credentials',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'scope': 'data:read data:write data:create bucket:create code:all'
        }
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        
        data = response.json()
        self._access_token = data['access_token']
        # Token süresinden 60 saniye önce yenilemek için marj bırakıyoruz
        self._token_expires_at = time.time() + data['expires_in'] - 60
        return self._access_token

    def create_bucket(self, bucket_key):
        """Geçici bir OSS bucket oluşturur."""
        token = self.get_access_token()
        url = f"{self.base_url}/oss/v2/buckets"
        headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
        payload = {"bucketKey": bucket_key, "policyKey": "transient"}
        
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code not in [200, 409]: # 409: Bucket zaten var
            response.raise_for_status()
        return bucket_key

    def upload_object(self, bucket_key, object_name, file_content):
        """Dosyayı Autodesk OSS'ye yükler."""
        token = self.get_access_token()
        
        # 1. Yükleme URL'i al
        url = f"{self.base_url}/oss/v2/buckets/{bucket_key}/objects/{object_name}/signeds3upload"
        headers = {'Authorization': f'Bearer {token}'}
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        signed_data = response.json()
        
        upload_url = signed_data.get('url') or signed_data['urls'][0]
        
        # 2. Dosyayı yükle
        requests.put(upload_url, data=file_content).raise_for_status()
        
        # 3. Yüklemeyi tamamla (Finalize)
        finalize_url = f"{self.base_url}/oss/v2/buckets/{bucket_key}/objects/{object_name}/signeds3upload"
        payload = {"uploadKey": signed_data['uploadKey']}
        response = requests.post(finalize_url, headers=headers, json=payload)
        response.raise_for_status()
        
        # Object ID'yi dön (URN üretmek için lazım)
        return response.json()

    def translate_object(self, object_urn, root_filename):
        """Model Çeviri İşini (Translation Job) başlatır."""
        token = self.get_access_token()
        url = f"{self.base_url}/modelderivative/v2/designdata/job"
        headers = {
            'Authorization': f'Bearer {token}', 
            'Content-Type': 'application/json', 
            'x-ads-force': 'true'
        }
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
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        return response.json()

    def check_manifest(self, object_urn):
        """Çeviri durumunu (Manifest) kontrol eder."""
        token = self.get_access_token()
        url = f"{self.base_url}/modelderivative/v2/designdata/{object_urn}/manifest"
        headers = {'Authorization': f'Bearer {token}'}
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        return None

    def get_derivative_content(self, derivative_urn):
        """Çevrilmiş dosya içeriğini (Model veya Thumbnail) indirir."""
        token = self.get_access_token()
        # URN encode edilmiş olduğu için base_url kısmına dikkat
        # Manifest içindeki URN zaten tam path veriyor olabilir veya vermeyebilir.
        # Genelde: /modelderivative/v2/designdata/{urn}/manifest/{derivativeUrn}
        # Ama manifest cevabında URN zaten tamdır.
        
        # Biz güvenli yöntemle base URL üzerinden gidelim:
        # API dökümanına göre derivative indirme URL'i:
        # GET https://developer.api.autodesk.com/modelderivative/v2/designdata/{urn}/manifest/{derivativeUrn}
        # Ancak `requests` ile aldığımız manifest içindeki URN'ler bazen farklı formatta olabiliyor.
        # Senin eski kodunda şöyle yapılmış:
        # base_url = f".../{object_urn}/manifest"
        # requests.get(f"{base_url}/{derivative_urn}")
        
        # Biz de aynısını yapalım ama fonksiyon parametreleri olarak alalım.
        pass 
        # (Bu fonksiyonu aşağıda process_derivatives içinde inline kullanacağız, buraya gerek yok)

    def cleanup_bucket(self, bucket_key):
        """Geçici bucket'ı siler."""
        token = self.get_access_token()
        url = f"{self.base_url}/oss/v2/buckets/{bucket_key}"
        headers = {'Authorization': f'Bearer {token}'}
        requests.delete(url, headers=headers)

# Tek bir instance oluşturalım
aps_client = AutodeskClient()