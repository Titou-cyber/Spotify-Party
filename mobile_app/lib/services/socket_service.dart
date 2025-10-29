import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket _socket;
  bool _isConnected = false;

  Future<void> connect(String sessionId, String userId) async {
    try {
      _socket = io.io(
        'http://localhost:8000',
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
      );

      _socket.onConnect((_) {
        _isConnected = true;
        print('Connected to session $sessionId');
        
        // Rejoindre la room WebSocket
        _socket.emit('join_session', {
          'session_id': sessionId,
          'user_id': userId,
        });
      });

      _socket.onDisconnect((_) {
        _isConnected = false;
        print('Disconnected from session');
      });

      _socket.onError((data) {
        print('WebSocket error: $data');
      });

      _socket.connect();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  Stream<Map<String, dynamic>> get messages {
    return _socket.on('message').map((data) => data as Map<String, dynamic>);
  }

  void sendVote(String trackId, String voteType) {
    if (!_isConnected) return;
    
    _socket.emit('vote', {
      'track_id': trackId,
      'vote_type': voteType,
    });
  }

  void notifyTrackChange(Map<String, dynamic> track) {
    if (!_isConnected) return;
    
    _socket.emit('track_change', {
      'track': track,
    });
  }

  void sendChatMessage(String message) {
    if (!_isConnected) return;
    
    _socket.emit('chat_message', {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    _socket.disconnect();
    _isConnected = false;
  }
}