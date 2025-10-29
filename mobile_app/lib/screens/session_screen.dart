import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import '../models/track.dart';
import '../models/vote.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/spotify_service.dart';
import '../widgets/track_card.dart';
import '../widgets/now_playing.dart';
import '../utils/constants.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final SpotifyService _spotifyService = SpotifyService();

  Session? _session;
  String? _userId;
  List<Track> _tracks = [];
  Track? _currentTrack;
  Map<String, VoteResults> _voteResults = {};
  bool _isLoading = true;
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final session = ModalRoute.of(context)!.settings.arguments as Session;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.keyUserId);

    setState(() {
      _session = session;
      _userId = userId;
      _isHost = session.hostId == userId;
    });

    await _socketService.connect(session.id, userId!);
    _socketService.messages.listen(_handleWebSocketMessage);

    await _loadTracks();

    if (_isHost) {
      await _spotifyService.connectToSpotify();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadTracks() async {
    if (_session == null) return;

    List<Track> allTracks = [];
    
    for (String playlistId in _session!.playlistIds) {
      try {
        final tracks = await _apiService.getPlaylistTracks(playlistId);
        allTracks.addAll(tracks);
      } catch (e) {
        print('Error loading playlist $playlistId: $e');
      }
    }

    setState(() {
      _tracks = allTracks;
    });

    await _loadVoteResults();
  }

  Future<void> _loadVoteResults() async {
    if (_session == null) return;

    try {
      final results = await _apiService.getAllResults(_session!.id);
      setState(() {
        _voteResults = results;
      });
    } catch (e) {
      print('Error loading vote results: $e');
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'];

    switch (type) {
      case 'vote_update':
        _loadVoteResults();
        break;
      
      case 'track_change':
        setState(() {
          _currentTrack = Track.fromJson(message['track']);
        });
        break;
      
      case 'user_joined':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message['user_id']} a rejoint la session'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      
      case 'user_left':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message['user_id']} a quitté la session'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      
      case 'session_closed':
        Navigator.pop(context);
        break;
    }
  }

  Future<void> _vote(Track track, VoteType voteType) async {
    try {
      await _apiService.submitVote(_session!.id, track.id, voteType);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            voteType == VoteType.like ? 'Vote pour ${track.name}' : 'Vote contre ${track.name}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de vote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _playTrack(Track track) async {
    if (!_isHost) return;

    try {
      await _spotifyService.play(track.uri);
      _socketService.notifyTrackChange(track.toJson());
      
      setState(() {
        _currentTrack = track;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de lecture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copySessionCode() {
    Clipboard.setData(ClipboardData(text: _session!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papier'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _leaveSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la session'),
        content: Text(_isHost 
          ? 'Vous êtes l\'hôte. Quitter fermera la session pour tous.'
          : 'Êtes-vous sûr de vouloir quitter ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (_isHost) {
          await _apiService.closeSession(_session!.id);
        } else {
          await _apiService.leaveSession(_session!.id);
        }
        
        await _socketService.disconnect();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isHost ? 'Session (Hôte)' : 'Session'),
        backgroundColor: const Color(0xFF191414),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _leaveSession,
            tooltip: 'Quitter',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF282828),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Code: ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _session!.code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF1DB954),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: _copySessionCode,
                ),
              ],
            ),
          ),

          if (_currentTrack != null)
            NowPlayingWidget(track: _currentTrack!),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${_session!.participants.length} participant(s)',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _tracks.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final results = _voteResults[track.id];

                return TrackCard(
                  track: track,
                  voteResults: results,
                  onVote: (voteType) => _vote(track, voteType),
                  onPlay: _isHost ? () => _playTrack(track) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}