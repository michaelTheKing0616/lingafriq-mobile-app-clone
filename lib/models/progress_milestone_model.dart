import 'package:flutter/material.dart';
import '../utils/pan_african_design_system.dart';

/// Types of progress milestones
enum MilestoneType {
  // Learning milestones
  firstWord,            // Learn your first word
  tenWords,             // Learn 10 words
  fiftyWords,           // Learn 50 words
  hundredWords,         // Learn 100 words
  fiveHundredWords,     // Learn 500 words
  thousandWords,        // Learn 1000 words
  
  // XP milestones
  firstXP,              // Earn your first XP
  hundredXP,            // Earn 100 XP
  fiveHundredXP,        // Earn 500 XP
  thousandXP,           // Earn 1000 XP
  fiveThousandXP,       // Earn 5000 XP
  tenThousandXP,        // Earn 10000 XP
  
  // Streak milestones
  firstStreak,          // First day streak
  weekStreak,           // 7 day streak
  monthStreak,          // 30 day streak
  quarterStreak,        // 90 day streak
  yearStreak,           // 365 day streak
  
  // Lesson milestones
  firstLesson,          // Complete first lesson
  tenLessons,           // Complete 10 lessons
  fiftyLessons,         // Complete 50 lessons
  hundredLessons,       // Complete 100 lessons
  
  // Quiz milestones
  firstQuiz,            // Complete first quiz
  firstPerfectQuiz,     // Get first perfect score
  tenPerfectQuizzes,    // Get 10 perfect scores
  
  // Social milestones
  joinedTribe,          // Join a tribe
  firstFriend,          // Add first friend
  firstChatMessage,     // Send first chat message
  firstGift,            // Send first gift
  
  // Game milestones
  firstGame,            // Play first game
  tenGames,             // Play 10 games
  fiftyGames,           // Play 50 games
  
  // Story milestones
  firstStoryChapter,    // Complete first story chapter
  completeStory,        // Complete a full story
  
  // Badge milestones
  firstBadge,           // Earn first badge
  tenBadges,            // Earn 10 badges
  twentyFiveBadges,     // Earn 25 badges
  
  // Level milestones
  levelFive,            // Reach level 5
  levelTen,             // Reach level 10
  levelTwentyFive,      // Reach level 25
  levelFifty,           // Reach level 50
  levelHundred,         // Reach level 100
  
  // AI Chat milestones
  firstPolieChat,       // First chat with Polie
  hundredPolieMessages, // 100 messages with Polie
  
  // Contribution milestones
  firstVoiceContrib,    // First voice contribution
  tenVoiceContribs,     // 10 voice contributions
}

/// Milestone definition
class Milestone {
  final MilestoneType type;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final int cowriesReward;
  final Color color;
  final bool isSecret; // Hidden until achieved

  const Milestone({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.cowriesReward,
    this.color = const Color(0xFFF7CB46),
    this.isSecret = false,
  });
}

