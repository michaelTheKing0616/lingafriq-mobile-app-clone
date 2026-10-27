import 'game_feedback.dart';
import 'game_difficulty.dart';
import 'game_scoring.dart';
import 'game_engine.dart';
import 'game_session.dart';
import 'game_turn_context.dart';
import '../../models/game/game_session_model.dart' as backend;
import '../../learning/learner_model/learner_model_service.dart';
import '../../learning/learner_model/error_taxonomy.dart';
import '../../services/learning/spaced_repetition_service.dart';

/// Complete result of a game turn
class GameTurnResult {
  final GameScore score;
  final GameFeedback feedback;
  final GameDifficultyUpdate difficultyUpdate;
  final DateTime timestamp;

  GameTurnResult({
    required this.score,
    required this.feedback,
    required this.difficultyUpdate,
    required this.timestamp,
  });

  /// Convert to backend GameTurn model
  backend.GameTurn toGameTurn({required String cardId}) {
    return backend.GameTurn(
      cardId: cardId,
      result: score.isCorrect ? backend.GameResult.correct : backend.GameResult.incorrect,
      durationMs: 0, // Should be set by caller
      confidence: score.accuracy,
      feedback: {
        'message': feedback.message,
        'animation_event': feedback.animationEvent.name,
        'accuracy': score.accuracy,
        'is_perfect': score.isPerfect,
        'is_fail': score.isFail,
      },
    );
  }
}

/// Writes GameKit turn outcomes to the learner graph and SRS (P8-901).
class GameKitLearnerGraphWriter {
  GameKitLearnerGraphWriter({
    LearnerModelService? learnerModel,
    SpacedRepetitionService? spacedRepetition,
  })  : _learnerModel = learnerModel ?? LearnerModelService.instance,
        _spacedRepetition = spacedRepetition ?? SpacedRepetitionService();

  final LearnerModelService _learnerModel;
  final SpacedRepetitionService _spacedRepetition;

  final List<({String userId, String itemId, bool wasCorrect, double accuracy})>
      _pendingSrs = [];

  /// Resolves item and skill ids for a turn.
  static ({String itemId, String skillId, List<String> errorTypeIds}) idsForTurn(
    GameTurnContext context,
    GameTurnResult result,
  ) {
    final meta = context.metadata ?? {};
    final itemId = (meta['itemId'] as String?) ??
        context.queuedItemId ??
        (meta['skillId'] as String?) ??
        'unknown_item';
    final skillId = (meta['skillId'] as String?) ?? itemId;
    final errorTypeIds = (meta['errorTypeIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((id) => ErrorType.byId(id) != null)
            .toList() ??
        (result.score.isCorrect
            ? const <String>[]
            : [
                gameKitInferWrongAnswerErrorType(
                  metadata: meta,
                  gameCategory: meta['gameCategory'] as String?,
                  languageCode: context.session.language,
                ),
              ]);
    return (itemId: itemId, skillId: skillId, errorTypeIds: errorTypeIds);
  }

  /// Records learner-graph + SRS updates before the next turn may start.
  Future<GameSession> recordTurn({
    required GameSession session,
    required GameTurnContext context,
    required GameTurnResult result,
    required String turnId,
    bool queueOnly = false,
  }) async {
    final alreadyRecorded = (session.metadata['recorded_turn_ids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .contains(turnId) ??
        false;
    if (alreadyRecorded) {
      return session;
    }

    final ids = idsForTurn(context, result);
    await _learnerModel.recordPracticeEvent(
      turnId: turnId,
      sessionId: session.sessionId,
      learnerId: session.userId,
      itemId: ids.itemId,
      skillId: ids.skillId,
      wasCorrect: result.score.isCorrect,
      errorTypeIds: ids.errorTypeIds,
      timestamp: result.timestamp,
      queueOnly: queueOnly,
    );

    if (queueOnly) {
      _pendingSrs.add((
        userId: session.userId,
        itemId: ids.itemId,
        wasCorrect: result.score.isCorrect,
        accuracy: result.score.accuracy,
      ));
    } else {
      _spacedRepetition.reviewFromPracticeOutcome(
        userId: session.userId,
        lessonItemId: ids.itemId,
        wasCorrect: result.score.isCorrect,
        accuracy: result.score.accuracy,
      );
    }

    final updatedTurns = [...session.turns, result];
    final recorded = [
      ...(session.metadata['recorded_turn_ids'] as List<dynamic>? ?? const [])
          .map((e) => e as String),
      turnId,
    ];

    return session.copyWith(
      turns: updatedTurns,
      metadata: {
        ...session.metadata,
        'recorded_turn_ids': recorded,
        'learner_events_recorded': recorded.length,
      },
    );
  }

  /// Applies queued learner events and matching SRS updates in order.
  Future<int> flushOfflineQueue() async {
    final applied = await _learnerModel.flushPendingPracticeEvents();
    for (final entry in _pendingSrs) {
      _spacedRepetition.reviewFromPracticeOutcome(
        userId: entry.userId,
        lessonItemId: entry.itemId,
        wasCorrect: entry.wasCorrect,
        accuracy: entry.accuracy,
      );
    }
    _pendingSrs.clear();
    return applied;
  }
}

/// Result of resolving a turn and recording it on the learner graph.
class GameTurnResolution {
  final GameTurnResult result;
  final GameSession session;

  const GameTurnResolution(this.result, this.session);
}

/// Mandatory GameKit path: resolve scoring, then write learner graph + SRS.
extension GameEngineLearnerGraph on GameEngine {
  Future<GameTurnResolution> resolveTurnRecording(
    GameKitLearnerGraphWriter writer,
    GameTurnContext context, {
    required String turnId,
    bool queueOnly = false,
  }) async {
    final result = await resolve(context);
    final session = await writer.recordTurn(
      session: context.session,
      context: context,
      result: result,
      turnId: turnId,
      queueOnly: queueOnly,
    );
    return GameTurnResolution(result, session);
  }
}
