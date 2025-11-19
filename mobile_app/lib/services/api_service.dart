import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/session.dart';
import '../models/track.dart';
import '../models/vote.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = AppConstants.apiUrl;
  String? _accessToken;
  String? _userId; // 🆕 Stocker l'userId

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.keyAccessToken);
    _userId = prefs.getString(AppConstants.keyUserId);
    print('🔑 Token chargé: ${_accessToken != null ? "✅" : "❌"}');
  }

  Future<void> saveToken(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, token);
    await prefs.setString(AppConstants.keyUserId, userId);
    _accessToken = token;
    _userId = userId;
    print('💾 Token sauvegardé');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyUserId);
    _accessToken = null;
    _userId = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // 🆕 Gérer les erreurs 401 (token expiré)
  Future<http.Response> _handleRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      
      // Si token expiré, demander à l'utilisateur de se reconnecter
      if (response.statusCode == 401) {
        print('❌ Token expiré - Reconnexion nécessaire');
        await clearToken();
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // AUTH ENDPOINTS

  Future<Map<String, dynamic>> getAuthUrl() async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.login}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get auth URL');
    }
  }

  Future<Map<String, dynamic>> handleCallback(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.callback}?code=$code'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 🆕 Sauvegarder le token ET l'userId
      await saveToken(
        data['access_token'],
        data['user']['id'],
      );
      return data;
    } else {
      throw Exception('Authentication failed');
    }
  }

  Future<User> getCurrentUser(String userId) async {
    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.me}?user_id=$userId'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user');
    }
  }

  // SESSION ENDPOINTS

  Future<Session> createSession({
    required List<String> playlistIds,
    String? name,
    int votesRequired = 5,
  }) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.post(
      Uri.parse('$baseUrl${ApiEndpoints.createSession}'),
      headers: _headers,
      body: json.encode({
        'playlist_ids': playlistIds,
        if (name != null) 'name': name,
        'votes_required': votesRequired,
      }),
    ));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create session: ${response.body}');
    }
  }

  Future<Session> joinSession(String code) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.post(
      Uri.parse('$baseUrl${ApiEndpoints.joinSession}'),
      headers: _headers,
      body: json.encode({'code': code.toUpperCase()}),
    ));

    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to join session');
    }
  }

  Future<Session> getSession(String sessionId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.getSession(sessionId)}'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get session');
    }
  }

  Future<void> leaveSession(String sessionId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.post(
      Uri.parse('$baseUrl${ApiEndpoints.leaveSession(sessionId)}'),
      headers: _headers,
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to leave session');
    }
  }

  Future<void> closeSession(String sessionId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.post(
      Uri.parse('$baseUrl${ApiEndpoints.closeSession(sessionId)}'),
      headers: _headers,
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to close session');
    }
  }

  Future<void> updateVotesRequired(String sessionId, int votesRequired) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.patch(
      Uri.parse('$baseUrl/api/sessions/$sessionId/votes-required?votes_required=$votesRequired'),
      headers: _headers,
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to update votes required');
    }
  }

  // VOTE ENDPOINTS

  Future<Vote> submitVote(String sessionId, String trackId, VoteType voteType) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.post(
      Uri.parse('$baseUrl${ApiEndpoints.vote(sessionId)}'),
      headers: _headers,
      body: json.encode({
        'track_id': trackId,
        'vote_type': voteType == VoteType.like ? 'like' : 'dislike',
      }),
    ));

    if (response.statusCode == 200) {
      return Vote.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit vote');
    }
  }

  Future<VoteResults> getTrackResults(String sessionId, String trackId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.trackResults(sessionId, trackId)}'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      return VoteResults.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get results');
    }
  }

  Future<Map<String, VoteResults>> getAllResults(String sessionId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.allResults(sessionId)}'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.map(
        (key, value) => MapEntry(key, VoteResults.fromJson(value)),
      );
    } else {
      throw Exception('Failed to get results');
    }
  }

  // SPOTIFY ENDPOINTS

  Future<List<dynamic>> getUserPlaylists() async {
    if (_accessToken == null) {
      print('⚠️ Token null, chargement...');
      await loadToken();
    }

    print('📋 Requête playlists avec token: ${_accessToken?.substring(0, 10)}...');

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.playlists}'),
      headers: _headers,
    ));

    print('📡 Réponse: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ ${data['playlists'].length} playlists récupérées');
      return data['playlists'];
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to get playlists: ${response.body}');
    }
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.playlistTracks(playlistId)}'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['tracks'] as List)
          .map((track) => Track.fromJson(track))
          .toList();
    } else {
      throw Exception('Failed to get tracks');
    }
  }

  Future<Track> getTrack(String trackId) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.track(trackId)}'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      return Track.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get track');
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    if (_accessToken == null) {
      await loadToken();
    }

    final response = await _handleRequest(() => http.get(
      Uri.parse('$baseUrl${ApiEndpoints.search}?query=$query'),
      headers: _headers,
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['tracks'] as List)
          .map((track) => Track.fromJson(track))
          .toList();
    } else {
      throw Exception('Search failed');
    }
  }
}