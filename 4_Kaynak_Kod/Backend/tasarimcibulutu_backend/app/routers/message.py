# app/routers/message.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app import schemas
from app.crud import message as message_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from fastapi import Response 
from app import models

router = APIRouter(
    prefix="/messages",
    tags=["messages"]
)

@router.post("/", response_model=schemas.Message, status_code=status.HTTP_201_CREATED)
def send_new_message(
    message: schemas.MessageCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Sends a new message from the current user to a receiver.
    """
    # Kullanıcı kendine mesaj atamaz
    if message.receiver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot send message to yourself")

    # sender_id olarak token'dan gelen güvenli ID'yi kullan
    return message_crud.create_message(db=db, message=message, sender_id=current_user.id)

@router.get("/{other_user_id}", response_model=List[schemas.Message])
def get_message_history(
    other_user_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Retrieves the chat history between the current user and another user.
    """
    return message_crud.get_conversation(db, user1_id=current_user.id, user2_id=other_user_id)

# --- YENİ ENDPOINT ---
@router.get("/conversations/me", response_model=List[schemas.Message])
def get_my_conversations(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Retrieves a list of all conversations for the current user,
    showing only the last message for each conversation.
    """
    return message_crud.get_conversations(db, user_id=current_user.id)

@router.post("/read/{other_user_id}", status_code=status.HTTP_204_NO_CONTENT)
def mark_conversation_as_read(
    other_user_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """Marks all messages from other_user to current_user as read."""
    message_crud.mark_messages_as_read(
        db, sender_id=other_user_id, receiver_id=current_user.id
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_message_for_user(
    message_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """Deletes a message only for the current user (soft delete)."""
    db_message = db.query(models.Message).get(str(message_id))
    if not db_message:
        raise HTTPException(status_code=404, detail="Message not found")

    # Kullanıcı sadece kendi gönderdiği veya aldığı mesajı silebilir
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
    success = message_crud.soft_delete_conversation(
        db, user_id=current_user.id, other_user_id=other_user_id
    )
    if not success:
        raise HTTPException(status_code=500, detail="Could not delete conversation")
    
    return Response(status_code=status.HTTP_204_NO_CONTENT)