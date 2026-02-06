import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'avatar_engine.dart';
import 'emotion_system.dart';
import 'personality_system.dart';

/// Avatar Intelligence System
/// 
/// Provides contextual awareness and cross-system synergy for avatars.
/// Avatars respond intelligently to:
/// - Time of day (greeting, energy level)
/// - User progress (encouragement, challenges)  
/// - Streak status (motivation, warnings)
/// - Learning patterns (adaptive personality)

class AvatarIntelligence {
  final Ref _ref;
  
  // User learning context
  int _dailyLessonsCompleted = 0;
  int _currentStreak = 0;
  int _totalXPToday = 0;
  DateTime? _lastActivityTime;
  double _userConfidence = 0.5;
  List<String> _recentMistakes = [];
  List<String> _recentSuccesses = [];
  
  // Personality adaptation
  double _adaptedWarmth = 0.5;
  double _adaptedEnergy = 0.5;
  double _adaptedPatience = 0.5;
  
  AvatarIntelligence(this._ref);
  
  /// Get contextual greeting based on time and user state
  String getContextualGreeting(AvatarPersonality personality) {
    final hour = DateTime.now().hour;
    final baseGreeting = personality.getGreeting();
    
    // Check if returning after absence
    if (_lastActivityTime != null) {
      final hoursSinceActivity = DateTime.now().difference(_lastActivityTime!).inHours;
      
      if (hoursSinceActivity > 24) {
        return 'Welcome back! We\'ve missed you. ${_getStreakMessage()}';
      }
    }
    
    // Time-based energy adjustment
    if (hour >= 6 && hour < 9) {
      return '$baseGreeting Ready for some early morning learning?';
    } else if (hour >= 22 || hour < 6) {
      return '$baseGreeting Night owl studying? Your dedication is admirable!';
    } else if (_totalXPToday >= 100) {
      return '$baseGreeting You\'re on fire today! $_totalXPToday XP already!';
    }
    
    return baseGreeting;
  }
  
  /// Get contextual encouragement based on recent performance
  String getContextualEncouragement(AvatarPersonality personality, {
    required bool wasSuccessful,
    String? topic,
  }) {
    if (wasSuccessful) {
      _recentSuccesses.add(topic ?? 'exercise');
      if (_recentSuccesses.length > 3) {
        return 'You\'re on a roll! ${_recentSuccesses.length} correct in a row!';
      }
      return personality.getEncouragement('success');
    } else {
      _recentMistakes.add(topic ?? 'exercise');
      _recentSuccesses.clear();
      
      // Adapt response based on mistake frequency
      if (_recentMistakes.length >= 3) {
        return 'This is a tricky one! Let\'s slow down and review together.';
      }
      return personality.getEncouragement('mistake');
    }
  }
  
  /// Get recommended emotion based on context
  EmotionState getRecommendedEmotion(AvatarContext context) {
    final emotionSystem = EmotionSystem();
    
    // Adjust based on user confidence and recent performance
    final adjustedConfidence = _userConfidence;
    final recentSuccessRate = _calculateRecentSuccessRate();
    
    // Modify emotion selection based on context
    if (context == AvatarContext.correctAnswer && recentSuccessRate > 0.8) {
      return EmotionState.simple(
        AvatarEmotion.celebrating,
        intensity: EmotionIntensity.strong,
      );
    }
    
    if (context == AvatarContext.incorrectAnswer && recentSuccessRate < 0.4) {
      return EmotionState.blended(
        primary: AvatarEmotion.empathetic,
        secondary: AvatarEmotion.encouraging,
        blend: 0.6,
        intensity: EmotionIntensity.strong,
      );
    }
    
    return emotionSystem.getContextualEmotion(
      context: context,
      userConfidence: adjustedConfidence,
    );
  }
  
