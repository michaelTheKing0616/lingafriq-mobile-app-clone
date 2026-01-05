import '../gamekit/game.dart';
import '../gamekit/game_engine.dart';
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_difficulty.dart';
import '../gamekit/game_feedback.dart';
import '../gamekit/game_scoring.dart';
import '../../services/polie_game_client.dart';
import '../../services/rive_gamification_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Helper to create games with standard GameKit setup
class GameFactoryHelper {
  static GameEngine createStandardEngine(WidgetRef ref) {
    final riveService = ref.read(riveGamificationServiceProvider);
    final animationBridge = GameAnimationBridge(
      guideController: riveService.controller,
    );

    return GameEngine(
      scoring: DefaultGameScoringEngine(),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: DefaultGameFeedbackEngine(),
      animation: animationBridge,
    );
  }

  static PolieGameClient createPolieClient() {
    return PolieGameClient();
  }
}

