import '../gamekit/game.dart';
import '../gamekit/game_engine.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_difficulty.dart';
import '../../services/polie_game_client.dart';
import 'drum_rhythm_models.dart';
import 'drum_rhythm_scoring.dart';
import 'drum_rhythm_feedback.dart';

/// Drum Rhythm game - Migrated to GameKit
class DrumRhythmGame extends Game<DrumRhythmContent, DrumRhythmInput> {
  final PolieGameClient polieClient;

  DrumRhythmGame({
    required GameEngine engine,
    required this.polieClient,
  }) : super(engine);

  @override
  GameConfig get config => const GameConfig(
        gameId: 'drum_rhythm_shadowing',
        displayName: 'Drum Rhythm Shadowing',
        defaultCardCount: 5,
        supportsAudio: true,
        supportsVoiceInput: false,
      );

  @override
  Future<DrumRhythmContent> loadContent(GameSession session) async {
    try {
      final polieContent = await polieClient.generateContent(
        gameId: config.gameId,
        language: session.language,
        difficulty: session.level ?? 'A2',
        userId: session.userId,
        sessionId: session.sessionId,
        previousPerformance: session.performanceProfile,
        learningGoals: ['rhythm', 'cultural_context'],
      );

      return DrumRhythmContent.fromPolieContent({
        'pattern': polieContent.metadata?['pattern'] ?? 'DUM da-da DUM',
        'context': polieContent.culturalContext ?? polieContent.metadata?['context'] ?? '',
        'content_id': polieContent.contentId,
      });
    } catch (e) {
      // Return fallback content
      return DrumRhythmContent(
        pattern: 'DUM da-da DUM',
        context: 'Traditional rhythm pattern',
        correctWord: 'dance',
        options: ['dance', 'greeting', 'farewell', 'celebration', 'work'],
        contentId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Future<GameTurnResult> playTurn(
    DrumRhythmContent content,
    DrumRhythmInput input,
    GameSession session,
  ) async {
    final context = GameTurnContext(
      content: content,
      input: input,
      session: session,
    );

    return await engine.resolve(context);
  }
}

/// Factory to create Drum Rhythm game
class DrumRhythmGameFactory {
  static DrumRhythmGame create({
    required PolieGameClient polieClient,
    required GameAnimationBridge animationBridge,
  }) {
    final engine = GameEngine(
      scoring: DrumRhythmScoringEngine(polieClient: polieClient),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: DrumRhythmFeedbackEngine(),
      animation: animationBridge,
    );

    return DrumRhythmGame(
      engine: engine,
      polieClient: polieClient,
    );
  }
}

