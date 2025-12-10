from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import secrets

router = APIRouter()

# In-memory invite store for demo; replace with DB table in production.
INVITES = {}

class InviteCreate(BaseModel):
    created_by: str
    purpose: str = "add_contact"   # e.g., add_contact | start_chat
    scope: Optional[list] = []     # permissions this invite grants
    uses: int = 1                  # how many times it can be consumed
    expires_in_minutes: int = 60   # TTL

class InviteOut(BaseModel):
    link: str
    created_by: str
    purpose: str
    scope: list
    uses: int
    expires_at: str

@router.post("/create", response_model=InviteOut)
async def create_invite(payload: InviteCreate):
    token = secrets.token_urlsafe(16)
    link = f"polie://invite/{token}"
    expires_at = datetime.utcnow() + timedelta(minutes=payload.expires_in_minutes)
    INVITES[token] = {
        "created_by": payload.created_by,
        "purpose": payload.purpose,
        "scope": payload.scope,
        "uses_remaining": payload.uses,
        "expires_at": expires_at.isoformat()
    }
    return InviteOut(link=link, created_by=payload.created_by, purpose=payload.purpose, scope=payload.scope, uses=payload.uses, expires_at=expires_at.isoformat())

@router.post("/consume/{token}")
async def consume_invite(token: str, consumer_id: str):
    entry = INVITES.get(token)
    if not entry:
        raise HTTPException(status_code=404, detail="Invite not found")
    if entry["uses_remaining"] <= 0:
        raise HTTPException(status_code=410, detail="Invite exhausted")
    if datetime.fromisoformat(entry["expires_at"]) < datetime.utcnow():
        raise HTTPException(status_code=410, detail="Invite expired")
    # decrement
    entry["uses_remaining"] -= 1
    # In production: create contact relation / create chat / track audit
    return {"ok": True, "created_by": entry["created_by"], "consumer": consumer_id, "purpose": entry["purpose"], "scope": entry["scope"], "uses_remaining": entry["uses_remaining"]}

@router.get("/list")
async def list_invites():
    # admin debug endpoint
    return INVITES

