import 'dart:async';
import 'dart:convert'; // AJOUTÉ ICI
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket _socket;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messageQueue = [];
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Future<void> connect(String sessionId, String userId) async {
    try {
      _socket = io.io(
        'http://192.168.1.38:8000',
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
      );

      _socket.onConnect((_) {
        _isConnected = true;
        print('Connected to session $sessionId');
        
        // Envoyer les messages en attente
        for (final message in _messageQueue) {
          _socket.emit('join_session', message);
        }
        _messageQueue.clear();

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

      // Gérer les messages entrants
      _socket.on('message', (data) {
        _handleIncomingMessage(data);
      });

      _socket.on('vote_update', (data) {
        _handleIncomingMessage(data);
      });

      _socket.on('track_change', (data) {
        _handleIncomingMessage(data);
      });

      _socket.on('user_joined', (data) {
        _handleIncomingMessage(data);
      });

      _socket.on('user_left', (data) {
        _handleIncomingMessage(data);
      });

      _socket.on('session_closed', (data) {
        _handleIncomingMessage(data);
      });

      _socket.connect();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void _handleIncomingMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else if (data is String) {
        final message = json.decode(data) as Map<String, dynamic>;
        _messageController.add(message);
      }
    } catch (e) {
      print('Error handling message: $e, data: $data');
    }
  }

  void sendVote(String trackId, String voteType) {
    final message = {
      'type': 'vote',
      'track_id': trackId,
      'vote_type': voteType,
    };
    
    if (_isConnected) {
      _socket.emit('vote', message);
    } else {
      _messageQueue.add(message);
    }
  }

  void notifyTrackChange(Map<String, dynamic> track) {
    final message = {
      'type': 'track_change',
      'track': track,
    };
    
    if (_isConnected) {
      _socket.emit('track_change', message);
    } else {
      _messageQueue.add(message);
    }
  }

  void sendChatMessage(String messageText) {
    final message = {
      'type': 'chat_message',
      'message': messageText,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_isConnected) {
      _socket.emit('chat_message', message);
    } else {
      _messageQueue.add(message);
    }
  }

  Future<void> disconnect() async {
    _socket.disconnect();
    _isConnected = false;
    _messageQueue.clear();
    await _messageController.close();
  }
}