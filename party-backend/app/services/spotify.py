# app/services/spotify.py
import requests

def get_current_user(access_token: str) -> dict:
    """
    Appelle l'endpoint /me de Spotify pour récupérer le profil de l'utilisateur
    """
    headers = {
        "Authorization": f"Bearer {access_token}"
    }

    response = requests.get("https://api.spotify.com/v1/me", headers=headers)

    # Si token invalide / expiré, on renvoie l'erreur brute pour l'instant
    if response.status_code != 200:
        return {
            "error": "spotify_api_error",
            "status_code": response.status_code,
            "details": response.json(),
        }

    return response.json()
