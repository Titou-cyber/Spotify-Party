class User {
  final String id;
  final String spotifyId;
  final String displayName;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.spotifyId,
    required this.displayName,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      spotifyId: json['spotify_id'],
      displayName: json['display_name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotify_id': spotifyId,
      'display_name': displayName,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}