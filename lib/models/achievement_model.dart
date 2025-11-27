import 'dart:convert';

enum AchievementType {
  badge,
  medal,
  trophy,
  milestone,
  streak,
  xp,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final String icon; // Icon name or emoji
  final int xpReward;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final Map<String, dynamic>? metadata;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.xpReward,
    this.unlockedAt,
    this.isUnlocked = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'rarity': rarity.name,
    'icon': icon,
    'xpReward': xpReward,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isUnlocked': isUnlocked,
    'metadata': metadata,
  };

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    type: AchievementType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => AchievementType.badge,
    ),
    rarity: AchievementRarity.values.firstWhere(
      (e) => e.name == map['rarity'],
      orElse: () => AchievementRarity.common,
    ),
    icon: map['icon'] ?? '🏆',
    xpReward: map['xpReward'] ?? 0,
    unlockedAt: map['unlockedAt'] != null 
        ? DateTime.parse(map['unlockedAt']) 
        : null,
    isUnlocked: map['isUnlocked'] ?? false,
    metadata: map['metadata'] != null 
        ? Map<String, dynamic>.from(map['metadata']) 
        : null,
  );

  String toJson() => jsonEncode(toMap());
  factory Achievement.fromJson(String json) => Achievement.fromMap(jsonDecode(json));
}

