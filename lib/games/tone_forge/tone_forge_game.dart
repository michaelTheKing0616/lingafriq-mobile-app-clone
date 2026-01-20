import '../gamekit/game.dart';
import '../gamekit/game_engine.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_difficulty.dart';
import '../../services/polie_game_client.dart';
import 'tone_forge_models.dart';
import 'tone_forge_scoring.dart';
import 'tone_forge_feedback.dart';

/// ToneForge - Flagship game for tonal mastery
/// This is the gold standard implementation that all other games should follow
class ToneForgeGame extends Game<ToneForgeContent, ToneForgeInput> {
  final PolieGameClient polieClient;

  ToneForgeGame({
    required GameEngine engine,
    required this.polieClient,
  }) : super(engine);

  @override
  GameConfig get config => const GameConfig(
        gameId: 'tone_forge',
        displayName: 'Tone Forge',
        defaultCardCount: 10,
        supportsAudio: true,
        supportsVoiceInput: true,
        requiredPermissions: ['microphone'],
      );

  @override
  Future<ToneForgeContent> loadContent(GameSession session) async {
    try {
      final polieContent = await polieClient.generateContent(
        gameId: config.gameId,
        language: session.language,
        difficulty: session.level ?? 'A2',
        userId: session.userId,
        sessionId: session.sessionId,
        previousPerformance: session.performanceProfile,
        learningGoals: ['tones', 'fluency'],
      );

      return ToneForgeContent.fromPolieContent({
        ...polieContent.toJson(),
        'content_id': polieContent.contentId,
      });
    } catch (e) {
      // Return fallback content instead of throwing
      return ToneForgeContent(
        text: 'Loading...',
        targetPitchContour: [0.3, 0.5, 0.7, 0.5, 0.3],
        pitchTolerance: 0.15,
        timingTolerance: 0.2,
        contentId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Future<GameTurnResult> playTurn(
    ToneForgeContent content,
    ToneForgeInput input,
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

/// Factory to create ToneForge game with default engine
class ToneForgeGameFactory {
  static ToneForgeGame create({
    required PolieGameClient polieClient,
    required GameAnimationBridge animationBridge,
  }) {
    final engine = GameEngine(
      scoring: ToneForgeScoringEngine(),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: ToneForgeFeedbackEngine(),
      animation: animationBridge,
    );

    return ToneForgeGame(
      engine: engine,
      polieClient: polieClient,
    );
  }
}

extension PolieGameContentJson on PolieGameContent {
  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'game_id': gameId,
      'language': language,
      'text': text,
      'ipa': ipa,
      'tones': tones,
      'audio_url': audioUrl,
      'cultural_context': culturalContext,
      'difficulty_score': difficultyScore,
      'scoring_rules': scoringRules,
      'animation_cues': animationCues,
      'metadata': metadata,
    };
  }
}

