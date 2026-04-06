import 'package:lingafriq/utils/api_identity.dart';

/// Normalized feed post for the X-style community timeline.
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

  /// Populated when `author_id` is expanded by the API; otherwise null.
  final String? authorDisplayName;
  final String? authorUsername;

  final String? languageCode;
  final List<String> mediaUrls;
  final String? audioUrl;

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
    this.authorDisplayName,
    this.authorUsername,
    this.languageCode,
    this.mediaUrls = const [],
    this.audioUrl,
  });

  String get displayName {
    if (authorDisplayName != null && authorDisplayName!.trim().isNotEmpty) {
      return authorDisplayName!.trim();
    }
    final u = authorUsername?.trim();
    if (u != null && u.isNotEmpty) return u;
    if (authorId.length > 8) return 'Learner ${authorId.substring(0, 8)}…';
    return 'Learner';
  }

  String get handle {
    final u = authorUsername?.trim();
    if (u != null && u.isNotEmpty) return '@$u';
    return '@user';
  }

  String get languageChipLabel {
    final c = languageCode?.trim();
    if (c == null || c.isEmpty) return 'General';
    if (c.length == 1) return c.toUpperCase();
    return '${c[0].toUpperCase()}${c.substring(1)}';
  }

  bool get hasAudio =>
      (audioUrl != null && audioUrl!.trim().isNotEmpty) || type == 'audio';

  bool get hasImage =>
      mediaUrls.isNotEmpty || type == 'image' || type == 'video';

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final rawAuthor = json['author_id'] ?? json['authorId'];
    String authorId = '';
    String? authorDisplayName;
    String? authorUsername;
    if (rawAuthor is Map) {
      final m = Map<String, dynamic>.from(rawAuthor);
      authorId = firstNonEmptyId(m, const ['_id', 'id']);
      authorUsername = m['username']?.toString();
      final fn = m['first_name']?.toString() ?? m['firstName']?.toString() ?? '';
      final ln = m['last_name']?.toString() ?? m['lastName']?.toString() ?? '';
      final combined = ('$fn $ln').trim();
      authorDisplayName = combined.isNotEmpty ? combined : null;
    } else {
      authorId = normalizeApiId(rawAuthor);
    }

    final media = <String>[];
    final rawMedia = json['media_urls'] ?? json['mediaUrls'];
    if (rawMedia is List) {
      for (final e in rawMedia) {
        if (e != null) media.add(e.toString());
      }
    }

    final audioRaw = json['audio_url'] ?? json['audioUrl'];
    final audioUrl = audioRaw != null && audioRaw.toString().trim().isNotEmpty
        ? audioRaw.toString().trim()
        : null;

    final langRaw = json['language_code'] ?? json['languageCode'];
    final languageCode =
        langRaw != null && langRaw.toString().trim().isNotEmpty ? langRaw.toString().trim() : null;

    return FeedPostModel(
      id: firstNonEmptyId(json, const ['_id', 'id']),
      authorId: authorId,
      content: (json['content'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      likeCount: readInt(json['like_count'] ?? json['likeCount']),
      replyCount: readInt(json['reply_count'] ?? json['replyCount']),
      repostCount: readInt(json['repost_count'] ?? json['repostCount']),
      viewCount: readInt(json['view_count'] ?? json['viewCount']),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()),
      authorDisplayName: authorDisplayName,
      authorUsername: authorUsername,
      languageCode: languageCode,
      mediaUrls: media,
      audioUrl: audioUrl,
    );
  }

  FeedPostModel copyWith({
    String? id,
    String? authorId,
    String? content,
    String? type,
    int? likeCount,
    int? replyCount,
    int? repostCount,
    int? viewCount,
    DateTime? createdAt,
    String? authorDisplayName,
    String? authorUsername,
    String? languageCode,
    List<String>? mediaUrls,
    String? audioUrl,
  }) {
    return FeedPostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      type: type ?? this.type,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      repostCount: repostCount ?? this.repostCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorUsername: authorUsername ?? this.authorUsername,
      languageCode: languageCode ?? this.languageCode,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}
