/// Enhanced user gamification model with African-themed features
class UserGamificationModel {
  final int xp;
  final int level;
  final String levelTitle;
  final int ngwenya; // Daily earn currency
  final int cowries; // Premium currency
  final int ancestralBeads; // Ultra-rare achievement currency
  final int dailyStreak;
  final int perfectWeekStreak;
  final int tonalMasteryStreak;
  final int freezeLeft; // Streak freeze count
  final String? tribe; // Zulu, Yoruba, Igbo, Swahili, Amhara, etc.
  final List<String> unlockedBadges;
  final List<String> activeBoosters;
  final Map<String, int> questProgress; // questId -> progress
  final DateTime? lastLogin;
  final bool ubuntuStreakActive; // Never break - help others if you do
  
  // Additional progress tracking properties
  final int lessonsCompleted;
  final int wordsLearned;
  final int languagesLearned;
  final int totalXP; // Alias for xp, kept for backward compatibility
  final String? currentLanguage;
  final int quizzesCompleted;
  final int perfectQuizzes;
  final int gamesPlayed;
  final int polieMessages;
  final int storyChaptersRead;
  final int voiceContributions;

  UserGamificationModel({
    this.xp = 0,
    this.level = 1,
    this.levelTitle = 'Stranger at the Village Gate',
    this.ngwenya = 0,
    this.cowries = 0,
    this.ancestralBeads = 0,
    this.dailyStreak = 0,
    this.perfectWeekStreak = 0,
    this.tonalMasteryStreak = 0,
    this.freezeLeft = 2,
    this.tribe,
    this.unlockedBadges = const [],
    this.activeBoosters = const [],
    this.questProgress = const {},
    this.lastLogin,
    this.ubuntuStreakActive = false,
    this.lessonsCompleted = 0,
    this.wordsLearned = 0,
    this.languagesLearned = 0,
    this.totalXP = 0,
    this.currentLanguage,
    this.quizzesCompleted = 0,
    this.perfectQuizzes = 0,
    this.gamesPlayed = 0,
    this.polieMessages = 0,
    this.storyChaptersRead = 0,
    this.voiceContributions = 0,
  });

