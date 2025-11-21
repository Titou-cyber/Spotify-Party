# app/services/spotify_service.py
import spotipy
from spotipy.oauth2 import SpotifyOAuth
from app.core.config import settings
import os

class SpotifyService:
    def __init__(self):
        self.scope = "user-read-private user-read-email playlist-read-private user-modify-playback-state user-read-playback-state"
    
    def _create_oauth_manager(self):
        """Créer le manager OAuth Spotify avec la configuration actuelle"""
        return SpotifyOAuth(
            client_id=settings.SPOTIFY_CLIENT_ID,
            client_secret=settings.SPOTIFY_CLIENT_SECRET,
            redirect_uri=settings.SPOTIFY_REDIRECT_URI,  # ← UTILISE LA CONFIG
            scope=self.scope,
            cache_path=None
        )
    
    def get_auth_url(self):
        """Générer l'URL d'authentification Spotify"""
        try:
            sp_oauth = self._create_oauth_manager()
            auth_url = sp_oauth.get_authorize_url()
            return auth_url
        except Exception as e:
            print(f"Error generating auth URL: {e}")
            raise
    
    def get_access_token(self, code):
        """Échanger le code contre un token d'accès"""
        try:
            sp_oauth = self._create_oauth_manager()
            token_info = sp_oauth.get_access_token(code)
            return token_info
        except Exception as e:
            print(f"Error getting access token: {e}")
            return None
    
    def get_user_profile(self, access_token):
        """Obtenir le profil utilisateur Spotify"""
        try:
            sp = spotipy.Spotify(auth=access_token)
            user_profile = sp.current_user()
            return user_profile
        except Exception as e:
            print(f"Error getting user profile: {e}")
            return None

# Instance globale
spotify_service = SpotifyService()