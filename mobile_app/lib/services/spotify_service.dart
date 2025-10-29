import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String redirectUrl = 'spotify-party://callback';

  Future<bool> connectToSpotify() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      return true;
    } catch (e) {
      print('Error connecting to Spotify: $e');
      return false;
    }
  }

  Future<void> play(String trackUri) async {
    try {
      await SpotifySdk.play(spotifyUri: trackUri);
    } catch (e) {
      print('Error playing track: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      await SpotifySdk.resume();
    } catch (e) {
      print('Error resuming: $e');
    }
  }

  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      print('Error skipping next: $e');
    }
  }

  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      print('Error skipping previous: $e');
    }
  }

  Future<Map<String, dynamic>?> getPlayerState() async {
    try {
      final state = await SpotifySdk.getPlayerState();
      return {
        'isPlaying': state.isPlaying,
        'playbackPosition': state.playbackPosition,
        'playbackSpeed': state.playbackSpeed,
      };
    } catch (e) {
      print('Error getting player state: $e');
      return null;
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: position.inMilliseconds);
    } catch (e) {
      print('Error seeking: $e');
    }
  }
}