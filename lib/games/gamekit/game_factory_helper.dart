import '../gamekit/game_engine.dart';
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_difficulty.dart';
import '../gamekit/game_feedback.dart';
import '../gamekit/game_scoring.dart';
import '../gamekit/batch_game_factory.dart';
import '../../models/game/game_content_models.dart';
import '../../services/offline/lexicon_pack_service.dart';
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

  /// Entry point for screens: lexicon pool only (no legacy bundled seed file).
  static Future<GameLexiconPoolBuildResult> buildLexiconWordPool(
    GameLexiconPoolRequest request, {
    GameLexiconPoolFetch? fetch,
    LexiconPackService? packService,
  }) {
    return BatchGameFactory.buildLexiconWordPool(
      request,
      fetch: fetch,
      packService: packService,
    );
  }
}

