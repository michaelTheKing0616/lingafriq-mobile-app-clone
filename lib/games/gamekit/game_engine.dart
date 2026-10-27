import '../../learning/learner_model/learner_model_service.dart';
import '../../services/learning/spaced_repetition_service.dart';
import 'game_scoring.dart';
import 'game_difficulty.dart';
import 'game_feedback.dart';
import 'game_animation_bridge.dart';
import 'game_result.dart';
import 'game_session.dart';
import 'game_turn_context.dart';

/// Practice targets declared in a GameKit manifest (EP-§10.2).
enum GamePracticeTarget {
  retrieval,
  perception,
}

/// Single core player action per game (EP-§10.2-05).
enum GameCoreVerb {
  listen,
  speak,
  choose,
  match,
  tap,
  trace,
  build,
  assemble,
}

/// Planned session length bounds in seconds (EP-§10.2-04).
class GameKitSessionDuration {
  static const int minSeconds = 60;
  static const int maxSeconds = 180;
  static const int defaultSeconds = 120;

  static int clampPlanned(int? seconds) {
    final value = seconds ?? defaultSeconds;
    if (value < minSeconds || value > maxSeconds) {
      return value < minSeconds ? minSeconds : maxSeconds;
    }
    return value;
  }
}

/// Session timing and turn gating (P8-902).
class GameSessionClock {
  /// Whether a new turn may start; an in-flight turn may finish past the hard cap.
  static bool mayBeginTurn(
    GameSession session,
    DateTime now, {
    bool turnInProgress = false,
  }) {
    if (turnInProgress) return true;
    final elapsed = now.difference(session.startTime).inSeconds;
    if (elapsed >= GameKitSessionDuration.maxSeconds) return false;
    return now.isBefore(session.plannedEndTime);
  }

  /// After a turn resolves, show results when no further turn is allowed.
  static bool shouldShowResultsAfterTurn(GameSession session, DateTime now) {
    return !mayBeginTurn(session, now);
  }
}

/// Nightly telemetry flag for games whose median session length is outside 60–180 s.
class GameSessionDurationReport {
  final Map<String, double> medianSecondsByGame;
  final List<String> flaggedGameIds;

  const GameSessionDurationReport({
    required this.medianSecondsByGame,
    required this.flaggedGameIds,
  });

  static GameSessionDurationReport fromSamples(
    List<({String gameId, int durationSeconds})> samples,
  ) {
    final buckets = <String, List<int>>{};
    for (final sample in samples) {
      buckets.putIfAbsent(sample.gameId, () => []).add(sample.durationSeconds);
    }
    final medians = <String, double>{};
    final flagged = <String>[];
    for (final entry in buckets.entries) {
      final sorted = [...entry.value]..sort();
      final mid = sorted.length ~/ 2;
      final median = sorted.length.isOdd
          ? sorted[mid].toDouble()
          : (sorted[mid - 1] + sorted[mid]) / 2.0;
      medians[entry.key] = median;
      if (median < GameKitSessionDuration.minSeconds ||
          median > GameKitSessionDuration.maxSeconds) {
        flagged.add(entry.key);
      }
    }
    flagged.sort();
    return GameSessionDurationReport(
      medianSecondsByGame: medians,
      flaggedGameIds: flagged,
    );
  }
}

/// Typed failure when a game manifest is invalid for GameKit registration.
class GameManifestError implements Exception {
  final String code;
  final String message;

  const GameManifestError(this.code, this.message);

  @override
  String toString() => 'GameManifestError($code): $message';
}

/// Manifest every GameKit game must supply before it is listed.
class GameManifest {
  final String gameId;
  final Set<GamePracticeTarget> practiceTargets;
  final GameCoreVerb coreVerb;
  final int defaultQueueLength;
  final int plannedDurationSeconds;

  GameManifest({
    required this.gameId,
    required this.practiceTargets,
    required this.coreVerb,
    this.defaultQueueLength = 10,
    int? plannedDurationSeconds,
  }) : plannedDurationSeconds =
            GameKitSessionDuration.clampPlanned(plannedDurationSeconds);

  static final Set<GameCoreVerb> allowedCoreVerbs = GameCoreVerb.values.toSet();
}

/// Registered GameKit games (in-memory; populated at app bootstrap / tests).
class GameKitCatalog {
  static final Map<String, GameManifest> _byId = {};

  static void register(GameManifest manifest) {
    if (manifest.practiceTargets.isEmpty) {
      throw const GameManifestError(
        'missing_practice_target',
        'Game must declare retrieval or perception practice target',
      );
    }
    if (!GameManifest.allowedCoreVerbs.contains(manifest.coreVerb)) {
      throw GameManifestError(
        'invalid_core_verb',
        'Core verb must be one of: ${GameManifest.allowedCoreVerbs.map((v) => v.name).join(', ')}',
      );
    }
    _byId[manifest.gameId] = manifest;
  }

  static void unregister(String gameId) => _byId.remove(gameId);

  static void clear() => _byId.clear();

  static bool isRegistered(String gameId) => _byId.containsKey(gameId);

  static GameManifest? manifestFor(String gameId) => _byId[gameId];
}

/// How the turn queue was populated.
enum GameQueueSource {
  due,
  fallback,
}

/// Result of building a session turn queue.
class GameQueuePlan {
  final List<String> itemIds;
  final GameQueueSource source;
  final int dueItemsServed;
  final bool loadFailed;

  const GameQueuePlan({
    required this.itemIds,
    required this.source,
    required this.dueItemsServed,
    this.loadFailed = false,
  });

