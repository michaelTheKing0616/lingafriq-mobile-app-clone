/// Seasonal Event model
class SeasonalEvent {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime startDate;
  final DateTime endDate;
  final double xpMultiplier;
  final List<String> featuredLanguages;
  final Map<String, dynamic> specialRewards;
  final EventType type;
  final bool isActive;

  SeasonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.startDate,
    required this.endDate,
    this.xpMultiplier = 1.0,
    this.featuredLanguages = const [],
    this.specialRewards = const {},
    required this.type,
  }) : isActive = DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isPast => DateTime.now().isAfter(endDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());
  Duration get timeUntilStart => startDate.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'xpMultiplier': xpMultiplier,
        'featuredLanguages': featuredLanguages,
        'specialRewards': specialRewards,
        'type': type.name,
      };

  factory SeasonalEvent.fromJson(Map<String, dynamic> json) => SeasonalEvent(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        xpMultiplier: (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0,
        featuredLanguages: (json['featuredLanguages'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        specialRewards: json['specialRewards'] as Map<String, dynamic>? ?? {},
        type: EventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EventType.cultural,
        ),
      );
}

enum EventType {
  cultural,
  religious,
  seasonal,
  competition,
}

/// Seasonal Event Definitions
class SeasonalEventDefinitions {
  static List<SeasonalEvent> get allEvents {
    final now = DateTime.now();
    final year = now.year;

    return [
      // Festival of Masks (February)
      SeasonalEvent(
        id: 'festival_of_masks',
        name: 'Festival of Masks',
        description: 'Celebrate African mask traditions! Learn about cultural expressions.',
        icon: '🎭',
        startDate: DateTime(year, 2, 1),
        endDate: DateTime(year, 2, 28),
        xpMultiplier: 1.5,
        featuredLanguages: ['Yoruba', 'Igbo', 'Akan'],
        specialRewards: {'badge': 'mask_master', 'cowries': 100},
        type: EventType.cultural,
      ),
      // Eid/Ramadan Challenge (March-April)
      SeasonalEvent(
        id: 'eid_ramadan_challenge',
        name: 'Eid/Ramadan Challenge',
        description: 'Night lessons (12am-4am) earn 3× XP! Learn Arabic greetings and phrases.',
        icon: '🌙',
        startDate: DateTime(year, 3, 10),
        endDate: DateTime(year, 4, 20),
        xpMultiplier: 3.0, // For night lessons
        featuredLanguages: ['Arabic', 'Swahili', 'Hausa'],
        specialRewards: {'badge': 'night_learner', 'beads': 1},
        type: EventType.religious,
      ),
      // Yam Festival (August)
      SeasonalEvent(
        id: 'yam_festival',
        name: 'Yam Festival',
        description: 'Celebrate the harvest! Focus on Igbo and Yoruba food vocabulary.',
        icon: '🍠',
        startDate: DateTime(year, 8, 1),
        endDate: DateTime(year, 8, 31),
        xpMultiplier: 1.5,
        featuredLanguages: ['Igbo', 'Yoruba'],
        specialRewards: {'badge': 'yam_warrior', 'cowries': 150},
        type: EventType.cultural,
      ),
      // Heritage Month (September)
      SeasonalEvent(
        id: 'heritage_month',
        name: 'Heritage Month Mega-Event',
        description: 'The biggest event of the year! All languages, all activities, 2× XP!',
        icon: '🏛️',
        startDate: DateTime(year, 9, 1),
        endDate: DateTime(year, 9, 30),
        xpMultiplier: 2.0,
        featuredLanguages: [], // All languages
        specialRewards: {'badge': 'heritage_guardian', 'beads': 2, 'cowries': 200},
        type: EventType.cultural,
      ),
      // Harmattan Hustle (Dec-Feb)
      SeasonalEvent(
        id: 'harmattan_hustle',
        name: 'Harmattan Hustle',
        description: 'Longest streak competition! Survive the dry season with daily practice.',
        icon: '🌬️',
        startDate: DateTime(year - 1, 12, 1),
        endDate: DateTime(year, 2, 28),
        xpMultiplier: 1.2,
        featuredLanguages: ['Hausa', 'Fulfulde', 'Kanuri'],
        specialRewards: {'badge': 'harmattan_survivor', 'cowries': 300},
        type: EventType.seasonal,
      ),
    ];
  }

  static List<SeasonalEvent> get activeEvents =>
      allEvents.where((e) => e.isActive).toList();

  static List<SeasonalEvent> get upcomingEvents =>
      allEvents.where((e) => e.isUpcoming).toList();
}

