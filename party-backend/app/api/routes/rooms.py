# app/api/routes/rooms.py
import random
import string
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.db.session import get_session
from app.models.room import Room
from app.models.user import SpotifyUser
from app.models.room_participant import RoomParticipant

from app.models.room_participant import RoomParticipant
from app.models.vote import Vote

from app.services.spotify import pick_random_track_from_user
from app.models.vote import Vote  # si pas déjà importé


router = APIRouter(
    prefix="/rooms",
    tags=["rooms"],
)


def generate_room_code(length: int = 6) -> str:
    """
    Génère un code de room simple, ex: 'A3F9ZQ'
    """
    chars = string.ascii_uppercase + string.digits
    return "".join(random.choice(chars) for _ in range(length))


@router.post("/", response_model=Room)
def create_room(
    host_spotify_id: str,
    like_threshold: int = 3,
    session: Session = Depends(get_session),
):
    """
    Crée une nouvelle room.
    """

    # 1) Trouver l'hôte dans spotify_users
    statement = select(SpotifyUser).where(SpotifyUser.spotify_id == host_spotify_id)
    host = session.exec(statement).first()

    if not host:
        raise HTTPException(status_code=404, detail="Hôte (SpotifyUser) introuvable")

    # 2) Générer un code unique
    code = generate_room_code()
    while session.exec(select(Room).where(Room.code == code)).first():
        code = generate_room_code()

    # 3) Créer la room
    room = Room(
        code=code,
        host_user_id=host.id,
        like_threshold=like_threshold,
        is_active=True,
    )

    session.add(room)
    session.commit()
    session.refresh(room)

    # 4) Ajouter l'hôte comme participant aussi
    participant = RoomParticipant(
        room_id=room.id,
        user_id=host.id,
    )
    session.add(participant)
    session.commit()

    return room


@router.get("/", response_model=List[Room])
def list_rooms(
    session: Session = Depends(get_session),
):
    rooms = session.exec(select(Room)).all()
    return rooms


@router.get("/{code}", response_model=Room)
def get_room_by_code(
    code: str,
    session: Session = Depends(get_session),
):
    statement = select(Room).where(Room.code == code)
    room = session.exec(statement).first()

    if not room:
        raise HTTPException(status_code=404, detail="Room introuvable")

    return room


@router.post("/{code}/join")
def join_room(
    code: str,
    spotify_id: str,
    session: Session = Depends(get_session),
):
    """
    Un utilisateur (via son spotify_id) rejoint une room.
    """

    # 1) Récupérer la room
    statement_room = select(Room).where(Room.code == code)
    room = session.exec(statement_room).first()

    if not room:
        raise HTTPException(status_code=404, detail="Room introuvable")

    # 2) Récupérer l'utilisateur
    statement_user = select(SpotifyUser).where(SpotifyUser.spotify_id == spotify_id)
    user = session.exec(statement_user).first()

    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur Spotify introuvable")

    # 3) Vérifier s'il est déjà participant
    statement_participant = select(RoomParticipant).where(
        RoomParticipant.room_id == room.id,
        RoomParticipant.user_id == user.id,
    )
    existing = session.exec(statement_participant).first()

    if existing:
        return {
            "status": "already_in_room",
            "room_code": room.code,
            "user_id": user.id,
        }

    # 4) Ajouter comme participant
    participant = RoomParticipant(
        room_id=room.id,
        user_id=user.id,
    )
    session.add(participant)
    session.commit()
    session.refresh(participant)

    return {
        "status": "joined",
        "room_code": room.code,
        "user_id": user.id,
    }


@router.get("/{code}/participants")
def list_participants(
    code: str,
    session: Session = Depends(get_session),
):
    """
    Liste les participants d'une room (pour debug / dev)
    """
    # Room
    statement_room = select(Room).where(Room.code == code)
    room = session.exec(statement_room).first()

    if not room:
        raise HTTPException(status_code=404, detail="Room introuvable")

    # Participants
    statement_participants = select(RoomParticipant).where(
        RoomParticipant.room_id == room.id
    )
    participants = session.exec(statement_participants).all()

    # On récupère aussi les infos SpotifyUser pour chaque user
    users_data = []
    for p in participants:
        user_stmt = select(SpotifyUser).where(SpotifyUser.id == p.user_id)
        u = session.exec(user_stmt).first()
        if u:
            users_data.append(
                {
                    "user_id": u.id,
                    "spotify_id": u.spotify_id,
                    "display_name": u.display_name,
                    "email": u.email,
                    "joined_at": p.joined_at,
                }
            )

    return {
        "room_code": room.code,
        "participants": users_data,
    }

