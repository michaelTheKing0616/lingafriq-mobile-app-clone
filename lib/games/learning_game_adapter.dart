import 'package:dio/dio.dart';

import '../services/learning/learning_event_log.dart';
import '../services/sync/outbox_service.dart';
import 'gamekit/batch_game_factory.dart';
import 'gamekit/game_difficulty.dart';
import 'gamekit/game_engine.dart';
import 'gamekit/game_factory_helper.dart';
import 'gamekit/game_scoring.dart';
import '../models/game/game_content_models.dart';
import '../services/offline/lexicon_pack_service.dart';
import '../../services/lens/lens_scoring_client.dart';
import 'gamekit/game_feedback.dart';
import 'gamekit/game_animation_bridge.dart';
import 'gamekit/game_turn_context.dart';
import 'gamekit/game_result.dart';
import 'gamekit/game_session.dart' as gamekit_session;
import '../services/learning/spaced_repetition_service.dart';
import '../learning/game_integration/learning_game.dart';
import '../learning/learner_model/learner_model_service.dart';
import '../learning/learner_model/error_taxonomy.dart';

/// Difficulty engine that uses the learner model for adaptive difficulty.
///
/// Implements the same interface as [GameDifficultyEngine]. Uses
/// [LearnerModelService] to read learner state and compute difficulty from
/// mastery, error patterns, time pressure, and streak. Falls back to
/// [DefaultGameDifficultyEngine] behavior when no meaningful learner state exists.
class LearningGameDifficultyEngine implements GameDifficultyEngine {
  final String learnerId;
  final String skillId;

  LearningGameDifficultyEngine({
    required this.learnerId,
    required this.skillId,
  });

  @override
  GameDifficultyUpdate adjust(GameTurnContext context, GameScore score) {
    final session = context.session;
    final streak = session.streak;
    final recentAccuracy = session.accuracy;

    final state = LearnerModelService.instance.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    // Fallback to default behavior when no meaningful history
    final hasHistory = state.totalAttempts >= 2;
    if (!hasHistory) {
      if (score.isPerfect && streak >= 3 && recentAccuracy > 0.85) {
        return GameDifficultyUpdate.increase();
      }
      if (score.isFail && streak == 0 && recentAccuracy < 0.5) {
        return GameDifficultyUpdate.decrease();
      }
      return GameDifficultyUpdate.maintain();
    }

    // Learner-model–driven adjustment
    final mastery = state.mastery.clamp(0.0, 1.0);
    final accuracy = state.accuracy;
    final currentStreak = state.currentStreak;
    final errorEntropy = ErrorTaxonomy.errorEntropy(
      state.errorDistribution.rates,
    );

    // Increase difficulty: high accuracy, good streak, solid mastery
    if (score.isPerfect &&
        currentStreak >= 3 &&
        accuracy > 0.85 &&
        mastery > 0.4) {
      final newLevel = (mastery + 0.1).clamp(0.0, 1.0);
      return GameDifficultyUpdate.increase(level: newLevel);
    }

    // Decrease difficulty: failing, low accuracy, many attempts, or high error entropy
    if (score.isFail && (accuracy < 0.5 || currentStreak == 0)) {
      final newLevel = (mastery - 0.15).clamp(0.1, 1.0);
      return GameDifficultyUpdate.decrease(level: newLevel);
    }
    if (state.totalAttempts > 5 && accuracy < 0.4) {
      final newLevel = (mastery - 0.1).clamp(0.1, 1.0);
      return GameDifficultyUpdate.decrease(level: newLevel);
    }
    if (errorEntropy > 2.0 && score.isFail) {
      return GameDifficultyUpdate.decrease();
    }

    return GameDifficultyUpdate.maintain();
  }
}

/// Loads GameKit vocabulary from verified lexicon (P8-912); surfaces typed failures.
class GameKitLexiconPool {
  GameKitLexiconPool._();

  static Future<GameLexiconPoolBuildResult> load({
    required String languageCode,
    required int minimumItems,
    bool requireAudio = false,
    int fetchLimit = 100,
    GameLexiconPoolFetch? fetch,
    LexiconPackService? packService,
  }) {
    return GameFactoryHelper.buildLexiconWordPool(
      GameLexiconPoolRequest(
        languageCode: languageCode,
        minimumItems: minimumItems,
        requireAudio: requireAudio,
        fetchLimit: fetchLimit,
      ),
      fetch: fetch,
      packService: packService,
    );
  }
}

/// Single entry for GameKit turn → learner graph + SRS (do not call [GameEngine.resolve] alone).
class GameKitPracticeRecorder {
  GameKitPracticeRecorder._();

