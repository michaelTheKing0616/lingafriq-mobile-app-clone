import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';

class SocialFeedNotifier extends Notifier<List<SocialFeedItem>> {
  @override
  List<SocialFeedItem> build() {
    _setupSocketListeners();
    return [];
  }

  void _setupSocketListeners() {
    // Listen for real-time feed updates via Socket.io
    // This would be implemented based on your socket setup
  }

  Future<void> loadFeed() async {
    try {
      final response = await ApiService.get(
        ApiContract.url('/api/social/feed'),
        queryParameters: {'limit': 50},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['feed'] is List) {
          state = (data['feed'] as List)
              .map((item) => SocialFeedItem.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          state = data
              .map((item) => SocialFeedItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      logger.error('Error loading social feed', tag: 'social_feed', error: e);
      state = [];
    }
  }

  void addFeedItem(SocialFeedItem item) {
    state = [item, ...state];
  }
}

final socialFeedProvider = NotifierProvider<SocialFeedNotifier, List<SocialFeedItem>>(
  () => SocialFeedNotifier(),
);

class SocialFeedItem {
  final String id;
  final String type;
  final String userId;
  final String userName;
  final String? details;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SocialFeedItem({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.details,
    required this.timestamp,
    this.metadata,
  });

  factory SocialFeedItem.fromJson(Map<String, dynamic> json) {
    return SocialFeedItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'lesson_complete',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? json['username']?.toString() ?? 'User',
      details: json['details']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
