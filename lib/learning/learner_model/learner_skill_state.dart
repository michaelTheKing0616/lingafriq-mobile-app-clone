import '../scheduling/fsrs6_scheduler.dart';
import '../../services/learning/memory_state.dart';
import '../core/bkt_mastery.dart';
import 'error_taxonomy.dart';

/// The complete state of a learner's knowledge for a single skill.
///
/// This is the fundamental data structure of the learning engine.
/// Every interaction (AI tutor, game, pronunciation, review) reads
/// and writes to this state. The state drives all adaptive behavior:
/// - Which skill to practice next
/// - What difficulty level to use
/// - What type of feedback to give
/// - When to schedule the next review
class LearnerSkillState {
  /// Skill ID this state belongs to.
  final String skillId;

  /// Learner ID this state belongs to.
  final String learnerId;

  /// BKT mastery probability P(K) in [0, 1].
  /// Represents the probability that the learner has acquired this skill.
  final double mastery;

  /// HLR half-life in days.
  /// Represents memory stability — how long until recall drops to 50%.
  final double halfLifeDays;

  /// Timestamp of the last successful recall.
  final DateTime lastRecall;

  /// Timestamp of the last practice attempt (successful or not).
  final DateTime lastPractice;

  /// Error distribution vector — tracks error type frequencies.
  final ErrorDistribution errorDistribution;

  /// Performance under time pressure [0, 1].
  /// Measures automaticity — can the learner respond quickly?
  final double timePressureScore;

  /// Total number of practice attempts for this skill.
  final int totalAttempts;

  /// Number of successful attempts.
  final int successfulAttempts;

  /// Current streak of consecutive correct responses.
  final int currentStreak;

  /// BKT parameters specific to this skill instance.
  /// If null, defaults are used.
  final BktParams? bktParams;

  const LearnerSkillState({
    required this.skillId,
    required this.learnerId,
    this.mastery = 0.1,
    this.halfLifeDays = 0.5,
    required this.lastRecall,
    required this.lastPractice,
    this.errorDistribution = const ErrorDistribution(rates: {}, totalObservations: 0),
    this.timePressureScore = 0.5,
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    this.currentStreak = 0,
    this.bktParams,
  });

  /// Creates an initial state for a new skill.
  factory LearnerSkillState.initial({
    required String skillId,
    required String learnerId,
    BktParams? bktParams,
  }) {
    final now = DateTime.now();
    return LearnerSkillState(
      skillId: skillId,
      learnerId: learnerId,
      mastery: bktParams?.pL0 ?? BktMastery.defaultParams.pL0,
      halfLifeDays: 0.5,
      lastRecall: now,
      lastPractice: now,
      bktParams: bktParams,
    );
  }

  /// Current recall probability based on time elapsed since last recall.
  double get currentRecallProbability {
    final elapsed = DateTime.now().difference(lastRecall).inHours / 24.0;
    return const Fsrs6Scheduler().retrievability(
      elapsedDays: elapsed,
      stability: halfLifeDays,
    );
  }

  /// Whether this skill is considered mastered.
  bool get isMastered => BktMastery.isMastered(mastery);

  /// Whether this skill is due for review.
  bool get isDueForReview => currentRecallProbability < 0.7;

  /// Urgency of reviewing this skill (0 = not urgent, 1 = critical).
  double get reviewUrgency {
    return (1 - currentRecallProbability).clamp(0.0, 1.0);
  }

  /// Overall accuracy ratio.
  double get accuracy =>
      totalAttempts > 0 ? successfulAttempts / totalAttempts : 0.0;

  /// Whole-number mastery for results UI (P8-915).
  int masteryPercentRounded() => (mastery * 100).round().clamp(0, 100);

  /// The optimal day to schedule the next review.
  DateTime get nextOptimalReview {
    final daysUntilReview = const Fsrs6Scheduler().intervalDays(halfLifeDays, retention: 0.7).toDouble();
    return lastRecall.add(Duration(
      hours: (daysUntilReview * 24).round(),
    ));
  }

  /// The dominant error type for this skill, or null if no errors tracked.
  String? get dominantErrorType => errorDistribution.dominantError;