  static const retry = GameQueuePlan(
    itemIds: [],
    source: GameQueueSource.due,
    dueItemsServed: 0,
    loadFailed: true,
  );
}

/// Builds due-first turn queues for GameKit sessions (P8-900).
class GameTurnQueuePlanner {
  GameTurnQueuePlanner({
    LearnerModelService? learnerModel,
    SpacedRepetitionService? spacedRepetition,
    this.dueItemIdsOverride,
  })  : _learnerModel = learnerModel ?? LearnerModelService.instance,
        _spacedRepetition = spacedRepetition ?? SpacedRepetitionService();

  final LearnerModelService _learnerModel;
  final SpacedRepetitionService _spacedRepetition;

  /// Injectable due query for tests and offline failure simulation.
  Future<List<String>> Function(String userId, int limit)? dueItemIdsOverride;

  Future<GameQueuePlan> buildQueue({
    required String userId,
    required String languageCode,
    required int queueLength,
  }) async {
    List<String> dueIds;
    try {
      if (dueItemIdsOverride != null) {
        dueIds = await dueItemIdsOverride!(userId, queueLength);
      } else {
        dueIds = _spacedRepetition
            .getDueCards(userId, limit: queueLength)
            .map((c) => c.lessonItemId)
            .toList();
      }
    } catch (_) {
      return GameQueuePlan.retry;
    }

    final dueSlice = dueIds.take(queueLength).toList();
    final dueServed = dueSlice.length;

    if (dueServed >= queueLength) {
      return GameQueuePlan(
        itemIds: dueSlice,
        source: GameQueueSource.due,
        dueItemsServed: dueServed,
      );
    }

    final fallbackSkills = _learnerModel.getLowestMasterySkillIds(
      learnerId: userId,
      languageCode: languageCode,
      count: queueLength,
    );
    final filler = fallbackSkills
        .where((id) => !dueSlice.contains(id))
        .take(queueLength - dueServed);

    if (dueServed == 0) {
      return GameQueuePlan(
        itemIds: filler.take(queueLength).toList(),
        source: GameQueueSource.fallback,
        dueItemsServed: 0,
      );
    }

    return GameQueuePlan(
      itemIds: [...dueSlice, ...filler],
      source: GameQueueSource.due,
      dueItemsServed: dueServed,
    );
  }
}

/// Central game engine that orchestrates scoring, difficulty, feedback, and animation
/// This is the core of the GameKit framework - all games use this
class GameEngine {
  final GameScoringEngine scoring;
  final GameDifficultyEngine difficulty;
  final GameFeedbackEngine feedback;
  final GameAnimationBridge animation;
  final GameTurnQueuePlanner queuePlanner;

  GameEngine({
    required this.scoring,
    required this.difficulty,
    required this.feedback,
    required this.animation,
    GameTurnQueuePlanner? queuePlanner,
  }) : queuePlanner = queuePlanner ?? GameTurnQueuePlanner();

  /// Register a game manifest; throws [GameManifestError] when invalid.
  void registerGame(GameManifest manifest) {
    GameKitCatalog.register(manifest);
  }

  /// Start a session with a due-first turn queue (AC1–AC4).
  Future<GameSession> startSessionWithQueue({
    required String sessionId,
    required String userId,
    required String gameId,
    required String languageCode,
    String? level,
    int? queueLength,
    int? plannedDurationSeconds,
  }) async {
    final manifest = GameKitCatalog.manifestFor(gameId);
    if (manifest == null) {
      throw GameManifestError(
        'not_registered',
        'Game $gameId is not registered with GameKit',
      );
    }

    final length = queueLength ?? manifest.defaultQueueLength;
    final plan = await queuePlanner.buildQueue(
      userId: userId,
      languageCode: languageCode,
      queueLength: length,
    );

    final planned = GameKitSessionDuration.clampPlanned(
      plannedDurationSeconds ?? manifest.plannedDurationSeconds,
    );

    final metadata = <String, dynamic>{
      'queue_source': plan.loadFailed ? 'retry' : plan.source.name,
      'due_items_served': plan.dueItemsServed,
      'planned_duration_seconds': planned,
      'core_verb': manifest.coreVerb.name,
      if (plan.loadFailed) 'queue_load_failed': true,
    };

    final startedAt = DateTime.now();
    return GameSession(
      sessionId: sessionId,
      userId: userId,
      gameId: gameId,
      language: languageCode,
      level: level,
      startTime: startedAt,
      plannedDurationSeconds: planned,
      turnQueue: plan.itemIds,
      queueLoadFailed: plan.loadFailed,
      metadata: metadata,
    );
  }

  /// Resolve a game turn - this is called by all games
  /// Returns complete result with score, feedback, difficulty adjustment, and animation cues
  Future<GameTurnResult> resolve(GameTurnContext context) async {
    // Calculate score
    final score = await scoring.score(context);

    // Adjust difficulty based on performance
    final difficultyUpdate = difficulty.adjust(context, score);

    // Generate feedback
    final feedbackData = await feedback.generate(context, score);

    // Emit animation event
    animation.emit(feedbackData.animationEvent, score);

    return GameTurnResult(
      score: score,
      feedback: feedbackData,
      difficultyUpdate: difficultyUpdate,
      timestamp: DateTime.now(),
    );
  }

  /// Create a default engine instance
  factory GameEngine.defaultEngine(GameAnimationBridge animationBridge) {
    return GameEngine(
      scoring: DefaultGameScoringEngine(),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: DefaultGameFeedbackEngine(),
      animation: animationBridge,
    );
  }
}
