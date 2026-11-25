import '../gamekit/game.dart';
import '../gamekit/game_engine.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_difficulty.dart';
import '../../services/polie_game_client.dart';
import 'proverb_unlocker_catalog.dart';
import 'proverb_unlocker_models.dart';
import 'proverb_unlocker_scoring.dart';
import 'proverb_unlocker_feedback.dart';

/// GameKit proverb unlocker. Proverb text is the harvested live catalog.
/// [polieClient] is kept so [GameEngineService] can construct the game.
/// The played path does not ask Polie for a proverb.
class ProverbUnlockerGame extends Game<ProverbUnlockerContent, ProverbUnlockerInput> {
  final PolieGameClient polieClient;

  ProverbUnlockerGame({
    required GameEngine engine,
    required this.polieClient,
  }) : super(engine);

  @override
  GameConfig get config => const GameConfig(
        gameId: 'proverb_unlocker',
        displayName: 'Proverb Unlocker',
        defaultCardCount: 6,
        supportsAudio: false,
        supportsVoiceInput: false,
      );

  @override
  Future<ProverbUnlockerContent> loadContent(GameSession session) async {
    final raw = session.metadata['seed'];
    final seed = raw is int
        ? raw
        : raw is num
            ? raw.toInt()
            : proverbUnlockerStableSeed(session.language, session.level);
    final roundRaw = session.metadata['round_index'];
    final roundIndex = roundRaw is int
        ? roundRaw
        : roundRaw is num
            ? roundRaw.toInt()
            : 0;
    final deal = dealProverbUnlocker(
      seed: seed,
      language: session.language,
      roundIndex: roundIndex,
    );
    return ProverbUnlockerContent.fromDeal(deal);
  }

  @override
  Future<GameTurnResult> playTurn(
    ProverbUnlockerContent content,
    ProverbUnlockerInput input,
    GameSession session,
  ) async {
    final context = GameTurnContext(
      content: content,
      input: input,
      session: session,
    );

    return engine.resolve(context);
  }
}

/// Factory to create ProverbUnlocker game
class ProverbUnlockerGameFactory {
  static ProverbUnlockerGame create({
    required PolieGameClient polieClient,
    required GameAnimationBridge animationBridge,
  }) {
    final engine = GameEngine(
      scoring: ProverbUnlockerScoringEngine(polieClient: polieClient),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: ProverbUnlockerFeedbackEngine(),
      animation: animationBridge,
    );

    return ProverbUnlockerGame(
      engine: engine,
      polieClient: polieClient,
    );
  }
}
