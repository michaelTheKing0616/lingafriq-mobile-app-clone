import 'package:lingafriq/utils/api_identity.dart';

class SnapMessageModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String mediaUrl;
  final String mediaType;
  final String caption;
  final bool opened;

  const SnapMessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.opened,
  });

  factory SnapMessageModel.fromJson(Map<String, dynamic> json) => SnapMessageModel(
        id: firstNonEmptyId(json, const ['_id', 'id']),
        senderId: firstNonEmptyId(json, const ['sender_id', 'senderId']),
        recipientId: firstNonEmptyId(json, const ['recipient_id', 'recipientId']),
        mediaUrl: (json['media_url'] ?? '').toString(),
        mediaType: (json['media_type'] ?? 'image').toString(),
        caption: (json['caption'] ?? '').toString(),
        opened: json['viewed_at'] != null,
      );
}

class SnapStoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String caption;

  const SnapStoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
  });

  factory SnapStoryModel.fromJson(Map<String, dynamic> json) => SnapStoryModel(
        id: firstNonEmptyId(json, const ['_id', 'id']),
        userId: firstNonEmptyId(json, const ['user_id', 'userId']),
        mediaUrl: (json['media_url'] ?? '').toString(),
        mediaType: (json['media_type'] ?? 'image').toString(),
        caption: (json['caption'] ?? '').toString(),
      );
}
