from pydantic import BaseModel
from typing import Optional, List

class MessageCreate(BaseModel):
    sender: str
    body: str
    lang: Optional[str] = None

class MessageOut(BaseModel):
    id: str
    sender: str
    body: str
    lang: Optional[str] = None
    meta: dict = {}

class InviteCreate(BaseModel):
    created_by: str
    purpose: str
    scope: List[str] = []
    uses: int = 1

class InviteOut(BaseModel):
    link: str
    created_by: str
    scope: List[str]
    uses: int