  /// Adapt personality traits based on user behavior
  PersonalityTraits getAdaptedTraits(PersonalityTraits baseTraits) {
    // Increase warmth if user is struggling
    if (_calculateRecentSuccessRate() < 0.5) {
      _adaptedWarmth = (baseTraits.warmth + 0.2).clamp(0.0, 1.0);
      _adaptedPatience = (baseTraits.patience + 0.2).clamp(0.0, 1.0);
    }
    
    // Increase energy for users who are doing well
    if (_totalXPToday > 200) {
      _adaptedEnergy = (baseTraits.energy + 0.1).clamp(0.0, 1.0);
    }
    
    // Adjust based on time of day
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) {
      _adaptedEnergy = (baseTraits.energy - 0.2).clamp(0.0, 1.0);
    }
    
    return PersonalityTraits(
      energy: _adaptedEnergy,
      warmth: _adaptedWarmth,
      humor: baseTraits.humor,
      patience: _adaptedPatience,
      culturalAffinity: baseTraits.culturalAffinity,
      expressiveness: baseTraits.expressiveness,
      wisdom: baseTraits.wisdom,
    );
  }
  
  /// Record user activity
  void recordActivity({
    bool wasSuccessful = true,
    int xpGained = 0,
    String? topic,
  }) {
    _lastActivityTime = DateTime.now();
    _totalXPToday += xpGained;
    
    if (wasSuccessful) {
      _dailyLessonsCompleted++;
      _userConfidence = (_userConfidence + 0.05).clamp(0.0, 1.0);
    } else {
      _userConfidence = (_userConfidence - 0.03).clamp(0.0, 1.0);
    }
    
    // Update recent performance tracking
    if (wasSuccessful) {
      _recentSuccesses.add(topic ?? 'activity');
      if (_recentSuccesses.length > 10) {
        _recentSuccesses.removeAt(0);
      }
    } else {
      _recentMistakes.add(topic ?? 'activity');
      if (_recentMistakes.length > 10) {
        _recentMistakes.removeAt(0);
      }
    }
  }
  
  /// Update streak
  void updateStreak(int streak) {
    _currentStreak = streak;
  }
  
  /// Get milestone message for achievements
  String getMilestoneMessage(MilestoneType type, {int? value}) {
    switch (type) {
      case MilestoneType.dailyGoal:
        return 'Daily goal achieved! You\'ve earned a rest.';
      case MilestoneType.weeklyStreak:
        return '7 days strong! You\'re building a powerful habit.';
      case MilestoneType.monthlyStreak:
        return 'A whole month! You are truly dedicated.';
      case MilestoneType.perfectLesson:
        return 'Perfection! Not a single mistake!';
      case MilestoneType.levelUp:
        return 'Level ${value ?? 1}! Your journey continues!';
      case MilestoneType.badgeEarned:
        return 'A new badge to celebrate your achievement!';
      case MilestoneType.firstLesson:
        return 'Your first step on a great journey!';
      case MilestoneType.hundredLessons:
        return '100 lessons! You\'re becoming a true learner!';
    }
  }
  
  /// Get suggestion for what to do next
  String getNextActionSuggestion() {
    if (_dailyLessonsCompleted == 0) {
      return 'Start with a quick warm-up lesson?';
    }
    
    if (_recentMistakes.length > 3) {
      final weakArea = _getMostCommonMistake();
      return 'Let\'s practice more $weakArea to build confidence.';
    }
    
    if (_totalXPToday < 50) {
      return 'A few more exercises to reach your daily goal!';
    }
    
    if (_userConfidence > 0.8) {
      return 'You\'re ready for a challenge! Try a harder level?';
    }
    
    return 'Keep the momentum going with another lesson!';
  }
  
  // Private helpers
  
  double _calculateRecentSuccessRate() {
    final totalRecent = _recentSuccesses.length + _recentMistakes.length;
    if (totalRecent == 0) return 0.5;
    return _recentSuccesses.length / totalRecent;
  }
  
  String _getStreakMessage() {
    if (_currentStreak > 0) {
      return 'Your $_currentStreak day streak is waiting!';
    }
    return 'Let\'s start a new streak today!';
  }
  
  String _getMostCommonMistake() {
    if (_recentMistakes.isEmpty) return 'vocabulary';
    
    final counts = <String, int>{};
    for (final mistake in _recentMistakes) {
      counts[mistake] = (counts[mistake] ?? 0) + 1;
    }
    
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  /// Reset daily stats (call at midnight)
  void resetDaily() {
    _dailyLessonsCompleted = 0;
    _totalXPToday = 0;
    _recentMistakes.clear();
    _recentSuccesses.clear();
  }
}