  /// Updates state after a practice attempt.
  ///
  /// This is the core update function that:
  /// 1. Updates BKT mastery based on correctness
  /// 2. Updates HLR half-life based on success/error severity
  /// 3. Updates error distribution
  /// 4. Updates streaks and counts
  LearnerSkillState recordAttempt({
    required bool wasCorrect,
    List<String> errorTypeIds = const [],
    double responseTimeSeconds = 0,
    double expectedTimeSeconds = 5,
  }) {
    final params = bktParams ?? BktMastery.defaultParams;
    final now = DateTime.now();

    // 1. Update BKT mastery
    final newMastery = BktMastery.updateMastery(
      currentMastery: mastery,
      wasCorrect: wasCorrect,
      params: params,
    );

    final reviewed = const Fsrs6Scheduler.days().review(
      MemoryState(
        stability: halfLifeDays,
        difficulty: 5,
        phase: FsrsPhase.review,
        lastReview: lastPractice,
      ),
      wasCorrect ? FsrsRating.good : FsrsRating.again,
      now,
    );
    final newHalfLife = reviewed.stability!;

    // 4. Update error distribution
    ErrorDistribution newErrorDist = errorDistribution;
    if (errorTypeIds.isEmpty) {
      newErrorDist = errorDistribution.recordClean();
    } else {
      for (final errorId in errorTypeIds) {
        newErrorDist = newErrorDist.recordError(errorId);
      }
    }

    // 5. Update time pressure score
    double newTimePressure = timePressureScore;
    if (responseTimeSeconds > 0 && expectedTimeSeconds > 0) {
      final timeRatio = (expectedTimeSeconds / responseTimeSeconds).clamp(0.0, 2.0);
      // Exponential moving average
      newTimePressure = timePressureScore * 0.7 + (timeRatio / 2.0) * 0.3;
      newTimePressure = newTimePressure.clamp(0.0, 1.0);
    }

    return LearnerSkillState(
      skillId: skillId,
      learnerId: learnerId,
      mastery: newMastery,
      halfLifeDays: newHalfLife,
      lastRecall: wasCorrect ? now : lastRecall,
      lastPractice: now,
      errorDistribution: newErrorDist,
      timePressureScore: newTimePressure,
      totalAttempts: totalAttempts + 1,
      successfulAttempts: successfulAttempts + (wasCorrect ? 1 : 0),
      currentStreak: wasCorrect ? currentStreak + 1 : 0,
      bktParams: bktParams,
    );
  }

  LearnerSkillState copyWith({
    double? mastery,
    double? halfLifeDays,
    DateTime? lastRecall,
    DateTime? lastPractice,
    ErrorDistribution? errorDistribution,
    double? timePressureScore,
    int? totalAttempts,
    int? successfulAttempts,
    int? currentStreak,
    BktParams? bktParams,
  }) {
    return LearnerSkillState(
      skillId: skillId,
      learnerId: learnerId,
      mastery: mastery ?? this.mastery,
      halfLifeDays: halfLifeDays ?? this.halfLifeDays,
      lastRecall: lastRecall ?? this.lastRecall,
      lastPractice: lastPractice ?? this.lastPractice,
      errorDistribution: errorDistribution ?? this.errorDistribution,
      timePressureScore: timePressureScore ?? this.timePressureScore,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successfulAttempts: successfulAttempts ?? this.successfulAttempts,
      currentStreak: currentStreak ?? this.currentStreak,
      bktParams: bktParams ?? this.bktParams,
    );
  }

  factory LearnerSkillState.fromJson(Map<String, dynamic> json) {
    return LearnerSkillState(
      skillId: json['skillId'] as String,
      learnerId: json['learnerId'] as String,
      mastery: (json['mastery'] as num).toDouble(),
      halfLifeDays: (json['halfLifeDays'] as num).toDouble(),
      lastRecall: DateTime.parse(json['lastRecall'] as String),
      lastPractice: DateTime.parse(json['lastPractice'] as String),
      errorDistribution: ErrorDistribution.fromJson(
        json['errorDistribution'] as Map<String, dynamic>? ?? {},
      ),
      timePressureScore: (json['timePressureScore'] as num?)?.toDouble() ?? 0.5,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      successfulAttempts: json['successfulAttempts'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bktParams: json['bktParams'] != null
          ? BktParams.fromJson(json['bktParams'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'learnerId': learnerId,
        'mastery': mastery,
        'halfLifeDays': halfLifeDays,
        'lastRecall': lastRecall.toIso8601String(),
        'lastPractice': lastPractice.toIso8601String(),
        'errorDistribution': errorDistribution.toJson(),
        'timePressureScore': timePressureScore,
        'totalAttempts': totalAttempts,
        'successfulAttempts': successfulAttempts,
        'currentStreak': currentStreak,
        if (bktParams != null) 'bktParams': bktParams!.toJson(),
      };
}

/// P8-932: pronunciation/tone skills must surface scorer-backed values only.
bool learnerSkillIdExpectsScorerMeasurement(String skillId) {
  final id = skillId.toLowerCase();
  return id.contains('tone') ||
      id.contains('pronunciation') ||
      id.contains('phonetic') ||
      id.contains('speaking');
}

/// How a skill row on the mastery map should render its headline value.
enum MasteryMapSkillValueKind {
  notMeasured,
  masteryPercent,
  scorerPercent,
  unsure,
}

/// Aggregated skill row for the mastery map (P8-932).
class MasteryMapSkillRow {
  const MasteryMapSkillRow({
    required this.skillId,
    required this.valueKind,
    this.masteryPercent,
    required this.gameIds,
    required this.sessionIds,
  });

  final String skillId;
  final MasteryMapSkillValueKind valueKind;
  final int? masteryPercent;
  final List<String> gameIds;
  final List<String> sessionIds;
}
