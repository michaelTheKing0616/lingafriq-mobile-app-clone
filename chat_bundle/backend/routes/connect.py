from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
router = APIRouter()

USERS = [
    {"id":"u1","username":"adunni","native":["yoruba"],"learning":[{"lang":"swahili","level":"A2"}], "timezone":"Africa/Lagos"},
    {"id":"u2","username":"kofi","native":["akan"],"learning":[{"lang":"yoruba","level":"A1"}], "timezone":"Africa/Accra"},
    {"id":"u3","username":"fatou","native":["wolof"],"learning":[{"lang":"swahili","level":"B1"}], "timezone":"Africa/Dakar"}
]

class MatchQuery(BaseModel):
    lang: str
    level: Optional[str] = None
    timezone: Optional[str] = None

@router.post("/match")
async def match_users(q: MatchQuery):
    matches = []
    for u in USERS:
        for L in u.get("learning", []):
            if L.get("lang")==q.lang and (not q.level or L.get("level")==q.level):
                matches.append(u)
    return {"count": len(matches), "matches": matches}

@router.get("/profile/{username}")
async def profile(username: str):
    for u in USERS:
        if u["username"]==username:
            return u
    return {}
