import 'package:flutter/material.dart';

class UserListWidget extends StatelessWidget {
  final List<String> userIds;

  const UserListWidget({
    super.key,
    required this.userIds,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: userIds.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1DB954),
              child: Text(
                userIds[index].substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}