import 'package:lingafriq/utils/api_identity.dart';

class FeedPostModel {
  final String id;
  final String authorId;
  final String content;
  final String type;
  final int likeCount;
  final int replyCount;
  final int repostCount;
  final int viewCount;
  final DateTime? createdAt;

  const FeedPostModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.type,
    required this.likeCount,
    required this.replyCount,
    required this.repostCount,
    required this.viewCount,
    this.createdAt,
  });

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FeedPostModel(
      id: firstNonEmptyId(json, const ['_id', 'id']),
      authorId: firstNonEmptyId(json, const ['author_id', 'authorId']),
      content: (json['content'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      likeCount: readInt(json['like_count'] ?? json['likeCount']),
      replyCount: readInt(json['reply_count'] ?? json['replyCount']),
      repostCount: readInt(json['repost_count'] ?? json['repostCount']),
      viewCount: readInt(json['view_count'] ?? json['viewCount']),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()),
    );
  }
}
