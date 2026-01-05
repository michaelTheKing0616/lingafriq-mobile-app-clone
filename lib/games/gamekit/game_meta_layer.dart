import '../../models/cultural_mastery_profile.dart';
import '../../models/game_streak.dart';
import '../../services/cultural_mastery_service.dart';
import 'game_result.dart';

/// Meta-game layer - tracks streaks, mastery, badges
/// This is what makes the app addictive
class GameMetaLayer {
  final CulturalMasteryService masteryService;

  GameMetaLayer({required this.masteryService});

  /// Update meta-game state after a turn
  Future<MetaGameUpdate> updateAfterTurn({
    required String userId,
    required String language,
    required String gameId,
    required GameTurnResult result,
  }) async {
    // Update mastery profile
    final learningSignal = result.feedback.metadata?['learning_signal'] as Map<String, dynamic>?;
    final signalValue = learningSignal?.values.first as num? ?? 0.0;
    
    final mastery = await masteryService.updateMastery(
      userId: userId,
      language: language,
      gameId: gameId,
      accuracy: result.score.accuracy,
      learningSignal: signalValue.toDouble(),
    );

    // Update streak if correct
    GameStreak streak;
    if (result.score.isCorrect) {
      streak = await masteryService.incrementStreak(
        userId: userId,
        language: language,
      );
    } else {
      streak = await masteryService.getStreak(
        userId: userId,
        language: language,
      );
    }

    // Check for badges/unlocks
    final badges = _checkBadges(mastery, streak, result);

    return MetaGameUpdate(
      mastery: mastery,
      streak: streak,
      badges: badges,
    );
  }

  List<String> _checkBadges(
    CulturalMasteryProfile mastery,
    GameStreak streak,
    GameTurnResult result,
  ) {
    final badges = <String>[];

    // Streak badges
    if (streak.currentStreak == 7) {
      badges.add('week_warrior');
    } else if (streak.currentStreak == 30) {
      badges.add('month_master');
    } else if (streak.currentStreak == 100) {
      badges.add('century_champion');
    }

    // Mastery badges
    if (mastery.overallMastery >= 0.8) {
      badges.add('cultural_fluent');
    }
    if (mastery.tones >= 0.9) {
      badges.add('tone_master');
    }
    if (mastery.proverbDepth >= 0.9) {
      badges.add('wisdom_keeper');
    }

    // Perfect score badge
    if (result.score.isPerfect) {
      badges.add('perfectionist');
    }

    return badges;
  }
}

/// Meta-game update result
class MetaGameUpdate {
  final CulturalMasteryProfile mastery;
  final GameStreak streak;
  final List<String> badges;

  MetaGameUpdate({
    required this.mastery,
    required this.streak,
    this.badges = const [],
  });
}