from typing import Optional
from fastapi import Query
from sqlmodel import func


@router.post("/{code}/vote")
def vote_on_track(
    code: str,
    spotify_id: str = Query(...),
    track_uri: str = Query(...),
    is_like: bool = Query(True),
    session: Session = Depends(get_session),
):
    """
    Un utilisateur vote pour/contre une musique dans une room.

    Params (query) :
    - spotify_id : id Spotify du joueur
    - track_uri  : uri de la musique (spotify:track:...)
    - is_like    : true = j'aime, false = j'aime pas
    """

    # 1) Room
    room_stmt = select(Room).where(Room.code == code)
    room = session.exec(room_stmt).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room introuvable")

    # 2) User
    user_stmt = select(SpotifyUser).where(SpotifyUser.spotify_id == spotify_id)
    user = session.exec(user_stmt).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur Spotify introuvable")

    # (Optionnel) vérifier que l'user est bien participant de la room
    participant_stmt = select(RoomParticipant).where(
        RoomParticipant.room_id == room.id,
        RoomParticipant.user_id == user.id,
    )
    participant = session.exec(participant_stmt).first()
    if not participant:
        raise HTTPException(status_code=403, detail="Utilisateur non participant de la room")

    # 3) Enregistrer le vote
    vote = Vote(
        room_id=room.id,
        user_id=user.id,
        track_uri=track_uri,
        is_like=is_like,
    )
    session.add(vote)
    session.commit()

    # 4) Compter les likes pour cette musique dans cette room
    likes_stmt = (
        select(func.count(Vote.id))
        .where(
            Vote.room_id == room.id,
            Vote.track_uri == track_uri,
            Vote.is_like == True,
        )
    )
    likes_count = session.exec(likes_stmt).one()

    # 5) Décider si on lance la musique
    should_play = likes_count >= room.like_threshold

    return {
        "status": "vote_registered",
        "room_code": room.code,
        "track_uri": track_uri,
        "likes": likes_count,
        "like_threshold": room.like_threshold,
        "play": should_play,
    }

@router.get("/{code}/random-track")
def get_random_track_for_room(
    code: str,
    session: Session = Depends(get_session),
):
    """
    Choisit un joueur aléatoire dans la room,
    puis une musique aléatoire dans ses playlists.
    """

    # 1) Récupérer la room
    room_stmt = select(Room).where(Room.code == code)
    room = session.exec(room_stmt).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room introuvable")

    # 2) Récupérer les participants
    participants_stmt = select(RoomParticipant).where(
        RoomParticipant.room_id == room.id
    )
    participants = session.exec(participants_stmt).all()
    if not participants:
        raise HTTPException(status_code=400, detail="Aucun participant dans la room")

    # 3) Choisir un participant au hasard
    random_participant = random.choice(participants)

    # 4) Récupérer le SpotifyUser correspondant
    user_stmt = select(SpotifyUser).where(SpotifyUser.id == random_participant.user_id)
    user = session.exec(user_stmt).first()
    if not user:
        raise HTTPException(status_code=500, detail="Participant lié à aucun SpotifyUser")

    access_token = user.access_token
    if not access_token:
        raise HTTPException(status_code=500, detail="Pas de token Spotify pour cet utilisateur")

    # 5) Choisir une musique aléatoire dans ses playlists
    track_info = pick_random_track_from_user(access_token)

    if "error" in track_info:
        return {
            "status": "error",
            "room_code": room.code,
            "user": {
                "id": user.id,
                "spotify_id": user.spotify_id,
                "display_name": user.display_name,
            },
            "error": track_info["error"],
        }

    return {
        "status": "ok",
        "room_code": room.code,
        "chosen_user": {
            "id": user.id,
            "spotify_id": user.spotify_id,
            "display_name": user.display_name,
        },
        "track": track_info,
    }
