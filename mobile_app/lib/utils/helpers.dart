import 'dart:convert';
import 'package:crypto/crypto.dart';

class Helpers {
  static String generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  static String generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }
}