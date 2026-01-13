import 'package:flutter/foundation.dart';

/// Types of daily challenges
enum ChallengeType {
  lessonsComplete,      // Complete X lessons
  xpEarned,            // Earn X XP
  perfectQuiz,         // Get a perfect quiz score
  streakMaintain,      // Maintain your streak
  wordsLearned,        // Learn X new words
  gamesPlayed,         // Play X games
  timeSpent,           // Spend X minutes learning
  chatMessages,        // Send X messages to Polie
  storyChapters,       // Complete X story chapters
  culturalContent,     // Read X cultural articles
  voiceRecordings,     // Record X voice samples
  socialInteraction,   // Interact with X users
}

/// Challenge difficulty affects XP rewards
enum ChallengeDifficulty {
  easy,    // 1.0x multiplier
  medium,  // 1.5x multiplier
  hard,    // 2.0x multiplier
  expert,  // 3.0x multiplier
}

/// A daily challenge model
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int target;
  final int progress;
  final int xpReward;
  final int cowriesReward;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCompleted;
  final bool isClaimed;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.difficulty,
    required this.target,
    this.progress = 0,
    required this.xpReward,
    required this.cowriesReward,
    required this.createdAt,
    required this.expiresAt,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  /// Progress percentage (0.0 to 1.0)
  double get progressPercent => (progress / target).clamp(0.0, 1.0);

  /// Remaining time until expiry
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Check if challenge is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if challenge is ready to claim
  bool get canClaim => isCompleted && !isClaimed && !isExpired;

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    int? target,
    int? progress,
    int? xpReward,
    int? cowriesReward,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
    bool? isClaimed,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      xpReward: xpReward ?? this.xpReward,
      cowriesReward: cowriesReward ?? this.cowriesReward,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.name,
      'difficulty': difficulty.name,
      'target': target,
      'progress': progress,
      'xpReward': xpReward,
      'cowriesReward': cowriesReward,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.xpEarned,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ChallengeDifficulty.easy,
      ),
      target: json['target'] as int,
      progress: json['progress'] as int? ?? 0,
      xpReward: json['xpReward'] as int,
      cowriesReward: json['cowriesReward'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }
}

/// Daily challenge templates for generation
class DailyChallengeTemplates {
  static List<DailyChallenge> generateDailyChallenges() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return [
      // Easy challenges
      DailyChallenge(
        id: 'daily_lessons_${now.day}',
        title: 'Daily Learner',
        description: 'Complete 3 lessons today',
        emoji: '📚',
        type: ChallengeType.lessonsComplete,
        difficulty: ChallengeDifficulty.easy,
        target: 3,
        xpReward: 50,
        cowriesReward: 25,
        createdAt: now,
        expiresAt: endOfDay,
      ),
      DailyChallenge(
        id: 'daily_xp_${now.day}',
        title: 'XP Hunter',
        description: 'Earn 100 XP today',
        emoji: '⭐',
        type: ChallengeType.xpEarned,
        difficulty: ChallengeDifficulty.easy,
        target: 100,
        xpReward: 30,
        cowriesReward: 15,
        createdAt: now,
        expiresAt: endOfDay,
      ),
      
      // Medium challenges
      DailyChallenge(
        id: 'daily_perfect_${now.day}',
        title: 'Perfectionist',
        description: 'Get a perfect score on any quiz',
        emoji: '💯',
        type: ChallengeType.perfectQuiz,
        difficulty: ChallengeDifficulty.medium,
        target: 1,
        xpReward: 75,
        cowriesReward: 40,
        createdAt: now,
        expiresAt: endOfDay,
      ),
      DailyChallenge(
        id: 'daily_words_${now.day}',
        title: 'Word Collector',
        description: 'Learn 10 new words',
        emoji: '🔤',
        type: ChallengeType.wordsLearned,
        difficulty: ChallengeDifficulty.medium,
        target: 10,
        xpReward: 60,
        cowriesReward: 30,
        createdAt: now,
        expiresAt: endOfDay,
      ),
      
      // Hard challenge
      DailyChallenge(
        id: 'daily_marathon_${now.day}',
        title: 'Learning Marathon',
        description: 'Spend 30 minutes learning',
        emoji: '🏃',
        type: ChallengeType.timeSpent,
        difficulty: ChallengeDifficulty.hard,
        target: 30,
        xpReward: 100,
        cowriesReward: 50,
        createdAt: now,
        expiresAt: endOfDay,
      ),
    ];
  }

  /// Weekend warrior bonus challenges
  static List<DailyChallenge> generateWeekendChallenges() {
    final now = DateTime.now();
    final endOfWeekend = DateTime(now.year, now.month, now.day + (7 - now.weekday), 23, 59, 59);
    
    return [
      DailyChallenge(
        id: 'weekend_warrior_${now.day}',
        title: '🔥 Weekend Warrior',
        description: 'Earn 500 XP this weekend (2x bonus!)',
        emoji: '🔥',
        type: ChallengeType.xpEarned,
        difficulty: ChallengeDifficulty.expert,
        target: 500,
        xpReward: 300, // 2x weekend bonus
        cowriesReward: 150,
        createdAt: now,
        expiresAt: endOfWeekend,
      ),
      DailyChallenge(
        id: 'weekend_explorer_${now.day}',
        title: '🌍 Cultural Explorer',
        description: 'Read 5 cultural articles',
        emoji: '🌍',
        type: ChallengeType.culturalContent,
        difficulty: ChallengeDifficulty.hard,
        target: 5,
        xpReward: 200,
        cowriesReward: 100,
        createdAt: now,
        expiresAt: endOfWeekend,
      ),
    ];
  }
}

