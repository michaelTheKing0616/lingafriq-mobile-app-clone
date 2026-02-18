import '../learner_model/learner_model_service.dart';
import '../learner_model/learner_skill_state.dart';
import '../learner_model/error_taxonomy.dart';

/// Abstract base for learning-aware games.
///
/// Every game MUST implement this interface to participate in the
/// learning system. Games are not standalone entertainment — they are
/// practice wrappers driven by the learner model.
///
/// Contract:
/// - Games read from the learner model to determine difficulty
/// - Games write back to the learner model after each response
/// - Difficulty is continuously tuned by the engine, not hardcoded
/// - Game results feed the same error taxonomy as all other practice
abstract class LearningGame {
  /// Adjusts game difficulty based on the learner's current state.
  ///
  /// The game MUST call this at the start of each round to get the
  /// correct difficulty parameters.
  GameDifficulty adjustDifficulty(LearnerSkillState state);

  /// Evaluates a single response within the game.
  ///
  /// Returns a SkillOutcome that includes:
  /// - Whether it was correct
  /// - Which errors occurred (from the taxonomy)
  /// - Partial credit if applicable
  /// - Response time for automaticity tracking
  SkillOutcome evaluateResponse(GameResponse response);

  /// Returns the skill ID(s) this game practices.
  List<String> get targetSkillIds;

  /// Returns the game's identifier for analytics.
  String get gameId;
}

/// Mixin that provides learner model integration for games.
///
/// Games that mix this in get automatic difficulty adjustment,
/// learner model updates, and session tracking.
mixin LearningGameMixin {
  LearnerModelService get learnerModel => LearnerModelService.instance;

  /// Records a game response in the learner model.
  ///
  /// This is the bridge between game mechanics and the learning engine.
  Future<LearnerSkillState> recordGameResponse({
    required String learnerId,
    required String skillId,
    required SkillOutcome outcome,
  }) async {
    return learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: outcome.isCorrect,
      errorTypeIds: outcome.errorTypeIds,
      responseTimeSeconds: outcome.responseTimeSeconds,
      expectedTimeSeconds: outcome.expectedTimeSeconds,
    );
  }

  /// Gets the current recommended difficulty for a skill.
  GameDifficulty getRecommendedDifficulty({
    required String learnerId,
    required String skillId,
  }) {
    final state = learnerModel.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    return _computeDifficulty(state);
  }

  /// Computes game difficulty from learner state.
  ///
  /// Uses mastery, accuracy, time pressure, and error concentration
  /// to set appropriate game parameters.
  GameDifficulty _computeDifficulty(LearnerSkillState state) {
    // Base difficulty from mastery level
    double level = state.mastery.clamp(0.1, 0.95);

    // Adjust based on recent performance
    if (state.accuracy > 0.85 && state.currentStreak >= 3) {
      level = (level + 0.1).clamp(0.0, 1.0);
    } else if (state.accuracy < 0.5 && state.totalAttempts > 3) {
      level = (level - 0.15).clamp(0.0, 1.0);
    }

    // Time pressure from automaticity score
    final timeMultiplier = state.timePressureScore > 0.7 ? 0.8 : 1.2;

    // Distractors based on error patterns
    final errorFocus = ErrorTaxonomy.topErrors(state.errorDistribution.rates)
        .map((e) => e.key)
        .toList();

    return GameDifficulty(
      level: level,
      timeLimitMultiplier: timeMultiplier,
      distractorCount: _distractorCount(level),
      errorFocusTypes: errorFocus,
      shouldIncludeMinimalPairs: level > 0.4,
      shouldTimeResponse: state.mastery > 0.5,
    );
  }

  int _distractorCount(double level) {
    if (level < 0.3) return 2;
    if (level < 0.6) return 3;
    return 4;
  }
}

/// The result of evaluating a game response against the learning model.
class SkillOutcome {
  final bool isCorrect;
  final double partialCredit;
  final List<String> errorTypeIds;
  final double responseTimeSeconds;
  final double expectedTimeSeconds;

  const SkillOutcome({
    required this.isCorrect,
    this.partialCredit = 0.0,
    this.errorTypeIds = const [],
    this.responseTimeSeconds = 0,
    this.expectedTimeSeconds = 5,
  });

