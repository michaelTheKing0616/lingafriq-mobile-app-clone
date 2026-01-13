from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routes import chats, world, connect, health, invites, moderation

app = FastAPI(title="Polie Chat Router", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/health")
app.include_router(chats.router, prefix="/chats")
app.include_router(world.router, prefix="/world")
app.include_router(connect.router, prefix="/connect")
app.include_router(invites.router, prefix="/invites")
app.include_router(moderation.router, prefix="/moderation")
