class AppConstants {
  // Pour tester sur iPhone via PWA (même domaine que le frontend)
  static const String apiUrl = '';  // Chaîne vide car /api est déjà dans les endpoints
  
  // OU pour continuer à développer sur PC avec Flutter en développement :
  // static const String apiUrl = 'http://172.20.10.4:8000';
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
}

class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String callback = '/api/auth/callback';
  static const String refresh = '/api/auth/refresh';
  static const String me = '/api/auth/me';
  
  // Sessions
  static const String createSession = '/api/sessions/create';
  static const String joinSession = '/api/sessions/join';
  static String getSession(String sessionId) => '/api/sessions/$sessionId';
  static String leaveSession(String sessionId) => '/api/sessions/$sessionId/leave';
  static String closeSession(String sessionId) => '/api/sessions/$sessionId/close';
  
  // Votes
  static String vote(String sessionId) => '/api/votes/$sessionId/vote';
  static String trackResults(String sessionId, String trackId) => '/api/votes/$sessionId/track/$trackId/results';
  static String allResults(String sessionId) => '/api/votes/$sessionId/results';
  
  // Spotify
  static const String playlists = '/api/spotify/playlists';
  static String playlistTracks(String playlistId) => '/api/spotify/playlists/$playlistId/tracks';
  static String track(String trackId) => '/api/spotify/tracks/$trackId';
  static const String search = '/api/spotify/search';
}

class AppColors {
  static const spotifyGreen = 0xFF1DB954;
  static const spotifyBlack = 0xFF191414;
  static const spotifyDarkGray = 0xFF282828;
  static const spotifyLightGray = 0xFFB3B3B3;
}