  static final GameKitLearnerGraphWriter _writer = GameKitLearnerGraphWriter();

  static Future<gamekit_session.GameSession> afterTurn({
    required gamekit_session.GameSession session,
    required GameTurnContext context,
    required GameTurnResult result,
    required String turnId,
    bool queueOnly = false,
  }) {
    return _writer.recordTurn(
      session: session,
      context: context,
      result: result,
      turnId: turnId,
      queueOnly: queueOnly,
    );
  }

  static Future<int> flushOfflineQueue() {
    return _writer.flushOfflineQueue();
  }

  /// SRS quality mapping shared with lesson practice.
  static int srsQuality({required bool wasCorrect, double accuracy = 1.0}) {
    return SpacedRepetitionService().qualityFromPracticeOutcome(
      wasCorrect: wasCorrect,
      accuracy: accuracy,
    );
  }
}

/// Maps game results to learning model types and records sessions.
class GameResultMapper {
  GameResultMapper._();

  /// Maps a single turn result to a [SkillOutcome].
  static SkillOutcome mapToSkillOutcome({
    required double score,
    required double responseTimeSeconds,
    double expectedTimeSeconds = 5.0,
    List<String> errorTypeIds = const [],
  }) {
    final isCorrect = score >= 0.6;
    final partialCredit = score.clamp(0.0, 1.0);
    return SkillOutcome(
      isCorrect: isCorrect,
      partialCredit: partialCredit,
      errorTypeIds: errorTypeIds,
      responseTimeSeconds: responseTimeSeconds,
      expectedTimeSeconds: expectedTimeSeconds,
    );
  }

  /// Records a full game session by recording each outcome in the learner model.
  static Future<void> recordGameSession(GameSessionResult result) async {
    final learnerModel = LearnerModelService.instance;
    for (var i = 0; i < result.outcomes.length; i++) {
      final outcome = result.outcomes[i];
      final skillId = i < result.skillIds.length
          ? result.skillIds[i]
          : result.skillIds.isNotEmpty
          ? result.skillIds.first
          : '';
      if (skillId.isEmpty) continue;
      await learnerModel.recordAttempt(
        learnerId: result.learnerId,
        skillId: skillId,
        wasCorrect: outcome.isCorrect,
        errorTypeIds: outcome.errorTypeIds,
        responseTimeSeconds: outcome.responseTimeSeconds,
        expectedTimeSeconds: outcome.expectedTimeSeconds,
      );
    }
  }

  /// Records a single outcome for one learner/skill.
  static Future<void> recordSingleOutcome({
    required String learnerId,
    required String skillId,
    required SkillOutcome outcome,
  }) async {
    await LearnerModelService.instance.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: outcome.isCorrect,
      errorTypeIds: outcome.errorTypeIds,
      responseTimeSeconds: outcome.responseTimeSeconds,
      expectedTimeSeconds: outcome.expectedTimeSeconds,
    );
  }
}

/// Factory for a [GameEngine] configured with [LearningGameDifficultyEngine].
class AdaptiveLearningGameEngine {
  AdaptiveLearningGameEngine._();

  /// Creates a [GameEngine] that uses [LearningGameDifficultyEngine] for
  /// the given [learnerId] and first of [skillIds], with the provided
  /// [animationBridge]. Uses [DefaultGameScoringEngine] and
  /// [DefaultGameFeedbackEngine] for scoring and feedback.
  static GameEngine create({
    required String learnerId,
    required List<String> skillIds,
    required GameAnimationBridge animationBridge,
  }) {
    final skillId = skillIds.isNotEmpty ? skillIds.first : '';
    final difficulty = skillId.isNotEmpty
        ? LearningGameDifficultyEngine(learnerId: learnerId, skillId: skillId)
        : DefaultGameDifficultyEngine();
    return GameEngine(
      scoring: DefaultGameScoringEngine(),
      difficulty: difficulty,
      feedback: DefaultGameFeedbackEngine(),
      animation: animationBridge,
    );
  }

  /// Speaking games: scores only via [RealScorerSpeakingEngine] + gateway POST.
  static GameEngine createWithRealSpeakingScorer({
    required String learnerId,
    required List<String> skillIds,
    required GameAnimationBridge animationBridge,
    required Future<Response<dynamic>> Function(String path, FormData data)
    post,
    LensScoringClient? scoringClient,
  }) {
    final skillId = skillIds.isNotEmpty ? skillIds.first : '';
    final difficulty = skillId.isNotEmpty
        ? LearningGameDifficultyEngine(learnerId: learnerId, skillId: skillId)
        : DefaultGameDifficultyEngine();
    return GameEngine(
      scoring: RealScorerSpeakingEngine(client: scoringClient, post: post),
      difficulty: difficulty,
      feedback: SpeakingGameFeedbackEngine(),
      animation: animationBridge,
    );
  }
}

