# app/routers/message.py
from fastapi import APIRouter, Depends, HTTPException, status, Response, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from app import schemas, models
from app.crud import message as message_crud, user as user_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel

# 🚀 YENİ İMPORT: Bildirim Motorumuz
from app.utils.push_sender import send_expo_push_notification

router = APIRouter(
    prefix="/messages",
    tags=["messages"]
)

@router.post("/", response_model=schemas.Message, status_code=status.HTTP_201_CREATED)
def send_new_message(
    message: schemas.MessageCreate,
    background_tasks: BackgroundTasks, # 🚀 YENİ: Arka Plan Görev Yöneticisi
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Sends a new message from the current user to a receiver.
    """
    if message.receiver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot send message to yourself")

    new_message = message_crud.create_message(db=db, message=message, sender_id=current_user.id)

    # 🚀 ANLIK BİLDİRİM (PUSH) MOTORU TETİKLENİYOR
    receiver = user_crud.get_user(db, user_id=str(message.receiver_id))
    
    if receiver and receiver.push_enabled and receiver.expo_push_token:
        preview_text = message.content[:50] + ("..." if len(message.content) > 50 else "")
        
        background_tasks.add_task(
            send_expo_push_notification,
            token=receiver.expo_push_token,
            title=f"{current_user.name} sana mesaj gönderdi",
            body=preview_text,
            data={"type": "message", "related_entity_id": str(current_user.id)} 
        )
    else:
        print(f"⚠️ DİKKAT: Bildirim gönderilemedi! Sebebi -> Alıcı Bulundu mu?: {bool(receiver)} | Push Açık mı?: {receiver.push_enabled if receiver else False} | Token Var mı?: {receiver.expo_push_token if receiver else 'YOK (NULL)'}")

    # 🚀 DÜZELTME BURADA: Bu satır İÇERİDE değil, EN DIŞTADIR!
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