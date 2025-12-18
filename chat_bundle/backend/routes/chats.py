from fastapi import APIRouter, HTTPException
from backend.models import MessageCreate, MessageOut, InviteCreate, InviteOut
from src.enforce_diacritics import enforce_diacritics
from backend.moderation.automod import score_text
import uuid

router = APIRouter()

CHATS = {}
INVITES = {}

@router.post("/create")
async def create_chat(user_ids: list):
    chat_id = "chat_" + "_".join(user_ids)
    CHATS.setdefault(chat_id, [])
    return {"chat_id": chat_id, "members": user_ids}

@router.post("/{chat_id}/send", response_model=MessageOut)
async def send_message(chat_id: str, payload: MessageCreate):
    if chat_id not in CHATS:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Moderation check before processing
    message_id = f"m_{len(CHATS[chat_id])+1}_{uuid.uuid4().hex[:8]}"
    mod_result = score_text(payload.body)
    
    if mod_result["action"] == "block":
        raise HTTPException(status_code=403, detail="Message blocked by moderation")
    
    # Apply diacritics correction
    corrected, changed, meta = (payload.body, False, {})
    if payload.lang:
        corrected, changed, meta = enforce_diacritics(payload.body, payload.lang)
    
    # Build message with moderation metadata
    message_meta = {"diacritics_applied": changed}
    if mod_result["action"] == "hold_for_review":
        message_meta["pending_moderation"] = True
        message_meta["moderation_score"] = mod_result["score"]
        message_meta["moderation_reasons"] = mod_result["reasons"]
    
    message = {
        "id": message_id,
        "sender": payload.sender,
        "body": corrected or payload.body,
        "lang": payload.lang,
        "meta": message_meta
    }
    
    CHATS[chat_id].append(message)
    return message

@router.get("/{chat_id}/messages")
async def get_messages(chat_id: str, limit: int = 50):
    return CHATS.get(chat_id, [])[-limit:]

@router.post("/invite", response_model=InviteOut)
async def create_invite(payload: InviteCreate):
    link = "invite_" + payload.created_by + "_" + payload.purpose
    INVITES[link] = {"created_by": payload.created_by, "scope": payload.scope, "uses": payload.uses}
    return {"link": link, "created_by": payload.created_by, "scope": payload.scope, "uses": payload.uses}
