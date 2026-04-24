# app/utils/websocket_manager.py
from fastapi import WebSocket
from typing import Dict

class ConnectionManager:
    def __init__(self):
        # Hangi user_id'nin hangi WebSocket bağlantısında olduğunu tutan hafıza
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        print(f"🟢 WS Bağlandı: {user_id} (Şu an aktif olanlar: {len(self.active_connections)})")

    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            print(f"🔴 WS Koptu: {user_id}")

    async def send_personal_message(self, message: dict, user_id: str) -> bool:
        """Kullanıcı o an bağlıysa mesajı anında ekrana iletir (True), offline ise False döner"""
        if user_id in self.active_connections:
            websocket = self.active_connections[user_id]
            try:
                await websocket.send_json(message)
                return True # Başarıyla iletildi (Online)
            except Exception as e:
                print(f"⚠️ WS Gönderme Hatası: {e}")
                self.disconnect(user_id)
        return False # Kullanıcı uygulamada değil (Offline)

# Bu nesneyi projenin her yerinde ortak kullanacağız
manager = ConnectionManager()