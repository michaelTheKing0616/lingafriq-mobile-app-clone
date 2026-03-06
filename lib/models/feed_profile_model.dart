import 'package:lingafriq/utils/api_identity.dart';

class FeedProfileModel {
  final String userId;
  final String username;
  final String displayName;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int unreadNotifications;

  const FeedProfileModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.unreadNotifications,
  });

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory FeedProfileModel.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] ?? '').toString().trim();
    final last = (json['last_name'] ?? '').toString().trim();
    final display = (json['display_name'] ?? '').toString().trim();
    return FeedProfileModel(
      userId: firstNonEmptyId(json, const ['user_id', '_id', 'id']),
      username: (json['username'] ?? '').toString(),
      displayName: display.isNotEmpty ? display : ('$first $last').trim(),
      postsCount: _readInt(json['posts_count']),
      followersCount: _readInt(json['followers_count']),
      followingCount: _readInt(json['following_count']),
      unreadNotifications: _readInt(json['unread_notifications']),
    );
  }
}