  UserGamificationModel copyWith({
    int? xp,
    int? level,
    String? levelTitle,
    int? ngwenya,
    int? cowries,
    int? ancestralBeads,
    int? dailyStreak,
    int? perfectWeekStreak,
    int? tonalMasteryStreak,
    int? freezeLeft,
    String? tribe,
    List<String>? unlockedBadges,
    List<String>? activeBoosters,
    Map<String, int>? questProgress,
    DateTime? lastLogin,
    bool? ubuntuStreakActive,
    int? lessonsCompleted,
    int? wordsLearned,
    int? languagesLearned,
    int? totalXP,
    String? currentLanguage,
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? gamesPlayed,
    int? polieMessages,
    int? storyChaptersRead,
    int? voiceContributions,
  }) {
    return UserGamificationModel(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      ngwenya: ngwenya ?? this.ngwenya,
      cowries: cowries ?? this.cowries,
      ancestralBeads: ancestralBeads ?? this.ancestralBeads,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      perfectWeekStreak: perfectWeekStreak ?? this.perfectWeekStreak,
      tonalMasteryStreak: tonalMasteryStreak ?? this.tonalMasteryStreak,
      freezeLeft: freezeLeft ?? this.freezeLeft,
      tribe: tribe ?? this.tribe,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      activeBoosters: activeBoosters ?? this.activeBoosters,
      questProgress: questProgress ?? this.questProgress,
      lastLogin: lastLogin ?? this.lastLogin,
      ubuntuStreakActive: ubuntuStreakActive ?? this.ubuntuStreakActive,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      languagesLearned: languagesLearned ?? this.languagesLearned,
      totalXP: totalXP ?? this.totalXP,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      polieMessages: polieMessages ?? this.polieMessages,
      storyChaptersRead: storyChaptersRead ?? this.storyChaptersRead,
      voiceContributions: voiceContributions ?? this.voiceContributions,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'level': level,
        'levelTitle': levelTitle,
        'ngwenya': ngwenya,
        'cowries': cowries,
        'ancestralBeads': ancestralBeads,
        'dailyStreak': dailyStreak,
        'perfectWeekStreak': perfectWeekStreak,
        'tonalMasteryStreak': tonalMasteryStreak,
        'freezeLeft': freezeLeft,
        'tribe': tribe,
        'unlockedBadges': unlockedBadges,
        'activeBoosters': activeBoosters,
        'questProgress': questProgress,
        'lastLogin': lastLogin?.toIso8601String(),
        'ubuntuStreakActive': ubuntuStreakActive,
        'lessonsCompleted': lessonsCompleted,
        'wordsLearned': wordsLearned,
        'languagesLearned': languagesLearned,
        'totalXP': totalXP,
        'currentLanguage': currentLanguage,
        'quizzesCompleted': quizzesCompleted,
        'perfectQuizzes': perfectQuizzes,
        'gamesPlayed': gamesPlayed,
        'polieMessages': polieMessages,
        'storyChaptersRead': storyChaptersRead,
        'voiceContributions': voiceContributions,
      };

  factory UserGamificationModel.fromJson(Map<String, dynamic> json) =>
      UserGamificationModel(
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        levelTitle: json['levelTitle'] as String? ?? 'Stranger at the Village Gate',
        ngwenya: json['ngwenya'] as int? ?? 0,
        cowries: json['cowries'] as int? ?? 0,
        ancestralBeads: json['ancestralBeads'] as int? ?? 0,
        dailyStreak: json['dailyStreak'] as int? ?? 0,
        perfectWeekStreak: json['perfectWeekStreak'] as int? ?? 0,
        tonalMasteryStreak: json['tonalMasteryStreak'] as int? ?? 0,
        freezeLeft: json['freezeLeft'] as int? ?? 2,
        tribe: json['tribe'] as String?,
        unlockedBadges: (json['unlockedBadges'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        activeBoosters: (json['activeBoosters'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        questProgress: (json['questProgress'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'] as String)
            : null,
        ubuntuStreakActive: json['ubuntuStreakActive'] as bool? ?? false,
        lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
        wordsLearned: json['wordsLearned'] as int? ?? 0,
        languagesLearned: json['languagesLearned'] as int? ?? 0,
        totalXP: json['totalXP'] as int? ?? json['xp'] as int? ?? 0,
        currentLanguage: json['currentLanguage'] as String?,
        quizzesCompleted: json['quizzesCompleted'] as int? ?? 0,
        perfectQuizzes: json['perfectQuizzes'] as int? ?? 0,
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        polieMessages: json['polieMessages'] as int? ?? 0,
        storyChaptersRead: json['storyChaptersRead'] as int? ?? 0,
        voiceContributions: json['voiceContributions'] as int? ?? 0,
      );
}

/// African-themed level titles
class LevelTitles {
  static const List<String> titles = [
    'Stranger at the Village Gate', // Level 1
    'Market Apprentice', // Level 10
    'Griot-in-Training', // Level 25
    'Village Storyteller', // Level 50
    'Keeper of Proverbs', // Level 75
    'Elder of Tongues', // Level 100
    'Pan-African Orator', // Level 150
    'Living Legend', // Level 200
    'Immortal Ancestor', // Level 300
  ];

  static const List<int> levelThresholds = [1, 10, 25, 50, 75, 100, 150, 200, 300];

  static String getTitleForLevel(int level) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (level >= levelThresholds[i]) {
        return titles[i];
      }
    }
    return titles[0];
  }

  static int getXPForLevel(int level) {
    // 1000 XP per level (can be adjusted)
    return (level - 1) * 1000;
  }

  static int getLevelFromXP(int xp) {
    return (xp ~/ 1000) + 1;
  }
}

/// XP sources with African context
class XPSources {
  static const Map<String, int> sources = {
    'lesson_complete': 15,
    'perfect_lesson': 30,
    'ai_chat_5min': 20,
    'pronunciation_95plus': 40,
    'story_quest_milestone': 150,
    'help_another_learner': 60, // Answer in forums
    'record_native_phrase': 150, // Community audio contribution
    'market_bargaining_roleplay_win': 200,
    'quiz_complete': 10,
    'game_complete': 15,
    'daily_checkin': 20,
    'perfect_week': 100,
    'unlock_badge': 50,
    'complete_quest_chapter': 500,
    'review': 30, // User submits app review
  };

  static int getXP(String source) {
    return sources[source] ?? 10; // Default 10 XP
  }
}

/// Available tribes for leaderboards
class Tribes {
  static const List<String> allTribes = [
    'Zulu',
    'Yoruba',
    'Igbo',
    'Hausa',
    'Swahili',
    'Amhara',
    'Xhosa',
    'Shona',
    'Twi',
    'Wolof',
    'Somali',
    'Luo',
    'Kikuyu',
    'Oromo',
    'Mandinka',
  ];

  static bool isValidTribe(String tribe) {
    return allTribes.contains(tribe);
  }
}

