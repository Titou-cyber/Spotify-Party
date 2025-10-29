class Track {
  final String id;
  final String name;
  final List<String> artists;
  final String artistNames;
  final String album;
  final String albumImageUrl;
  final int durationMs;
  final String? previewUrl;
  final String uri;
  final bool isPlayable;

  Track({
    required this.id,
    required this.name,
    required this.artists,
    required this.artistNames,
    required this.album,
    required this.albumImageUrl,
    required this.durationMs,
    this.previewUrl,
    required this.uri,
    required this.isPlayable,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      name: json['name'],
      artists: List<String>.from(json['artists']),
      artistNames: json['artist_names'],
      album: json['album'],
      albumImageUrl: json['album_image_url'] ?? '',
      durationMs: json['duration_ms'],
      previewUrl: json['preview_url'],
      uri: json['uri'],
      isPlayable: json['is_playable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': artists,
      'artist_names': artistNames,
      'album': album,
      'album_image_url': albumImageUrl,
      'duration_ms': durationMs,
      'preview_url': previewUrl,
      'uri': uri,
      'is_playable': isPlayable,
    };
  }
}