  factory SkillOutcome.correct({
    double responseTimeSeconds = 0,
    double expectedTimeSeconds = 5,
  }) =>
      SkillOutcome(
        isCorrect: true,
        partialCredit: 1.0,
        responseTimeSeconds: responseTimeSeconds,
        expectedTimeSeconds: expectedTimeSeconds,
      );

  factory SkillOutcome.incorrect({
    List<String> errorTypeIds = const [],
    double partialCredit = 0.0,
    double responseTimeSeconds = 0,
    double expectedTimeSeconds = 5,
  }) =>
      SkillOutcome(
        isCorrect: false,
        partialCredit: partialCredit,
        errorTypeIds: errorTypeIds,
        responseTimeSeconds: responseTimeSeconds,
        expectedTimeSeconds: expectedTimeSeconds,
      );
}

/// A raw response from a game that needs evaluation.
class GameResponse {
  final String skillId;
  final String expected;
  final String actual;
  final double responseTimeSeconds;
  final double expectedTimeSeconds;
  final Map<String, dynamic>? metadata;

  const GameResponse({
    required this.skillId,
    required this.expected,
    required this.actual,
    this.responseTimeSeconds = 0,
    this.expectedTimeSeconds = 5,
    this.metadata,
  });
}

/// Difficulty parameters for a game, computed from the learner model.
class GameDifficulty {
  /// Overall difficulty level [0, 1].
  final double level;

  /// Multiplier for time limits (< 1.0 = faster, > 1.0 = more time).
  final double timeLimitMultiplier;

  /// Number of distractor options.
  final int distractorCount;

  /// Error types to focus distractors on (most confusing options).
  final List<String> errorFocusTypes;

  /// Whether to include minimal pairs as distractors.
  final bool shouldIncludeMinimalPairs;

  /// Whether to time responses for automaticity tracking.
  final bool shouldTimeResponse;

  const GameDifficulty({
    required this.level,
    this.timeLimitMultiplier = 1.0,
    this.distractorCount = 3,
    this.errorFocusTypes = const [],
    this.shouldIncludeMinimalPairs = false,
    this.shouldTimeResponse = false,
  });

  /// Suggested time limit in seconds for a single response.
  double get suggestedTimeLimit => (5.0 + (1.0 - level) * 10.0) * timeLimitMultiplier;

  /// Returns true if difficulty should increase next round.
  bool shouldIncrease(SkillOutcome lastOutcome) {
    return lastOutcome.isCorrect &&
        lastOutcome.responseTimeSeconds < suggestedTimeLimit * 0.7;
  }

  /// Returns true if difficulty should decrease next round.
  bool shouldDecrease(SkillOutcome lastOutcome) {
    return !lastOutcome.isCorrect && lastOutcome.partialCredit < 0.3;
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'timeLimitMultiplier': timeLimitMultiplier,
        'distractorCount': distractorCount,
        'errorFocusTypes': errorFocusTypes,
        'shouldIncludeMinimalPairs': shouldIncludeMinimalPairs,
        'shouldTimeResponse': shouldTimeResponse,
        'suggestedTimeLimit': suggestedTimeLimit,
      };
}

/// Tracks the results of a complete game session.
class GameSessionResult {
  final String gameId;
  final String learnerId;
  final String languageCode;
  final List<String> skillIds;
  final List<SkillOutcome> outcomes;
  final DateTime startedAt;
  final DateTime endedAt;

  const GameSessionResult({
    required this.gameId,
    required this.learnerId,
    required this.languageCode,
    required this.skillIds,
    required this.outcomes,
    required this.startedAt,
    required this.endedAt,
  });

  int get totalResponses => outcomes.length;
  int get correctResponses => outcomes.where((o) => o.isCorrect).length;
  double get accuracy => totalResponses > 0 ? correctResponses / totalResponses : 0;
  Duration get duration => endedAt.difference(startedAt);

  double get averageResponseTime =>
      outcomes.isEmpty
          ? 0
          : outcomes.fold<double>(0, (s, o) => s + o.responseTimeSeconds) / outcomes.length;

  Set<String> get allErrorTypes =>
      outcomes.expand((o) => o.errorTypeIds).toSet();

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'learnerId': learnerId,
        'languageCode': languageCode,
        'skillIds': skillIds,
        'totalResponses': totalResponses,
        'correctResponses': correctResponses,
        'accuracy': accuracy,
        'durationSeconds': duration.inSeconds,
        'averageResponseTime': averageResponseTime,
        'allErrorTypes': allErrorTypes.toList(),
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
      };
}
