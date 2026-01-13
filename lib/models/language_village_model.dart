/// Language Village (Voice Room) model
class LanguageVillage {
  final String id;
  final String name;
  final String language;
  final String description;
  final int currentParticipants;
  final int maxParticipants;
  final bool isActive;
  final DateTime? lastActivity;
  final String? hostId;
  final List<String> rules; // Village rules

  LanguageVillage({
    required this.id,
    required this.name,
    required this.language,
    required this.description,
    this.currentParticipants = 0,
    this.maxParticipants = 50,
    this.isActive = true,
    this.lastActivity,
    this.hostId,
    this.rules = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language,
        'description': description,
        'currentParticipants': currentParticipants,
        'maxParticipants': maxParticipants,
        'isActive': isActive,
        'lastActivity': lastActivity?.toIso8601String(),
        'hostId': hostId,
        'rules': rules,
      };

  factory LanguageVillage.fromJson(Map<String, dynamic> json) => LanguageVillage(
        id: (json['id'] ?? json['_id']).toString(),
        name: json['name'] as String? ?? 'Language Village',
        language: (json['language'] ?? json['lang'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        currentParticipants: json['currentParticipants'] as int? ?? 0,
        maxParticipants: json['maxParticipants'] as int? ?? 50,
        isActive: json['isActive'] as bool? ?? true,
        lastActivity: json['lastActivity'] != null
            ? DateTime.parse(json['lastActivity'] as String)
            : null,
        hostId: json['hostId'] as String?,
        rules: (json['rules'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

/// Village participant
class VillageParticipant {
  final String userId;
  final String username;
  final String? avatar;
  final bool isHost;
  final bool isSpeaking;
  final DateTime joinedAt;

  VillageParticipant({
    required this.userId,
    required this.username,
    this.avatar,
    this.isHost = false,
    this.isSpeaking = false,
    required this.joinedAt,
  });
}

