import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/daily_challenges_provider.dart';
import '../providers/milestones_provider.dart';
import '../providers/league_provider.dart';
import '../providers/hearts_provider.dart';
import '../providers/gamification_provider.dart';
import '../widgets/gamification/xp_gain_overlay.dart';
import '../services/sound_effects_service.dart';

/// Gamification Integration Helper
/// 
/// Provides easy-to-use methods for integrating gamification across all screens.
/// 
/// Usage:
/// ```dart
/// // In any ConsumerWidget or ConsumerStatefulWidget:
/// ref.gamify.onLessonComplete(xpEarned: 50);
/// ref.gamify.onQuizComplete(score: 100, isPerfect: true, xpEarned: 75);
/// ref.gamify.onGameComplete(xpEarned: 30);
/// ref.gamify.onWordLearned(count: 5);
/// ```
extension GamificationIntegration on WidgetRef {
  _GamificationHelper get gamify => _GamificationHelper(this);
}

class _GamificationHelper {
  final WidgetRef _ref;

  _GamificationHelper(this._ref);

  /// Call when a lesson is completed
  Future<void> onLessonComplete({
    required int xpEarned,
    int wordsLearned = 0,
    int timeSpentMinutes = 0,
  }) async {
    debugPrint('[Gamification] Lesson complete: XP=$xpEarned, words=$wordsLearned');
    
    // Show XP overlay
    showXPGain(_ref, amount: xpEarned, source: 'Lesson Complete');
    
    // Track daily challenges
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.lessonsComplete, 1);
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    
    if (wordsLearned > 0) {
      _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.wordsLearned, wordsLearned);
    }
    
    if (timeSpentMinutes > 0) {
      _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.timeSpent, timeSpentMinutes);
    }
    
    // Add to league weekly XP
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    
    // Check milestones
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      lessonsCompleted: gamification.lessonsCompleted + 1,
      wordsLearned: gamification.wordsLearned + wordsLearned,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when a quiz is completed
  Future<void> onQuizComplete({
    required int score,
    required int xpEarned,
    bool isPerfect = false,
    int wordsLearned = 0,
  }) async {
    debugPrint('[Gamification] Quiz complete: score=$score, XP=$xpEarned, perfect=$isPerfect');
    
    // Show XP overlay with bonus text for perfect
    showXPGain(
      _ref,
      amount: xpEarned,
      source: 'Quiz Complete',
      bonusText: isPerfect ? '💯 Perfect Score!' : null,
    );
    
    // Track daily challenges
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    
    if (isPerfect) {
      _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.perfectQuiz, 1);
      _ref.read(soundEffectsProvider).play(SoundEffect.perfectScore);
    }
    
    if (wordsLearned > 0) {
      _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.wordsLearned, wordsLearned);
    }
    
    // Add to league weekly XP
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    
    // Check milestones
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      quizzesCompleted: gamification.quizzesCompleted + 1,
      perfectQuizzes: isPerfect ? gamification.perfectQuizzes + 1 : gamification.perfectQuizzes,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when a game is completed
  Future<void> onGameComplete({
    required int xpEarned,
    int wordsLearned = 0,
  }) async {
    debugPrint('[Gamification] Game complete: XP=$xpEarned');
    
    // Show XP overlay
    showXPGain(_ref, amount: xpEarned, source: 'Game Complete');
    
    // Track daily challenges
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.gamesPlayed, 1);
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    
    if (wordsLearned > 0) {
      _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.wordsLearned, wordsLearned);
    }
    
    // Add to league weekly XP
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    
    // Check milestones
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      gamesPlayed: gamification.gamesPlayed + 1,
      wordsLearned: gamification.wordsLearned + wordsLearned,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when words are learned
  Future<void> onWordsLearned({required int count, int xpEarned = 0}) async {
    debugPrint('[Gamification] Words learned: count=$count');
    
    if (xpEarned > 0) {
      showXPGain(_ref, amount: xpEarned, source: 'Words Learned');
      _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
      _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    }
    
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.wordsLearned, count);
    
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      wordsLearned: gamification.wordsLearned + count,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when sending a message to Polie
  Future<void> onPolieMessage({int xpEarned = 5}) async {
    debugPrint('[Gamification] Polie message sent');
    
    if (xpEarned > 0) {
      showXPGain(_ref, amount: xpEarned, source: 'AI Chat');
    }
    
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.chatMessages, 1);
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      polieMessages: gamification.polieMessages + 1,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when completing a story chapter
  Future<void> onStoryChapterComplete({required int xpEarned}) async {
    debugPrint('[Gamification] Story chapter complete: XP=$xpEarned');
    
    showXPGain(_ref, amount: xpEarned, source: 'Story Chapter');
    
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.storyChapters, 1);
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      storyChaptersRead: gamification.storyChaptersRead + 1,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when reading cultural content
  Future<void> onCulturalContentRead({int xpEarned = 10}) async {
    debugPrint('[Gamification] Cultural content read');
    
    if (xpEarned > 0) {
      showXPGain(_ref, amount: xpEarned, source: 'Cultural Article');
    }
    
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.culturalContent, 1);
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
  }

  /// Call when submitting a voice recording
  Future<void> onVoiceRecording({int xpEarned = 15}) async {
    debugPrint('[Gamification] Voice recording submitted');
    
    if (xpEarned > 0) {
      showXPGain(_ref, amount: xpEarned, source: 'Voice Contribution');
    }
    
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.voiceRecordings, 1);
    _ref.read(dailyChallengesProvider.notifier).updateProgress(ChallengeType.xpEarned, xpEarned);
    _ref.read(leagueProvider.notifier).addWeeklyXP(xpEarned);
    
    final gamification = _ref.read(gamificationProvider);
    await _ref.read(milestonesProvider.notifier).checkProgressMilestones(
      voiceContributions: gamification.voiceContributions + 1,
      totalXP: gamification.totalXP + xpEarned,
    );
  }

  /// Call when making a mistake (for hearts system)
  /// Returns true if user can continue, false if out of hearts
  bool onMistake() {
    final heartsState = _ref.read(heartsProvider);
    
    // If challenge mode is off or unlimited, always continue
    if (!heartsState.challengeModeEnabled || heartsState.isUnlimited) {
      return true;
    }
    
    return _ref.read(heartsProvider.notifier).useHeart();
  }

  /// Call to check if user has hearts to continue
  bool get canContinue {
    final heartsState = _ref.read(heartsProvider);
    return !heartsState.challengeModeEnabled || heartsState.isUnlimited || heartsState.currentHearts > 0;
  }

  /// Play sound effects
  void playCorrect() => _ref.read(soundEffectsProvider).playCorrect();
  void playIncorrect() => _ref.read(soundEffectsProvider).playIncorrect();
  void playCelebration() => _ref.read(soundEffectsProvider).playCelebration();
  void playLevelUp() => _ref.read(soundEffectsProvider).playLevelUp();
  void playBadgeUnlock() => _ref.read(soundEffectsProvider).playBadgeUnlock();
}

/// Mixin for screens that need gamification
/// 
/// Add this mixin to StatefulWidget state classes for easy access:
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen> with GamificationMixin {
///   void _onComplete() {
///     gamify.onLessonComplete(xpEarned: 50);
///   }
/// }
/// ```
mixin GamificationMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  _GamificationHelper get gamify => _GamificationHelper(ref);
}

