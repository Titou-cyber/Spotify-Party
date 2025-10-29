enum VoteType { like, dislike }

class Vote {
  final String id;
  final String sessionId;
  final String userId;
  final String trackId;
  final VoteType voteType;
  final DateTime createdAt;

  Vote({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.trackId,
    required this.voteType,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      sessionId: json['session_id'],
      userId: json['user_id'],
      trackId: json['track_id'],
      voteType: json['vote_type'] == 'like' ? VoteType.like : VoteType.dislike,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'track_id': trackId,
      'vote_type': voteType == VoteType.like ? 'like' : 'dislike',
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class VoteResults {
  final String trackId;
  final int likes;
  final int dislikes;
  final int totalVotes;

  VoteResults({
    required this.trackId,
    required this.likes,
    required this.dislikes,
    required this.totalVotes,
  });

  factory VoteResults.fromJson(Map<String, dynamic> json) {
    return VoteResults(
      trackId: json['track_id'],
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      totalVotes: json['total_votes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track_id': trackId,
      'likes': likes,
      'dislikes': dislikes,
      'total_votes': totalVotes,
    };
  }
}