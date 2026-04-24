# app/routers/message.py
from fastapi import APIRouter, Depends, HTTPException, status, Response, BackgroundTasks, WebSocket, WebSocketDisconnect
from fastapi.encoders import jsonable_encoder
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
import asyncio

from app import schemas, models
from app.crud import message as message_crud, user as user_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel

from app.utils.push_sender import send_expo_push_notification
from app.utils.websocket_manager import manager
from jose import jwt, JWTError
from app.config import settings

router = APIRouter(
    prefix="/messages",
    tags=["messages"]
)

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str, db: Session = Depends(get_db)):
    # Güvenlik ve bağlantı çökmesini önlemek için önce kabul et, sonra kontrol et
    await websocket.accept()
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
    except JWTError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    user = user_crud.get_user_by_email(db, email=email)
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # Kuleye Kaydet
    manager.active_connections[str(user.id)] = websocket
    print(f"🟢 WS Bağlandı: {user.name} (Aktif Cihazlar: {len(manager.active_connections)})")

    try:
        while True:
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(str(user.id))

async def handle_hybrid_delivery(
    receiver_id: str, 
    message_data: dict, 
    push_token: str, 
    push_enabled: bool, 
    push_title: str, 
    push_body: str, 
    push_data: dict
):
    is_online = await manager.send_personal_message(message_data, receiver_id)
    
    if not is_online:
        if push_enabled and push_token:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, send_expo_push_notification, push_token, push_title, push_body, push_data)
        else:
            print(f"⚠️ Alıcı offline ve push kapalı/token yok. Mesaj sadece DB'ye yazıldı.")

@router.post("/", response_model=schemas.Message, status_code=status.HTTP_201_CREATED)
def send_new_message(
    message: schemas.MessageCreate,
    background_tasks: BackgroundTasks, 
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    if message.receiver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot send message to yourself")

    new_message = message_crud.create_message(db=db, message=message, sender_id=current_user.id)
    receiver = user_crud.get_user(db, user_id=str(message.receiver_id))
    
    if receiver:
        # 🚀 FORMAT DÜZELTMESİ (Saçmalık 2 Çözüldü): Veritabanı objesini Pydantic şemasına çeviriyoruz!
        message_schema = schemas.Message.model_validate(new_message)
        message_dict = jsonable_encoder(message_schema)
        
        preview_text = message.content[:50] + ("..." if len(message.content) > 50 else "")
        push_title = f"{current_user.name} sana mesaj gönderdi"
        push_data = {"type": "message", "related_entity_id": str(current_user.id)} 
        
        background_tasks.add_task(
            handle_hybrid_delivery,
            receiver_id=str(receiver.id),
            message_data=message_dict,
            push_token=receiver.expo_push_token,
            push_enabled=receiver.push_enabled,
            push_title=push_title,
            push_body=preview_text,
            push_data=push_data
        )

    return new_message

@router.get("/{other_user_id}", response_model=List[schemas.Message])
def get_message_history(
    other_user_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    return message_crud.get_conversation(db, user1_id=current_user.id, user2_id=other_user_id)

@router.get("/conversations/me", response_model=List[schemas.Message])
def get_my_conversations(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    return message_crud.get_conversations(db, user_id=current_user.id)

@router.post("/read/{other_user_id}", status_code=status.HTTP_204_NO_CONTENT)
def mark_conversation_as_read(
    other_user_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    message_crud.mark_messages_as_read(db, sender_id=other_user_id, receiver_id=current_user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.delete("/bulk-delete", status_code=status.HTTP_204_NO_CONTENT)
def delete_multiple_conversations(
    other_user_ids: List[UUID],
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    for other_id in other_user_ids:
        message_crud.soft_delete_conversation(db, user_id=current_user.id, other_user_id=other_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_message_for_user(
    message_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    db_message = db.query(models.Message).get(str(message_id))
    if not db_message:
        raise HTTPException(status_code=404, detail="Message not found")
    if db_message.sender_id != current_user.id and db_message.receiver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this message")
    message_crud.soft_delete_message(db, message=db_message, user_id=current_user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.delete("/conversation/{other_user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_conversation_for_user(
    other_user_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    success = message_crud.soft_delete_conversation(db, user_id=current_user.id, other_user_id=other_user_id)
    if not success:
        raise HTTPException(status_code=500, detail="Could not delete conversation")
    return Response(status_code=status.HTTP_204_NO_CONTENT)