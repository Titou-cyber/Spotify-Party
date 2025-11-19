from fastapi import FastAPI
from sqlmodel import SQLModel

from app.db.session import engine
from app.api.routes.auth import router as auth_router
from app.api.routes.rooms import router as rooms_router


app = FastAPI(
    title="Spotify Party Backend",
    version="0.1.0",
)


@app.on_event("startup")
def on_startup():
    # Création des tables si elles n'existent pas (users, rooms, ...)
    SQLModel.metadata.create_all(bind=engine)


@app.get("/")
def root():
    return {"message": "Backend Party - ça tourne 🎉"}


# Routers
app.include_router(auth_router)
app.include_router(rooms_router)
