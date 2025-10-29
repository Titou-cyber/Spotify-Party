class Session {
  final String id;
  final String code;
  final String hostId;
  final String name;
  final List<String> playlistIds;
  final List<String> participants;
  final Map<String, dynamic>? currentTrack;
  final List<Map<String, dynamic>> trackQueue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.code,
    required this.hostId,
    required this.name,
    required this.playlistIds,
    required this.participants,
    this.currentTrack,
    required this.trackQueue,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      code: json['code'],
      hostId: json['host_id'],
      name: json['name'],
      playlistIds: List<String>.from(json['playlist_ids']),
      participants: List<String>.from(json['participants']),
      currentTrack: json['current_track'],
      trackQueue: List<Map<String, dynamic>>.from(json['track_queue']),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'host_id': hostId,
      'name': name,
      'playlist_ids': playlistIds,
      'participants': participants,
      'current_track': currentTrack,
      'track_queue': trackQueue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}