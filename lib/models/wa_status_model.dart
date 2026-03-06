import 'package:lingafriq/utils/api_identity.dart';

class WaStatusModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String text;
  final String caption;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const WaStatusModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.text,
    required this.caption,
    this.createdAt,
    this.expiresAt,
  });

  factory WaStatusModel.fromJson(Map<String, dynamic> json) {
    return WaStatusModel(
      id: firstNonEmptyId(json, const ['_id', 'id']),
      userId: firstNonEmptyId(json, const ['user_id', 'userId']),
      mediaUrl: (json['media_url'] ?? json['mediaUrl'] ?? '').toString(),
      mediaType: (json['media_type'] ?? json['mediaType'] ?? 'text').toString(),
      text: (json['text'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? json['expiresAt'] ?? '').toString()),
    );
  }
}
