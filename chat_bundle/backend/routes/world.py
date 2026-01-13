from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
router = APIRouter()
POSTS = []

class PostCreate(BaseModel):
    author: str
    body: str
    lang: Optional[str] = None
    country: Optional[str] = None
    level: Optional[str] = None

@router.post("/post")
async def create_post(p: PostCreate):
    item = {"id": "post_" + str(len(POSTS)+1), "author": p.author, "body": p.body, "lang": p.lang, "country": p.country, "level": p.level, "created_at": datetime.utcnow().isoformat()}
    POSTS.append(item)
    return item

@router.get("/feed")
async def feed(country: Optional[str] = None, lang: Optional[str] = None, level: Optional[str] = None):
    results = POSTS
    if country: results = [r for r in results if r.get("country")==country]
    if lang: results = [r for r in results if r.get("lang")==lang]
    if level: results = [r for r in results if r.get("level")==level]
    return {"count": len(results), "items": results[-50:]}
