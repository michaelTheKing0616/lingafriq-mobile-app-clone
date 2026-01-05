import 'game_turn_context.dart';
import 'game_result.dart';
import 'game_scoring.dart';

/// Abstract difficulty engine - adjusts difficulty based on performance
abstract class GameDifficultyEngine {
  GameDifficultyUpdate adjust(GameTurnContext context, GameScore score);
}

/// Default difficulty engine with adaptive logic
class DefaultGameDifficultyEngine implements GameDifficultyEngine {
  @override
  GameDifficultyUpdate adjust(GameTurnContext context, GameScore score) {
    final session = context.session;
    final streak = session.streak;
    final recentAccuracy = session.accuracy;

    // Increase difficulty if doing well
    if (score.isPerfect && streak >= 3 && recentAccuracy > 0.85) {
      return GameDifficultyUpdate.increase();
    }

    // Decrease difficulty if struggling
    if (score.isFail && streak == 0 && recentAccuracy < 0.5) {
      return GameDifficultyUpdate.decrease();
    }

    // Maintain current difficulty
    return GameDifficultyUpdate.maintain();
  }
}

/// Difficulty update result
class GameDifficultyUpdate {
  final String action; // 'increase', 'decrease', 'maintain'
  final double? newLevel; // Optional new difficulty level
  final Map<String, dynamic>? metadata;

  GameDifficultyUpdate({
    required this.action,
    this.newLevel,
    this.metadata,
  });

  factory GameDifficultyUpdate.increase({double? level}) {
    return GameDifficultyUpdate(
      action: 'increase',
      newLevel: level,
    );
  }

  factory GameDifficultyUpdate.decrease({double? level}) {
    return GameDifficultyUpdate(
      action: 'decrease',
      newLevel: level,
    );
  }

  factory GameDifficultyUpdate.maintain() {
    return GameDifficultyUpdate(action: 'maintain');
  }
}

