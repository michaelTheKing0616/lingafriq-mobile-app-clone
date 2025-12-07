/// Magic Item/Booster model
class MagicItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final MagicItemType type;
  final int durationHours;
  final int costCowries;
  final int costBeads;
  final Map<String, dynamic> effect; // Effect parameters

  MagicItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.durationHours,
    this.costCowries = 0,
    this.costBeads = 0,
    required this.effect,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'type': type.name,
        'durationHours': durationHours,
        'costCowries': costCowries,
        'costBeads': costBeads,
        'effect': effect,
      };

  factory MagicItem.fromJson(Map<String, dynamic> json) => MagicItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        type: MagicItemType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MagicItemType.xpBoost,
        ),
        durationHours: json['durationHours'] as int,
        costCowries: json['costCowries'] as int? ?? 0,
        costBeads: json['costBeads'] as int? ?? 0,
        effect: json['effect'] as Map<String, dynamic>,
      );
}

enum MagicItemType {
  xpBoost,
  streakFreeze,
  perfectReview,
  hideFromLeaderboard,
  streakResurrection,
}

/// Magic Item Definitions
class MagicItemDefinitions {
  static List<MagicItem> get allItems => [
        MagicItem(
          id: 'ancestors_wisdom',
          name: "Ancestor's Wisdom",
          description: 'Next 10 reviews automatically marked as "Easy"',
          icon: '🧙',
          type: MagicItemType.perfectReview,
          durationHours: 0, // One-time use
          costCowries: 50,
          effect: {'reviewCount': 10, 'autoEasy': true},
        ),
        MagicItem(
          id: 'talking_drum',
          name: 'Talking Drum',
          description: 'Double XP from speaking exercises for 24 hours',
          icon: '🥁',
          type: MagicItemType.xpBoost,
          durationHours: 24,
          costCowries: 100,
          effect: {'xpMultiplier': 2.0, 'activityType': 'speaking'},
        ),
        MagicItem(
          id: 'kente_cloak',
          name: 'Kente Cloak',
          description: 'Hide from leaderboards for 7 days',
          icon: '👘',
          type: MagicItemType.hideFromLeaderboard,
          durationHours: 168, // 7 days
          costCowries: 75,
          effect: {'hidden': true},
        ),
        MagicItem(
          id: 'rainmaker',
          name: 'Rainmaker',
          description: 'Resurrect a broken streak once per month',
          icon: '🌧️',
          type: MagicItemType.streakResurrection,
          durationHours: 0, // One-time use
          costBeads: 1, // Ultra-rare, costs Ancestral Beads
          effect: {'restoreStreak': true},
        ),
        MagicItem(
          id: 'streak_freeze',
          name: 'Streak Freeze',
          description: 'Freeze your streak for 1 day',
          icon: '❄️',
          type: MagicItemType.streakFreeze,
          durationHours: 24,
          costCowries: 25,
          effect: {'freezeDays': 1},
        ),
      ];
}

