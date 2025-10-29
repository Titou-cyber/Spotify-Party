import 'package:flutter/material.dart';
import '../models/track.dart';

class NowPlayingWidget extends StatelessWidget {
  final Track track;

  const NowPlayingWidget({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1DB954).withOpacity(0.3),
            const Color(0xFF282828),
          ],
        ),
      ),
      child: Row(
        children: [
          // Album Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: track.albumImageUrl.isNotEmpty
                ? Image.network(
                    track.albumImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFF191414),
                    child: const Icon(
                      Icons.music_note,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EN COURS',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1DB954),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artistNames,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Playing Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}