import 'game_turn_context.dart';

/// P8-907 / EP-§10.2-12–13 — GameKit never gates play on energy or hearts, and
/// never issues randomised loot-box rewards; payouts derive from [GameScore] only.
abstract final class GameKitRewardPolicy {
  static const bool allowsEnergyOrHeartGate = false;
  static const bool allowsRandomLootMechanic = false;
}

/// Abstract scoring engine - each game can implement custom scoring
abstract class GameScoringEngine {
  Future<GameScore> score(GameTurnContext context);
}

/// Default scoring engine - can be used by simple games
class DefaultGameScoringEngine implements GameScoringEngine {
  @override
  Future<GameScore> score(GameTurnContext context) async {
    // Default implementation - games should override
    return GameScore(
      accuracy: 0.5,
      isPerfect: false,
      isFail: false,
    );
  }
}

/// Game score result
class GameScore {
  final double accuracy; // 0.0 to 1.0
  final bool isPerfect;
  final bool isFail;
  final Map<String, dynamic>? details; // Game-specific scoring details

  GameScore({
    required this.accuracy,
    required this.isPerfect,
    required this.isFail,
    this.details,
  });

  bool get isCorrect => accuracy >= 0.6; // Threshold for "correct"
  bool get isPartial => accuracy >= 0.4 && accuracy < 0.6;

  factory GameScore.correct({double accuracy = 1.0, bool perfect = true}) {
    return GameScore(
      accuracy: accuracy,
      isPerfect: perfect,
      isFail: false,
    );
  }

  factory GameScore.incorrect({double accuracy = 0.0, bool fail = true}) {
    return GameScore(
      accuracy: accuracy,
      isPerfect: false,
      isFail: fail,
    );
  }
}

/// Server-parity preview for GameKit session rewards (P8-909; authoritative value is claim response).
int previewGameSessionXp({
  required int correctCount,
  required int totalTurns,
  required int durationMs,
}) {
  if (totalTurns <= 0) return 0;
  final accuracy = correctCount / totalTurns;
  const baseXp = 10;
  final accuracyBonus = (accuracy * 20).round();
  final speedBonus = durationMs < 30000 ? 10 : (durationMs < 60000 ? 5 : 0);
  final perfectBonus = accuracy >= 1.0 ? 25 : 0;
  return baseXp + accuracyBonus + speedBonus + perfectBonus;
}

