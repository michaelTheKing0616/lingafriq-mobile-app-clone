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
import '../../config/api_contract.dart';
import '../../providers/dio_provider.dart';
import 'package:dio/dio.dart';

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
        if (score.isUnsure) 'unsure': true,
        if (score.honestPracticeMode) 'honest_practice': true,
        if (score.scorerVersion != null) 'scorer_version': score.scorerVersion,
        if (score.confidence != null) 'confidence': score.confidence,
      },
    );
  }
}

const _masteryEpsilon = 0.0001;

/// One skill's learner-model mastery before vs after a GameKit session (P8-915).
class GameMasterySkillDelta {
  const GameMasterySkillDelta({
    required this.skillId,
    required this.masteryBefore,
    required this.masteryAfter,
  });

  final String skillId;
  final double masteryBefore;
  final double masteryAfter;

  bool get hasMeasuredChange =>
      (masteryAfter - masteryBefore).abs() > _masteryEpsilon;

  bool get improved => masteryAfter > masteryBefore + _masteryEpsilon;

  bool get declined => masteryBefore > masteryAfter + _masteryEpsilon;

  /// Improved, declined, or flat — never label flat as improved.
  GameMasteryChangeKind get changeKind {
    if (improved) return GameMasteryChangeKind.improved;
    if (declined) return GameMasteryChangeKind.declined;
    return GameMasteryChangeKind.noChange;
  }

  int masteryBeforePercent() => (masteryBefore * 100).round().clamp(0, 100);

  int masteryAfterPercent() => (masteryAfter * 100).round().clamp(0, 100);
}

enum GameMasteryChangeKind { improved, declined, noChange }

/// Reads session metadata written during [GameKitLearnerGraphWriter.recordTurn].
List<GameMasterySkillDelta> skillDeltasFromGameSession(GameSession session) {
  final raw = session.metadata['skill_mastery_snapshots'];
  if (raw is! Map) return const [];
  final deltas = <GameMasterySkillDelta>[];
  for (final entry in raw.entries) {
    final skillId = entry.key.toString();
    final map = entry.value;
    if (map is! Map) continue;
    final before = (map['before'] as num?)?.toDouble();
    final after = (map['after'] as num?)?.toDouble();
    if (before == null || after == null) continue;
    deltas.add(GameMasterySkillDelta(
      skillId: skillId,
      masteryBefore: before,
      masteryAfter: after,
    ));
  }
  deltas.sort((a, b) => a.skillId.compareTo(b.skillId));
  return deltas;
}

/// Payload for [GameMasteryResultsScreen].
class GameMasteryResultsPayload {
  const GameMasteryResultsPayload({
    required this.session,
    required this.skillDeltas,
    this.serverXpAwarded,
    this.practiceNotScored = false,
  });

  final GameSession session;
  final List<GameMasterySkillDelta> skillDeltas;
  final int? serverXpAwarded;
  final bool practiceNotScored;

  factory GameMasteryResultsPayload.fromSession(
    GameSession session, {
    int? serverXpAwarded,
  }) {
    return GameMasteryResultsPayload(
      session: session,
      skillDeltas: skillDeltasFromGameSession(session),
      serverXpAwarded: serverXpAwarded,
      practiceNotScored: session.practiceNotScored,
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
    final snapshots = Map<String, dynamic>.from(
      session.metadata['skill_mastery_snapshots'] as Map? ?? const {},
    );
    final prior = snapshots[ids.skillId];
    final masteryBefore = prior is Map && prior['before'] is num
        ? (prior['before'] as num).toDouble()
        : _learnerModel
            .getState(learnerId: session.userId, skillId: ids.skillId)
            .mastery;

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

    final masteryAfter = _learnerModel
        .getState(learnerId: session.userId, skillId: ids.skillId)
        .mastery;
    snapshots[ids.skillId] = {
      'before': masteryBefore,
      'after': masteryAfter,
    };

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

    final scorerTraces = <Map<String, dynamic>>[
      ...((session.metadata['learner_scorer_traces'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)) ??
          const []),
    ];
    if (result.score.scorerTrace != null) {
      scorerTraces.add({
        'turnId': turnId,
        'itemId': ids.itemId,
        'skillId': ids.skillId,
        ...result.score.scorerTrace!,
      });
    }

    return session.copyWith(
      turns: updatedTurns,
      metadata: {
        ...session.metadata,
        'recorded_turn_ids': recorded,
        'learner_events_recorded': recorded.length,
        'skill_mastery_snapshots': snapshots,
        if (scorerTraces.isNotEmpty) 'learner_scorer_traces': scorerTraces,
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

/// Server-verified GameKit session reward (P8-909).
class GameSessionRewardClaim {
  final String sessionId;
  final int xpAwarded;
  final bool practice;
  final bool duplicate;
  final int? xpTotal;

  const GameSessionRewardClaim({
    required this.sessionId,
    required this.xpAwarded,
    required this.practice,
    required this.duplicate,
    this.xpTotal,
  });

  factory GameSessionRewardClaim.fromJson(Map<String, dynamic> json) {
    return GameSessionRewardClaim(
      sessionId: json['session_id'] as String? ?? '',
      xpAwarded: (json['xp_awarded'] as num?)?.toInt() ?? 0,
      practice: json['practice'] == true,
      duplicate: json['duplicate'] == true,
      xpTotal: (json['xp_total'] as num?)?.toInt(),
    );
  }
}

/// POST /api/games/session/:id/claim-reward/ — never sends client XP totals.
Future<GameSessionRewardClaim?> claimGameSessionRewardVerified({
  required Dio dio,
  required backend.GameSession session,
}) async {
  final response = await dio.post<Map<String, dynamic>>(
    ApiContract.url('/api/games/session/${session.sessionId}/claim-reward/'),
    data: const <String, dynamic>{},
    options: Options(
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  final status = response.statusCode ?? 0;
  if (status == 401 || status == 403) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: 'game_reward_auth_failed',
    );
  }
  if (status >= 400) {
    return null;
  }
  final data = response.data?['data'];
  if (data is! Map<String, dynamic>) return null;
  return GameSessionRewardClaim.fromJson(data);
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
