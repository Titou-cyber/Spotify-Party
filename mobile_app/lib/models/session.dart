class Session {
  final String id;
  final String code;
  final String hostId;
  final String name;
  final List<String> playlistIds;
  final List<String> participants;
  final Map<String, dynamic>? currentTrack;
  final List<Map<String, dynamic>> trackQueue;
  final int votesRequired; // 🆕 Nombre de votes requis
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
    required this.votesRequired,
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
      playlistIds: List<String>.from(json['playlist_ids'] ?? []),
      participants: List<String>.from(json['participants'] ?? []),
      currentTrack: json['current_track'],
      trackQueue: json['track_queue'] != null 
          ? List<Map<String, dynamic>>.from(json['track_queue']) 
          : [],
      votesRequired: json['votes_required'] ?? 5,
      isActive: json['is_active'] ?? true,
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
      'votes_required': votesRequired,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool isHost(String userId) => hostId == userId;
  int get participantCount => participants.length;
  bool hasParticipant(String userId) => participants.contains(userId);
  
  Session copyWith({
    String? id,
    String? code,
    String? hostId,
    String? name,
    List<String>? playlistIds,
    List<String>? participants,
    Map<String, dynamic>? currentTrack,
    List<Map<String, dynamic>>? trackQueue,
    int? votesRequired,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      name: name ?? this.name,
      playlistIds: playlistIds ?? this.playlistIds,
      participants: participants ?? this.participants,
      currentTrack: currentTrack ?? this.currentTrack,
      trackQueue: trackQueue ?? this.trackQueue,
      votesRequired: votesRequired ?? this.votesRequired,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}