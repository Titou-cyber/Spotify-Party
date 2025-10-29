import spotipy
from spotipy.oauth2 import SpotifyOAuth
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.user import User
from datetime import datetime, timedelta

class SpotifyService:
    def __init__(self, db: Session):
        self.db = db
    
    def _get_spotify_client(self, user_id: str):
        """Obtenir un client Spotify authentifié pour l'utilisateur"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user or not user.spotify_access_token:
            return None
        
        # Vérifier et rafraîchir le token si nécessaire
        if user.token_expires_at and user.token_expires_at < datetime.utcnow():
            if not self._refresh_user_token(user):
                return None
        
        return spotipy.Spotify(auth=user.spotify_access_token)
    
    def _refresh_user_token(self, user: User):
        """Rafraîchir le token Spotify d'un utilisateur"""
        try:
            sp_oauth = SpotifyOAuth(
                client_id=settings.SPOTIFY_CLIENT_ID,
                client_secret=settings.SPOTIFY_CLIENT_SECRET,
                redirect_uri=settings.SPOTIFY_REDIRECT_URI
            )
            
            token_info = sp_oauth.refresh_access_token(user.spotify_refresh_token)
            
            user.spotify_access_token = token_info['access_token']
            user.token_expires_at = datetime.utcnow() + timedelta(seconds=token_info['expires_in'])
            
            if 'refresh_token' in token_info:
                user.spotify_refresh_token = token_info['refresh_token']
            
            self.db.commit()
            return True
            
        except Exception as e:
            print(f"Token refresh failed: {e}")
            return False
    
    def get_auth_url(self):
        """Générer l'URL d'authentification Spotify"""
        sp_oauth = SpotifyOAuth(
            client_id=settings.SPOTIFY_CLIENT_ID,
            client_secret=settings.SPOTIFY_CLIENT_SECRET,
            redirect_uri=settings.SPOTIFY_REDIRECT_URI,
            scope="user-read-private user-read-email playlist-read-private user-modify-playback-state user-read-playback-state"
        )
        return sp_oauth.get_authorize_url()
    
    def get_access_token(self, code: str):
        """Échanger le code d'autorisation contre un token d'accès"""
        sp_oauth = SpotifyOAuth(
            client_id=settings.SPOTIFY_CLIENT_ID,
            client_secret=settings.SPOTIFY_CLIENT_SECRET,
            redirect_uri=settings.SPOTIFY_REDIRECT_URI
        )
        return sp_oauth.get_access_token(code)
    
    def get_user_profile(self, access_token: str):
        """Obtenir le profil utilisateur Spotify"""
        sp = spotipy.Spotify(auth=access_token)
        return sp.current_user()
    
    def get_user_playlists(self, user_id: str, limit: int = 50):
        """Obtenir les playlists de l'utilisateur"""
        sp = self._get_spotify_client(user_id)
        if not sp:
            return None
        
        try:
            playlists = sp.current_user_playlists(limit=limit)
            return [
                {
                    'id': item['id'],
                    'name': item['name'],
                    'description': item.get('description', ''),
                    'image_url': item['images'][0]['url'] if item['images'] else '',
                    'tracks_total': item['tracks']['total']
                }
                for item in playlists['items']
            ]
        except Exception as e:
            print(f"Error getting playlists: {e}")
            return None
    
    def get_playlist_tracks(self, user_id: str, playlist_id: str, limit: int = 100):
        """Obtenir les tracks d'une playlist"""
        sp = self._get_spotify_client(user_id)
        if not sp:
            return None
        
        try:
            tracks = sp.playlist_tracks(playlist_id, limit=limit)
            return [
                {
                    'id': item['track']['id'],
                    'name': item['track']['name'],
                    'artists': [artist['name'] for artist in item['track']['artists']],
                    'artist_names': ', '.join([artist['name'] for artist in item['track']['artists']]),
                    'album': item['track']['album']['name'],
                    'album_image_url': item['track']['album']['images'][0]['url'] if item['track']['album']['images'] else '',
                    'duration_ms': item['track']['duration_ms'],
                    'preview_url': item['track'].get('preview_url'),
                    'uri': item['track']['uri'],
                    'is_playable': item['track'].get('is_playable', True)
                }
                for item in tracks['items']
                if item['track'] and item['track']['id']
            ]
        except Exception as e:
            print(f"Error getting playlist tracks: {e}")
            return None
    
    def get_track(self, user_id: str, track_id: str):
        """Obtenir les détails d'une track"""
        sp = self._get_spotify_client(user_id)
        if not sp:
            return None
        
        try:
            track = sp.track(track_id)
            return {
                'id': track['id'],
                'name': track['name'],
                'artists': [artist['name'] for artist in track['artists']],
                'artist_names': ', '.join([artist['name'] for artist in track['artists']]),
                'album': track['album']['name'],
                'album_image_url': track['album']['images'][0]['url'] if track['album']['images'] else '',
                'duration_ms': track['duration_ms'],
                'preview_url': track.get('preview_url'),
                'uri': track['uri']
            }
        except Exception as e:
            print(f"Error getting track: {e}")
            return None
    
    def search_tracks(self, user_id: str, query: str, limit: int = 20):
        """Rechercher des tracks"""
        sp = self._get_spotify_client(user_id)
        if not sp:
            return None
        
        try:
            results = sp.search(q=query, type='track', limit=limit)
            return [
                {
                    'id': item['id'],
                    'name': item['name'],
                    'artists': [artist['name'] for artist in item['artists']],
                    'artist_names': ', '.join([artist['name'] for artist in item['artists']]),
                    'album': item['album']['name'],
                    'album_image_url': item['album']['images'][0]['url'] if item['album']['images'] else '',
                    'duration_ms': item['duration_ms'],
                    'preview_url': item.get('preview_url'),
                    'uri': item['uri']
                }
                for item in results['tracks']['items']
            ]
        except Exception as e:
            print(f"Search error: {e}")
            return None

# Instance globale pour l'auth
spotify_service = SpotifyService(None)