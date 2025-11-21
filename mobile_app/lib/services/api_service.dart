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

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.keyAccessToken);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, token);
    _accessToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // AUTH ENDPOINTS

  Future<Map<String, dynamic>> getAuthUrl() async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.login}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get auth URL: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> handleCallback(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.callback}?code=$code'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      throw Exception('Authentication failed: ${response.statusCode}');
    }
  }

  Future<User> getCurrentUser(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.me}?user_id=$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user: ${response.statusCode}');
    }
  }

  // SESSION ENDPOINTS

  Future<Session> createSession(List<String> playlistIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiEndpoints.createSession}'),
      headers: _headers,
      body: json.encode({'playlist_ids': playlistIds}),
    );

    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create session: ${response.statusCode}');
    }
  }

  Future<Session> joinSession(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiEndpoints.joinSession}'),
      headers: _headers,
      body: json.encode({'code': code}),
    );

    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to join session: ${response.statusCode}');
    }
  }

  Future<Session> getSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.getSession(sessionId)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get session: ${response.statusCode}');
    }
  }

  Future<void> leaveSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiEndpoints.leaveSession(sessionId)}'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave session: ${response.statusCode}');
    }
  }

  Future<void> closeSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiEndpoints.closeSession(sessionId)}'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to close session: ${response.statusCode}');
    }
  }

  // VOTE ENDPOINTS

  Future<Vote> submitVote(String sessionId, String trackId, VoteType voteType) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiEndpoints.vote(sessionId)}'),
      headers: _headers,
      body: json.encode({
        'track_id': trackId,
        'vote_type': voteType == VoteType.like ? 'like' : 'dislike',
      }),
    );

    if (response.statusCode == 200) {
      return Vote.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit vote: ${response.statusCode}');
    }
  }

  Future<VoteResults> getTrackResults(String sessionId, String trackId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.trackResults(sessionId, trackId)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return VoteResults.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get results: ${response.statusCode}');
    }
  }

  Future<Map<String, VoteResults>> getAllResults(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.allResults(sessionId)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.map(
        (key, value) => MapEntry(key, VoteResults.fromJson(value)),
      );
    } else {
      throw Exception('Failed to get results: ${response.statusCode}');
    }
  }

  // SPOTIFY ENDPOINTS

  Future<List<dynamic>> getUserPlaylists() async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.playlists}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['playlists'];
    } else {
      throw Exception('Failed to get playlists: ${response.statusCode}');
    }
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.playlistTracks(playlistId)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['tracks'] as List)
          .map((track) => Track.fromJson(track))
          .toList();
    } else {
      throw Exception('Failed to get tracks: ${response.statusCode}');
    }
  }

  Future<Track> getTrack(String trackId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.track(trackId)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Track.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get track: ${response.statusCode}');
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiEndpoints.search}?query=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['tracks'] as List)
          .map((track) => Track.fromJson(track))
          .toList();
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }
}