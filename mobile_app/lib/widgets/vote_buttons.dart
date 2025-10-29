import 'package:flutter/material.dart';
import '../models/vote.dart';

class VoteButtons extends StatelessWidget {
  final Function(VoteType) onVote;

  const VoteButtons({
    super.key,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.thumb_down),
          color: Colors.red,
          onPressed: () => onVote(VoteType.dislike),
        ),
        IconButton(
          icon: const Icon(Icons.thumb_up),
          color: const Color(0xFF1DB954),
          onPressed: () => onVote(VoteType.like),
        ),
      ],
    );
  }
}