/// Feedback for real-scorer speaking turns (unsure + honest practice).
class SpeakingGameFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(
    GameTurnContext context,
    GameScore score,
  ) async {
    if (score.isUnsure) {
      return GameFeedback.neutral(
        message:
            score.details?['message'] as String? ??
            'We could not score this clearly. Try again.',
        animationEvent: AnimationEvent.listening,
        metadata: const {'retry': true, 'unsure': true},
      );
    }
    if (score.honestPracticeMode) {
      return GameFeedback.neutral(
        message:
            score.details?['message'] as String? ??
            'Practice mode — scoring is unavailable.',
        animationEvent: AnimationEvent.encouraging,
        metadata: const {'honest_practice': true, 'retry': true},
      );
    }
    return DefaultGameFeedbackEngine().generate(context, score);
  }
}

/// Sync outbox operation for a finished practice game. This is the existing
/// `learning_event` type, not a new channel.
const String practiceLearnerOutboxType = 'learning_event';

/// [LearningEvent.source] for a game played as a practice format.
const String practiceLearnerEventSource = 'game';

/// Writes one typed learner-model event. [enqueue] is the existing outbox.
typedef PracticeOutboxEnqueue = Future<String> Function({
  required String type,
  required Map<String, dynamic> payload,
  String? idempotencyKey,
});

/// One played item. Correctness is copied from a real [GameScore].
/// An unscored turn omits [wasCorrect] and [accuracy].
class PracticeItemOutcome {
  const PracticeItemOutcome({
    required this.itemId,
    required this.scored,
    this.wasCorrect,
    this.accuracy,
  });

  final String itemId;
  final bool scored;
  final bool? wasCorrect;
  final double? accuracy;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'itemId': itemId,
      'scored': scored,
      if (scored && wasCorrect != null) 'wasCorrect': wasCorrect,
      if (scored && accuracy != null) 'accuracy': accuracy,
    };
  }
}

/// Outcomes for the turns that actually finished. No aggregate score is added.
class PracticeGameOutcome {
  const PracticeGameOutcome(this.items);

  final List<PracticeItemOutcome> items;

  bool get isEmpty => items.isEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'items': <Map<String, Object?>>[
        for (final PracticeItemOutcome item in items) item.toJson(),
      ],
    };
  }
}

/// Learner-model event for a practice game. [source] is `game`.
class PracticeLearnerEvent {
  const PracticeLearnerEvent({
    required this.clientEventId,
    required this.eventTime,
    required this.gameId,
    required this.learnerId,
    required this.itemIds,
    required this.outcome,
    this.language,
    this.planItemId,
    this.planItemIds = const <String>[],
    this.origin,
  });

  final String clientEventId;
  final DateTime eventTime;
  final String gameId;
  final String learnerId;
  final List<String> itemIds;
  final PracticeGameOutcome outcome;
  final String? language;
  final String? planItemId;
  final List<String> planItemIds;
  final String? origin;

  LearningEvent toLearningEvent() {
    return LearningEvent(
      clientEventId: clientEventId,
      source: practiceLearnerEventSource,
      eventTime: eventTime,
      language: language,
      payload: <String, Object?>{
        'gameId': gameId,
        'learnerId': learnerId,
        'itemIds': itemIds,
        'outcome': outcome.toJson(),
        if (planItemId != null) 'planItemId': planItemId,
        if (planItemIds.isNotEmpty) 'planItemIds': planItemIds,
        if (origin != null) 'origin': origin,
      },
    );
  }

  Map<String, dynamic> toOutboxPayload() {
    return _jsonMap(toLearningEvent().toJson());
  }
}

/// Result of trying to persist [PracticeLearnerEvent]. [saved] is true only
/// after the outbox accepts the row.
class PracticeOutboxSave {
  const PracticeOutboxSave({required this.saved, this.operationId, this.event});

  final bool saved;
  final String? operationId;
  final PracticeLearnerEvent? event;
}