/// Milestone types for special moments
enum MilestoneType {
  dailyGoal,
  weeklyStreak,
  monthlyStreak,
  perfectLesson,
  levelUp,
  badgeEarned,
  firstLesson,
  hundredLessons,
}

/// Provider for avatar intelligence
final avatarIntelligenceProvider = Provider<AvatarIntelligence>((ref) {
  return AvatarIntelligence(ref);
});

/// Cross-system synergy manager
/// Coordinates avatar behavior across different app systems
class AvatarSynergyManager {
  final Ref _ref;
  final Map<String, DateTime> _recentAchievements = {};
  
  AvatarSynergyManager(this._ref);
  
  /// Called when user completes a game
  Future<void> onGameComplete({
    required String gameId,
    required double accuracy,
    required int xpEarned,
  }) async {
    final intelligence = _ref.read(avatarIntelligenceProvider);
    final engine = _ref.read(avatarEngineProvider);
    
    intelligence.recordActivity(
      wasSuccessful: accuracy >= 0.7,
      xpGained: xpEarned,
      topic: 'game',
    );
    
    // Get Polie to react
    final polie = await engine.getController(AvatarType.polie);
    
    if (accuracy >= 0.9) {
      polie.celebrate();
      polie.startSpeaking(text: intelligence.getMilestoneMessage(MilestoneType.perfectLesson));
    } else if (accuracy >= 0.7) {
      polie.setEmotion(AvatarEmotion.happy, intensity: EmotionIntensity.strong);
    } else {
      polie.setEmotion(AvatarEmotion.encouraging);
      await Future.delayed(const Duration(seconds: 1));
      polie.startSpeaking(text: intelligence.getNextActionSuggestion());
    }
  }
  
  /// Called when user opens AI chat
  Future<void> onChatOpen() async {
    final intelligence = _ref.read(avatarIntelligenceProvider);
    final engine = _ref.read(avatarEngineProvider);
    final personalitySystem = engine.personalitySystem;
    
    final poliePersonality = personalitySystem.getPersonality('polie')!;
    final polie = await engine.getController(AvatarType.polie);
    
    // Contextual greeting
    final greeting = intelligence.getContextualGreeting(poliePersonality);
    polie.wave();
    polie.startSpeaking(text: greeting);
  }
  
  /// Called when user answers a question
  Future<void> onAnswerSubmitted({
    required bool isCorrect,
    required String topic,
  }) async {
    final intelligence = _ref.read(avatarIntelligenceProvider);
    final engine = _ref.read(avatarEngineProvider);
    final personalitySystem = engine.personalitySystem;
    
    final poliePersonality = personalitySystem.getPersonality('polie')!;
    
    intelligence.recordActivity(
      wasSuccessful: isCorrect,
      xpGained: isCorrect ? 10 : 0,
      topic: topic,
    );
    
    final encouragement = intelligence.getContextualEncouragement(
      poliePersonality,
      wasSuccessful: isCorrect,
      topic: topic,
    );
    
    debugPrint('Avatar: $encouragement');
  }
  
  /// Called on achievement unlock
  Future<void> onAchievementUnlock(String achievementId) async {
    // Prevent duplicate celebrations
    final now = DateTime.now();
    if (_recentAchievements[achievementId] != null) {
      final lastTime = _recentAchievements[achievementId]!;
      if (now.difference(lastTime).inSeconds < 5) {
        return;
      }
    }
    _recentAchievements[achievementId] = now;
    
    final engine = _ref.read(avatarEngineProvider);
    final polie = await engine.getController(AvatarType.polie);
    
    polie.celebrate();
    await polie.playReactionSequence(AvatarReaction.levelUp);
  }
}

final avatarSynergyManagerProvider = Provider<AvatarSynergyManager>((ref) {
  return AvatarSynergyManager(ref);
});

// Export the avatarEngineProvider from avatar_providers
final avatarEngineProvider = Provider<AvatarEngine>((ref) {
  return AvatarEngine();
});
