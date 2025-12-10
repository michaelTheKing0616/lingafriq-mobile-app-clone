from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict
from backend.moderation.automod import score_text

router = APIRouter()

# In-memory queue for demo
MOD_QUEUE = []

class ModCheckRequest(BaseModel):
    message_id: str
    text: str
    sender: str
    lang: str = "en"

class ModDecision(BaseModel):
    message_id: str
    action: str  # allow | block | remove | approve

@router.post("/check")
async def check_message(req: ModCheckRequest):
    result = score_text(req.text)
    entry = {"message_id": req.message_id, "text": req.text, "sender": req.sender, "score": result["score"], "action": result["action"], "reasons": result["reasons"]}
    if result["action"] != "allow":
        MOD_QUEUE.append(entry)
    return {"result": result, "queued": result["action"] != "allow"}

@router.get("/queue")
async def get_queue():
    return {"count": len(MOD_QUEUE), "items": MOD_QUEUE}

@router.post("/decide")
async def decide(dec: ModDecision):
    # apply moderator's action: in production, update DB & remove/notify
    for i, e in enumerate(MOD_QUEUE):
        if e["message_id"] == dec.message_id:
            MOD_QUEUE.pop(i)
            return {"ok": True, "applied": dec.action}
    raise HTTPException(status_code=404, detail="message not found")