/// Builds an event from turns the session already has.
///
/// Returns null when a turn has no item id, or when the session has no turns.
/// Missing correctness stays missing. It is not filled in.
PracticeLearnerEvent? practiceLearnerEventFromSession({
  required gamekit_session.GameSession session,
  required String clientEventId,
  String? planItemId,
  List<String> planItemIds = const <String>[],
  String? origin,
}) {
  final String eventId = clientEventId.trim();
  final String learnerId = session.userId.trim();
  final String gameId = session.gameId.trim();
  if (eventId.isEmpty || learnerId.isEmpty || gameId.isEmpty) return null;
  if (session.turns.isEmpty) return null;

  final List<String> requested = <String>[
    for (final String id in planItemIds)
      if (id.trim().isNotEmpty) id.trim(),
  ];
  final List<PracticeItemOutcome> items = <PracticeItemOutcome>[];
  for (var i = 0; i < session.turns.length; i++) {
    final String? itemId = _practiceItemId(
      index: i,
      turnQueue: session.turnQueue,
      planItemIds: requested,
    );
    if (itemId == null) return null;
    final score = session.turns[i].score;
    final bool scored =
        score.countsForRewards && !score.isUnsure && !score.honestPracticeMode;
    items.add(
      PracticeItemOutcome(
        itemId: itemId,
        scored: scored,
        wasCorrect: scored ? score.isCorrect : null,
        accuracy: scored ? score.accuracy : null,
      ),
    );
  }
  if (items.isEmpty) return null;

  final String? language = session.language.trim().isEmpty
      ? null
      : session.language.trim();
  final String? rowId = planItemId?.trim();
  final String? from = origin?.trim();
  final PracticeLearnerEvent event = PracticeLearnerEvent(
    clientEventId: eventId,
    eventTime: session.turns.last.timestamp.toUtc(),
    gameId: gameId,
    learnerId: learnerId,
    itemIds: <String>[
      for (final PracticeItemOutcome item in items) item.itemId,
    ],
    outcome: PracticeGameOutcome(items),
    language: language,
    planItemId: (rowId == null || rowId.isEmpty) ? null : rowId,
    planItemIds: requested,
    origin: (from == null || from.isEmpty) ? null : from,
  );
  try {
    final bool accepted = LearningEventLog().apply(event.toLearningEvent());
    if (!accepted) return null;
  } on ArgumentError {
    return null;
  }
  return event;
}

/// Enqueues [event] on the outbox the caller supplies.
///
/// A throw, an empty id, or an event with no item ids leaves [PracticeOutboxSave.saved]
/// false and does not report a completed save.
Future<PracticeOutboxSave> writePracticeLearnerEvent({
  required PracticeLearnerEvent event,
  required PracticeOutboxEnqueue enqueue,
}) async {
  if (event.clientEventId.isEmpty ||
      event.itemIds.isEmpty ||
      event.outcome.isEmpty ||
      event.itemIds.length != event.outcome.items.length) {
    return PracticeOutboxSave(saved: false, event: event);
  }
  if (!learningEventSources.contains(practiceLearnerEventSource)) {
    return PracticeOutboxSave(saved: false, event: event);
  }
  try {
    final String id = await enqueue(
      type: practiceLearnerOutboxType,
      payload: event.toOutboxPayload(),
      idempotencyKey: event.clientEventId,
    );
    if (id.trim().isEmpty) {
      return PracticeOutboxSave(saved: false, event: event);
    }
    return PracticeOutboxSave(saved: true, operationId: id, event: event);
  } catch (_) {
    return PracticeOutboxSave(saved: false, event: event);
  }
}

/// Writes [event] through [OutboxService.enqueue] as `learning_event`.
Future<PracticeOutboxSave> writePracticeLearnerEventToOutbox({
  required OutboxService outbox,
  required PracticeLearnerEvent event,
}) {
  return writePracticeLearnerEvent(
    event: event,
    enqueue:
        ({
          required String type,
          required Map<String, dynamic> payload,
          String? idempotencyKey,
        }) async {
          final OutboxRecord record = await outbox.enqueue(
            type: type,
            payload: payload,
            idempotencyKey: idempotencyKey,
          );
          return record.id;
        },
  );
}

String? _practiceItemId({
  required int index,
  required List<String> turnQueue,
  required List<String> planItemIds,
}) {
  if (index >= 0 && index < turnQueue.length) {
    final String queued = turnQueue[index].trim();
    if (queued.isNotEmpty) return queued;
  }
  if (index >= 0 && index < planItemIds.length) {
    final String planned = planItemIds[index].trim();
    if (planned.isNotEmpty) return planned;
  }
  return null;
}

Map<String, dynamic> _jsonMap(Map<String, Object?> json) {
  return json.map(
    (String key, Object? value) =>
        MapEntry<String, dynamic>(key, _jsonValue(value)),
  );
}

Object? _jsonValue(Object? value) {
  if (value is Map) {
    return value.map(
      (Object? key, Object? nested) =>
          MapEntry<String, dynamic>(key.toString(), _jsonValue(nested)),
    );
  }
  if (value is List) {
    return <Object?>[for (final Object? item in value) _jsonValue(item)];
  }
  return value;
}
