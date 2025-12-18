/// Quest chapter model
class QuestChapter {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int chapterNumber;
  final List<QuestLesson> lessons;
  final bool isUnlocked;
  final bool isCompleted;
  final int xpReward;
  final String? badgeReward;
  final Map<String, dynamic>? metadata; // Cultural context, story, etc.

  QuestChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.chapterNumber,
    required this.lessons,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.xpReward = 500,
    this.badgeReward,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'chapterNumber': chapterNumber,
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
        'xpReward': xpReward,
        'badgeReward': badgeReward,
        'metadata': metadata,
      };

  factory QuestChapter.fromJson(Map<String, dynamic> json) => QuestChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        chapterNumber: json['chapterNumber'] as int,
        lessons: (json['lessons'] as List<dynamic>?)
                ?.map((l) => QuestLesson.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
        xpReward: json['xpReward'] as int? ?? 500,
        badgeReward: json['badgeReward'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Quest lesson model
class QuestLesson {
  final String id;
  final String title;
  final String description;
  final String lessonType; // 'vocabulary', 'grammar', 'conversation', 'boss_battle'
  final int order;
  final bool isCompleted;
  final int xpReward;

  final Map<String, dynamic>? content;

  QuestLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonType,
    required this.order,
    this.isCompleted = false,
    this.xpReward = 50,
    this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'lessonType': lessonType,
        'order': order,
        'isCompleted': isCompleted,
        'xpReward': xpReward,
        'content': content,
      };

  factory QuestLesson.fromJson(Map<String, dynamic> json) => QuestLesson(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        lessonType: json['lessonType'] as String,
        order: json['order'] as int,
        isCompleted: json['isCompleted'] as bool? ?? false,
        xpReward: json['xpReward'] as int? ?? 50,
      );
}

/// "The Great Journey" quest definitions
class QuestDefinitions {
  static List<QuestChapter> getGreatJourneyChapters() {
    return [
      QuestChapter(
        id: 'nile_awakening',
        title: 'The Nile Awakening',
        description: 'Begin your journey along the ancient Nile, learning Egyptian Arabic and Sudanese dialects.',
        icon: '🌊',
        chapterNumber: 1,
        isUnlocked: true,
        lessons: [
          QuestLesson(
            id: 'nile_1',
            title: 'Greetings on the Nile',
            description: 'Learn basic greetings in Egyptian Arabic',
            lessonType: 'vocabulary',
            order: 1,
          ),
          QuestLesson(
            id: 'nile_2',
            title: 'Market Conversations',
            description: 'Practice shopping and bargaining',
            lessonType: 'conversation',
            order: 2,
          ),
          QuestLesson(
            id: 'nile_boss',
            title: 'Boss: The Nile Guide',
            description: '30-minute unscripted conversation with AI guide',
            lessonType: 'boss_battle',
            order: 3,
            xpReward: 200,
          ),
        ],
        xpReward: 500,
        badgeReward: 'nile_explorer',
        metadata: {
          'region': 'North Africa',
          'languages': ['Egyptian Arabic', 'Sudanese Arabic'],
        },
      ),
      QuestChapter(
        id: 'savannah_secrets',
        title: 'Savannah Secrets',
        description: 'Explore the Swahili Coast and learn the language of trade and culture.',
        icon: '🌴',
        chapterNumber: 2,
        lessons: [
          QuestLesson(
            id: 'savannah_1',
            title: 'Coastal Greetings',
            description: 'Master Swahili greetings',
            lessonType: 'vocabulary',
            order: 1,
          ),
          QuestLesson(
            id: 'savannah_2',
            title: 'Trading Phrases',
            description: 'Learn market and trading vocabulary',
            lessonType: 'conversation',
            order: 2,
          ),
          QuestLesson(
            id: 'savannah_boss',
            title: 'Boss: The Swahili Merchant',
            description: 'Complete a complex trading negotiation',
            lessonType: 'boss_battle',
            order: 3,
            xpReward: 200,
          ),
        ],
        xpReward: 500,
        badgeReward: 'swahili_coast_explorer',
        metadata: {
          'region': 'East Africa',
          'languages': ['Swahili'],
        },
      ),
      QuestChapter(
        id: 'yoruba_oracle',
        title: 'Yoruba Oracle',
        description: 'Discover the wisdom of the Yoruba people in Nigeria.',
        icon: '🔮',
        chapterNumber: 5,
        lessons: [
          QuestLesson(
            id: 'yoruba_1',
            title: 'Respectful Greetings',
            description: 'Learn honorifics and respectful forms',
            lessonType: 'vocabulary',
            order: 1,
          ),
          QuestLesson(
            id: 'yoruba_2',
            title: 'Proverbs and Wisdom',
            description: 'Master Yoruba proverbs and cultural expressions',
            lessonType: 'grammar',
            order: 2,
          ),
          QuestLesson(
            id: 'yoruba_boss',
            title: 'Boss: The Oracle',
            description: 'Engage in deep cultural conversation',
            lessonType: 'boss_battle',
            order: 3,
            xpReward: 200,
          ),
        ],
        xpReward: 500,
        badgeReward: 'yoruba_oracle',
        metadata: {
          'region': 'West Africa',
          'languages': ['Yoruba'],
        },
      ),
      // Add more chapters as needed (up to 12)
    ];
  }
}

