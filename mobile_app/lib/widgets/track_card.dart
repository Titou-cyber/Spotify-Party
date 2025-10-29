import 'package:flutter/material.dart';
import '../models/track.dart';
import '../models/vote.dart';
import 'vote_buttons.dart';

class TrackCard extends StatelessWidget {
  final Track track;
  final VoteResults? voteResults;
  final Function(VoteType) onVote;
  final VoidCallback? onPlay;

  const TrackCard({
    super.key,
    required this.track,
    this.voteResults,
    required this.onVote,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Album Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.albumImageUrl.isNotEmpty
                  ? Image.network(
                      track.albumImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFF282828),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontSize: 16,
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
                  if (voteResults != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.thumb_up,
                          size: 16,
                          color: Color(0xFF1DB954),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${voteResults!.likes}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.thumb_down,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${voteResults!.dislikes}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Vote Buttons
            VoteButtons(onVote: onVote),

            // Play Button (if host)
            if (onPlay != null)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                color: const Color(0xFF1DB954),
                onPressed: onPlay,
              ),
          ],
        ),
      ),
    );
  }
}