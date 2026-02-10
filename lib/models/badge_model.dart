/// Badge rarity levels
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Badge categories
enum BadgeCategory {
  streak,
  learning,
  pronunciation,
  cultural,
  social,
  special,
  languageSpecific,
}

/// Comprehensive badge model with African cultural context
class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeRarity rarity;
  final BadgeCategory category;
  final String icon; // Emoji or icon identifier
  final int xpReward;
  final int cowriesReward;
  final int beadsReward;
  final String? language; // Language-specific badges
  final Map<String, dynamic>? requirements; // Flexible requirements
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.category,
    required this.icon,
    this.xpReward = 50,
    this.cowriesReward = 0,
    this.beadsReward = 0,
    this.language,
    this.requirements,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    BadgeRarity? rarity,
    BadgeCategory? category,
    String? icon,
    int? xpReward,
    int? cowriesReward,
    int? beadsReward,
    String? language,
    Map<String, dynamic>? requirements,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      xpReward: xpReward ?? this.xpReward,
      cowriesReward: cowriesReward ?? this.cowriesReward,
      beadsReward: beadsReward ?? this.beadsReward,
      language: language ?? this.language,
      requirements: requirements ?? this.requirements,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rarity': rarity.name,
        'category': category.name,
        'icon': icon,
        'xpReward': xpReward,
        'cowriesReward': cowriesReward,
        'beadsReward': beadsReward,
        'language': language,
        'requirements': requirements,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        rarity: BadgeRarity.values.firstWhere(
          (e) => e.name == (json['rarity'] as String?),
          orElse: () => BadgeRarity.common,
        ),
        category: BadgeCategory.values.firstWhere(
          (e) => e.name == (json['category'] as String?),
          orElse: () => BadgeCategory.learning,
        ),
        icon: (json['icon'] as String?) ?? '',
        xpReward: (json['xpReward'] as num?)?.toInt() ?? 50,
        cowriesReward: (json['cowriesReward'] as num?)?.toInt() ?? 0,
        beadsReward: (json['beadsReward'] as num?)?.toInt() ?? 0,
        language: json['language'] as String?,
        requirements: json['requirements'] is Map
            ? Map<String, dynamic>.from(json['requirements'] as Map)
            : null,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.tryParse((json['unlockedAt'] as String?) ?? '')
            : null,
      );
}

/// Predefined African-themed badges
class BadgeDefinitions {
  static List<Badge> getAllBadges() {
    return [
      // Streak Badges
      Badge(
        id: 'streak_7',
        name: 'Week Warrior',
        description: 'Maintain a 7-day learning streak',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.streak,
        icon: '🔥',
        xpReward: 100,
        cowriesReward: 50,
      ),
      Badge(
        id: 'streak_30',
        name: 'Monthly Master',
        description: 'Maintain a 30-day learning streak',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.streak,
        icon: '⭐',
        xpReward: 500,
        cowriesReward: 200,
      ),
      Badge(
        id: 'streak_100',
        name: 'Century Champion',
        description: 'Maintain a 100-day learning streak',
        rarity: BadgeRarity.legendary,
        category: BadgeCategory.streak,
        icon: '👑',
        xpReward: 2000,
        cowriesReward: 1000,
        beadsReward: 10,
      ),
      Badge(
        id: 'harmattan_survivor',
        name: 'Harmattan Survivor',
        description: '90-day streak during dry season (Dec-Feb)',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.streak,
        icon: '🌬️',
        xpReward: 1500,
        cowriesReward: 500,
        beadsReward: 5,
      ),

      // Pronunciation Badges
      Badge(
        id: 'click_master',
        name: 'Click Master',
        description: '1000 perfect Xhosa/Zulu clicks',
        rarity: BadgeRarity.legendary,
        category: BadgeCategory.pronunciation,
        icon: '👆',
        xpReward: 2000,
        cowriesReward: 1000,
        beadsReward: 15,
        language: 'xhosa',
      ),
      Badge(
        id: 'tonal_master',
        name: 'Tonal Master',
        description: '7 days of perfect tonal pronunciation',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.pronunciation,
        icon: '🎵',
        xpReward: 1000,
        cowriesReward: 300,
        beadsReward: 3,
      ),

      // Cultural Badges
      Badge(
        id: 'jollof_wars_victor',
        name: 'Jollof Wars Victor',
        description: 'Win 10 food-ordering roleplays',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.cultural,
        icon: '🍛',
        xpReward: 500,
        cowriesReward: 200,
      ),
      Badge(
        id: 'adinkra_sage',
        name: 'Adinkra Sage',
        description: 'Collect all 30 wisdom-symbol lessons',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.cultural,
        icon: '🕉️',
        xpReward: 1500,
        cowriesReward: 500,
        beadsReward: 10,
      ),
      Badge(
        id: 'market_bargainer',
        name: 'Market Bargainer',
        description: 'Successfully complete 20 market bargaining roleplays',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.cultural,
        icon: '🏪',
        xpReward: 600,
        cowriesReward: 250,
      ),
      Badge(
        id: 'fufu_champion',
        name: 'Fufu Champion',
        description: 'Master all food vocabulary in 5 languages',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.cultural,
        icon: '🍽️',
        xpReward: 1200,
        cowriesReward: 400,
        beadsReward: 5,
      ),

      // Special Badges
      Badge(
        id: 'night_runner',
        name: 'Night Runner',
        description: 'Complete lessons 12am-4am 50 times',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.special,
        icon: '🌙',
        xpReward: 800,
        cowriesReward: 300,
      ),
      Badge(
        id: 'ubuntu_helper',
        name: 'Ubuntu Helper',
        description: 'Help 50 other learners in forums',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.social,
        icon: '🤝',
        xpReward: 1000,
        cowriesReward: 500,
        beadsReward: 5,
      ),

      // Language-Specific Badges (examples)
      Badge(
        id: 'yoruba_oracle',
        name: 'Yoruba Oracle',
        description: 'Master 500 Yoruba words with perfect diacritics',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.languageSpecific,
        icon: '🔮',
        xpReward: 1500,
        cowriesReward: 500,
        beadsReward: 10,
        language: 'yoruba',
      ),
      Badge(
        id: 'swahili_coast_explorer',
        name: 'Swahili Coast Explorer',
        description: 'Complete all Swahili coastal scenarios',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.languageSpecific,
        icon: '🏖️',
        xpReward: 800,
        cowriesReward: 300,
        language: 'swahili',
      ),
      Badge(
        id: 'zulu_warrior',
        name: 'Zulu Warrior',
        description: 'Achieve 95%+ pronunciation on 100 Zulu phrases',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.languageSpecific,
        icon: '🛡️',
        xpReward: 1200,
        cowriesReward: 400,
        beadsReward: 5,
        language: 'zulu',
      ),
    ];
  }

  static Badge? getBadgeById(String id) {
    return getAllBadges().firstWhere(
      (badge) => badge.id == id,
      orElse: () => throw StateError('Badge not found: $id'),
    );
  }
}