/// All milestone definitions
class MilestoneDefinitions {
  static const Map<MilestoneType, Milestone> milestones = {
    // Learning milestones
    MilestoneType.firstWord: Milestone(
      type: MilestoneType.firstWord,
      title: 'First Steps',
      description: 'Learn your first word in an African language',
      emoji: '🌱',
      xpReward: 25,
      cowriesReward: 10,
    ),
    MilestoneType.tenWords: Milestone(
      type: MilestoneType.tenWords,
      title: 'Word Collector',
      description: 'Learn 10 words',
      emoji: '📚',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.fiftyWords: Milestone(
      type: MilestoneType.fiftyWords,
      title: 'Vocabulary Builder',
      description: 'Learn 50 words',
      emoji: '📖',
      xpReward: 100,
      cowriesReward: 50,
    ),
    MilestoneType.hundredWords: Milestone(
      type: MilestoneType.hundredWords,
      title: 'Century Club',
      description: 'Learn 100 words',
      emoji: '💯',
      xpReward: 200,
      cowriesReward: 100,
    ),
    MilestoneType.fiveHundredWords: Milestone(
      type: MilestoneType.fiveHundredWords,
      title: 'Word Master',
      description: 'Learn 500 words',
      emoji: '🎓',
      xpReward: 500,
      cowriesReward: 250,
    ),
    MilestoneType.thousandWords: Milestone(
      type: MilestoneType.thousandWords,
      title: 'Linguistic Legend',
      description: 'Learn 1000 words',
      emoji: '👑',
      xpReward: 1000,
      cowriesReward: 500,
    ),
    
    // XP milestones
    MilestoneType.firstXP: Milestone(
      type: MilestoneType.firstXP,
      title: 'Getting Started',
      description: 'Earn your first XP',
      emoji: '⭐',
      xpReward: 10,
      cowriesReward: 5,
    ),
    MilestoneType.hundredXP: Milestone(
      type: MilestoneType.hundredXP,
      title: 'Rising Star',
      description: 'Earn 100 XP total',
      emoji: '🌟',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.fiveHundredXP: Milestone(
      type: MilestoneType.fiveHundredXP,
      title: 'XP Hunter',
      description: 'Earn 500 XP total',
      emoji: '✨',
      xpReward: 100,
      cowriesReward: 50,
    ),
    MilestoneType.thousandXP: Milestone(
      type: MilestoneType.thousandXP,
      title: 'Thousand Strong',
      description: 'Earn 1000 XP total',
      emoji: '💫',
      xpReward: 200,
      cowriesReward: 100,
    ),
    MilestoneType.fiveThousandXP: Milestone(
      type: MilestoneType.fiveThousandXP,
      title: 'XP Champion',
      description: 'Earn 5000 XP total',
      emoji: '🏆',
      xpReward: 500,
      cowriesReward: 250,
    ),
    MilestoneType.tenThousandXP: Milestone(
      type: MilestoneType.tenThousandXP,
      title: 'XP Legend',
      description: 'Earn 10000 XP total',
      emoji: '🏅',
      xpReward: 1000,
      cowriesReward: 500,
    ),
    
    // Streak milestones
    MilestoneType.firstStreak: Milestone(
      type: MilestoneType.firstStreak,
      title: 'Fire Starter',
      description: 'Start your learning streak',
      emoji: '🔥',
      xpReward: 25,
      cowriesReward: 10,
    ),
    MilestoneType.weekStreak: Milestone(
      type: MilestoneType.weekStreak,
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      emoji: '📅',
      xpReward: 100,
      cowriesReward: 50,
    ),
    MilestoneType.monthStreak: Milestone(
      type: MilestoneType.monthStreak,
      title: 'Month Master',
      description: 'Maintain a 30-day streak',
      emoji: '🗓️',
      xpReward: 300,
      cowriesReward: 150,
    ),
    MilestoneType.quarterStreak: Milestone(
      type: MilestoneType.quarterStreak,
      title: 'Quarterly Champion',
      description: 'Maintain a 90-day streak',
      emoji: '🎯',
      xpReward: 750,
      cowriesReward: 400,
    ),
    MilestoneType.yearStreak: Milestone(
      type: MilestoneType.yearStreak,
      title: 'Year of Dedication',
      description: 'Maintain a 365-day streak',
      emoji: '🌟',
      xpReward: 3650,
      cowriesReward: 2000,
      isSecret: true,
    ),
    
    // Lesson milestones
    MilestoneType.firstLesson: Milestone(
      type: MilestoneType.firstLesson,
      title: 'First Lesson',
      description: 'Complete your first lesson',
      emoji: '📝',
      xpReward: 25,
      cowriesReward: 10,
    ),
    MilestoneType.tenLessons: Milestone(
      type: MilestoneType.tenLessons,
      title: 'Dedicated Learner',
      description: 'Complete 10 lessons',
      emoji: '📚',
      xpReward: 75,
      cowriesReward: 40,
    ),
    MilestoneType.fiftyLessons: Milestone(
      type: MilestoneType.fiftyLessons,
      title: 'Studious Scholar',
      description: 'Complete 50 lessons',
      emoji: '🎒',
      xpReward: 250,
      cowriesReward: 125,
    ),
    MilestoneType.hundredLessons: Milestone(
      type: MilestoneType.hundredLessons,
      title: 'Lesson Legend',
      description: 'Complete 100 lessons',
      emoji: '🎓',
      xpReward: 500,
      cowriesReward: 250,
    ),
    
    // Quiz milestones
    MilestoneType.firstQuiz: Milestone(
      type: MilestoneType.firstQuiz,
      title: 'Quiz Taker',
      description: 'Complete your first quiz',
      emoji: '❓',
      xpReward: 25,
      cowriesReward: 10,
    ),
    MilestoneType.firstPerfectQuiz: Milestone(
      type: MilestoneType.firstPerfectQuiz,
      title: 'Perfectionist',
      description: 'Get a perfect score on a quiz',
      emoji: '💯',
      xpReward: 75,
      cowriesReward: 40,
    ),
    MilestoneType.tenPerfectQuizzes: Milestone(
      type: MilestoneType.tenPerfectQuizzes,
      title: 'Perfect Ten',
      description: 'Get 10 perfect quiz scores',
      emoji: '🌟',
      xpReward: 300,
      cowriesReward: 150,
    ),
    
    // Social milestones
    MilestoneType.joinedTribe: Milestone(
      type: MilestoneType.joinedTribe,
      title: 'Tribal Member',
      description: 'Join a learning tribe',
      emoji: '🏘️',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.firstFriend: Milestone(
      type: MilestoneType.firstFriend,
      title: 'Making Friends',
      description: 'Add your first friend',
      emoji: '🤝',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.firstChatMessage: Milestone(
      type: MilestoneType.firstChatMessage,
      title: 'Communicator',
      description: 'Send your first chat message',
      emoji: '💬',
      xpReward: 25,
      cowriesReward: 10,
    ),
    MilestoneType.firstGift: Milestone(
      type: MilestoneType.firstGift,
      title: 'Generous Soul',
      description: 'Send your first gift to a friend',
      emoji: '🎁',
      xpReward: 75,
      cowriesReward: 40,
    ),
    
    // Game milestones
    MilestoneType.firstGame: Milestone(
      type: MilestoneType.firstGame,
      title: 'Game On',
      description: 'Play your first language game',
      emoji: '🎮',
      xpReward: 25,
      cowriesReward: 10,
    ),
    MilestoneType.tenGames: Milestone(
      type: MilestoneType.tenGames,
      title: 'Gamer',
      description: 'Play 10 language games',
      emoji: '🕹️',
      xpReward: 75,
      cowriesReward: 40,
    ),
    MilestoneType.fiftyGames: Milestone(
      type: MilestoneType.fiftyGames,
      title: 'Game Master',
      description: 'Play 50 language games',
      emoji: '👾',
      xpReward: 250,
      cowriesReward: 125,
    ),
    
    // Story milestones
    MilestoneType.firstStoryChapter: Milestone(
      type: MilestoneType.firstStoryChapter,
      title: 'Story Begins',
      description: 'Complete your first story chapter',
      emoji: '📖',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.completeStory: Milestone(
      type: MilestoneType.completeStory,
      title: 'Story Complete',
      description: 'Complete an entire story',
      emoji: '📕',
      xpReward: 200,
      cowriesReward: 100,
    ),
    
    // Badge milestones
    MilestoneType.firstBadge: Milestone(
      type: MilestoneType.firstBadge,
      title: 'Badge Collector',
      description: 'Earn your first badge',
      emoji: '🏷️',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.tenBadges: Milestone(
      type: MilestoneType.tenBadges,
      title: 'Badge Hunter',
      description: 'Earn 10 badges',
      emoji: '🎖️',
      xpReward: 200,
      cowriesReward: 100,
    ),
    MilestoneType.twentyFiveBadges: Milestone(
      type: MilestoneType.twentyFiveBadges,
      title: 'Badge Master',
      description: 'Earn 25 badges',
      emoji: '🏅',
      xpReward: 500,
      cowriesReward: 250,
    ),
    
    // Level milestones
    MilestoneType.levelFive: Milestone(
      type: MilestoneType.levelFive,
      title: 'Level 5',
      description: 'Reach level 5',
      emoji: '5️⃣',
      xpReward: 100,
      cowriesReward: 50,
    ),
    MilestoneType.levelTen: Milestone(
      type: MilestoneType.levelTen,
      title: 'Level 10',
      description: 'Reach level 10',
      emoji: '🔟',
      xpReward: 250,
      cowriesReward: 125,
    ),
    MilestoneType.levelTwentyFive: Milestone(
      type: MilestoneType.levelTwentyFive,
      title: 'Level 25',
      description: 'Reach level 25',
      emoji: '🌟',
      xpReward: 500,
      cowriesReward: 250,
    ),
    MilestoneType.levelFifty: Milestone(
      type: MilestoneType.levelFifty,
      title: 'Level 50',
      description: 'Reach level 50',
      emoji: '⭐',
      xpReward: 1000,
      cowriesReward: 500,
    ),
    MilestoneType.levelHundred: Milestone(
      type: MilestoneType.levelHundred,
      title: 'Level 100',
      description: 'Reach level 100',
      emoji: '💯',
      xpReward: 2500,
      cowriesReward: 1250,
      isSecret: true,
    ),
    
    // AI Chat milestones
    MilestoneType.firstPolieChat: Milestone(
      type: MilestoneType.firstPolieChat,
      title: 'Meeting Polie',
      description: 'Have your first conversation with Polie',
      emoji: '🤖',
      xpReward: 50,
      cowriesReward: 25,
    ),
    MilestoneType.hundredPolieMessages: Milestone(
      type: MilestoneType.hundredPolieMessages,
      title: 'Polie\'s Friend',
      description: 'Send 100 messages to Polie',
      emoji: '💭',
      xpReward: 200,
      cowriesReward: 100,
    ),
    
    // Contribution milestones
    MilestoneType.firstVoiceContrib: Milestone(
      type: MilestoneType.firstVoiceContrib,
      title: 'Voice Contributor',
      description: 'Submit your first voice contribution',
      emoji: '🎙️',
      xpReward: 100,
      cowriesReward: 50,
    ),
    MilestoneType.tenVoiceContribs: Milestone(
      type: MilestoneType.tenVoiceContribs,
      title: 'Voice Champion',
      description: 'Submit 10 voice contributions',
      emoji: '🎤',
      xpReward: 500,
      cowriesReward: 250,
    ),
  };

  static Milestone? getMilestone(MilestoneType type) => milestones[type];
  
  static List<Milestone> getAllMilestones() => milestones.values.toList();
  
  static List<Milestone> getVisibleMilestones() => 
      milestones.values.where((m) => !m.isSecret).toList();
}

/// User's achieved milestones
class UserMilestones {
  final Set<MilestoneType> achieved;
  final DateTime? lastAchieved;
  final Map<MilestoneType, DateTime> achievedDates;

  UserMilestones({
    Set<MilestoneType>? achieved,
    this.lastAchieved,
    Map<MilestoneType, DateTime>? achievedDates,
  }) : achieved = achieved ?? {},
       achievedDates = achievedDates ?? {};

  bool hasAchieved(MilestoneType type) => achieved.contains(type);

  int get totalAchieved => achieved.length;

  int get totalRewardsXP => achieved.fold(0, (sum, type) {
    final milestone = MilestoneDefinitions.getMilestone(type);
    return sum + (milestone?.xpReward ?? 0);
  });

  int get totalRewardsCowries => achieved.fold(0, (sum, type) {
    final milestone = MilestoneDefinitions.getMilestone(type);
    return sum + (milestone?.cowriesReward ?? 0);
  });

  UserMilestones copyWith({
    Set<MilestoneType>? achieved,
    DateTime? lastAchieved,
    Map<MilestoneType, DateTime>? achievedDates,
  }) {
    return UserMilestones(
      achieved: achieved ?? this.achieved,
      lastAchieved: lastAchieved ?? this.lastAchieved,
      achievedDates: achievedDates ?? this.achievedDates,
    );
  }

  Map<String, dynamic> toJson() => {
    'achieved': achieved.map((m) => m.name).toList(),
    'lastAchieved': lastAchieved?.toIso8601String(),
    'achievedDates': achievedDates.map(
      (k, v) => MapEntry(k.name, v.toIso8601String()),
    ),
  };

  factory UserMilestones.fromJson(Map<String, dynamic> json) {
    final achievedList = (json['achieved'] as List<dynamic>?)
        ?.map((name) => MilestoneType.values.firstWhere((m) => m.name == name))
        .toSet() ?? {};
    
    final achievedDates = (json['achievedDates'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(
        MilestoneType.values.firstWhere((m) => m.name == k),
        DateTime.parse(v as String),
      ),
    ) ?? {};

    return UserMilestones(
      achieved: achievedList,
      lastAchieved: json['lastAchieved'] != null 
          ? DateTime.parse(json['lastAchieved'] as String)
          : null,
      achievedDates: achievedDates,
    );
  }
}

