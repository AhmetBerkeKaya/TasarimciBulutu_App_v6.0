# app/utils/push_sender.py
import requests

def send_expo_push_notification(token: str, title: str, body: str, data: dict = None):
    """
    Expo sunucularını kullanarak hedeflenen telefona anlık (push) bildirim gönderir.
    """
    # Token geçerli mi diye basit bir kontrol
    if not token or not str(token).startswith("ExponentPushToken"):
        print("Geçersiz veya boş Expo Push Token. Bildirim gönderilmedi.")
        return False

    headers = {
        "Accept": "application/json",
        "Accept-encoding": "gzip, deflate",
        "Content-Type": "application/json",
    }
    
    payload = {
        "to": token,
        "title": title,
        "body": body,
        "data": data or {}, # Tıklayınca açılacak ekran verisi (Bavul)
        "sound": "default", # Telefonun varsayılan bildirim sesi
    }
    
    try:
        response = requests.post(
            "https://exp.host/--/api/v2/push/send", 
            headers=headers, 
            json=payload,
            timeout=5 # İstek çok uzun sürerse backend'i kilitlememesi için
        )
        
        if response.status_code == 200:
            print(f"Push Bildirim Başarıyla Gönderildi: {title}")
            return True
        else:
            print(f"Push Hatası: {response.text}")
            return False
            
    except Exception as e:
        print(f"Push bildirim gönderilirken bir hata oluştu: {e}")
        return False