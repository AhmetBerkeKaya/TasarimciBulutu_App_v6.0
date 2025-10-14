# app/utils/s3.py

import boto3
from botocore.exceptions import ClientError
from app.config import settings

# --- DÜZELTME: Fonksiyon parametresinin adı 'expiration' -> 'expires_in' olarak değiştirildi ---
def create_presigned_post_url(bucket_name: str, object_name: str, fields=None, conditions=None, expires_in=3600):
    """
    Flutter'dan doğrudan S3'e dosya yüklemek için bir Presigned URL ve gerekli alanları oluşturur.
    """
    s3_client = boto3.client(
        's3',
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_REGION,
        config=boto3.session.Config(signature_version='s3v4')
    )
    try:
        # Boto3'ün cevabı, Flutter'ın FormData'sına doğrudan eklenecek alanları içerir.
        # Content-Type bu alanlara dahil DEĞİLDİR, bu yüzden Flutter'da eklenmesi gerekir.
        response = s3_client.generate_presigned_post(
            Bucket=bucket_name,
            Key=object_name,
            Fields=fields,
            Conditions=conditions,
            # --- DÜZELTME: Boto3'e doğru parametre adı olan 'expires_in' geçiriliyor ---
            ExpiresIn=expires_in
        )
        print(f"✅ Presigned URL başarıyla oluşturuldu. Alanlar: {response['fields']}")
    except ClientError as e:
        print(f"❌ S3 Presigned URL oluşturma hatası: {e}")
        return None

    return response