/// Session item mixing and desirable-difficulty control (P5-031, ELEVATION §6.2).
library;

/// Practice modalities required in a mixed session.
enum SessionPracticeType {
  listen,
  say,
  choose,
  build,
  translate,
}

/// Target success band for real-time difficulty steering.
const double kTargetSuccessMin = 0.80;
const double kTargetSuccessMax = 0.85;

/// How many recent outcomes inform the success-rate estimate.
const int kSuccessWindowSize = 10;

/// Step applied to [DifficultyController.targetDifficulty] when outside the band.
const double kDifficultyStep = 0.08;

/// All modalities that must appear before any type is repeated in a cycle.
const List<SessionPracticeType> kRequiredTypeRotation = SessionPracticeType.values;

/// A pool item the controller may schedule next.
class AdaptiveSessionCandidate {
  const AdaptiveSessionCandidate({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.voiceId,
  });

  final String id;
  final SessionPracticeType type;
  /// Normalised difficulty in [0, 1]; higher is harder.
  final double difficulty;
  final String voiceId;
}

/// One graded attempt in the current session.
class SessionAttemptOutcome {
  const SessionAttemptOutcome({
    required this.candidateId,
    required this.success,
    required this.difficultyAtPresentation,
  });

  final String candidateId;
  final bool success;
  final double difficultyAtPresentation;
}

/// Chooses the next item to keep type/voice variety and ~80–85% success.
///
/// Legacy fixed per-session difficulty was removed (P5-031 AC3); only
/// [targetDifficulty] adapts from recent outcomes.
class DifficultyController {
  DifficultyController({double initialTarget = 0.5})
      : targetDifficulty = initialTarget.clamp(0.0, 1.0);

  double targetDifficulty;
  final List<SessionAttemptOutcome> _outcomes = [];
  final List<SessionPracticeType> _recentTypes = [];
  final List<String> _recentVoices = [];

  List<SessionAttemptOutcome> get outcomes => List.unmodifiable(_outcomes);

  double recentSuccessRate({int? windowSize}) {
    final window = windowSize ?? kSuccessWindowSize;
    if (_outcomes.isEmpty) {
      return (kTargetSuccessMin + kTargetSuccessMax) / 2;
    }
    final slice = _outcomes.length <= window
        ? _outcomes
        : _outcomes.sublist(_outcomes.length - window);
    final successes = slice.where((o) => o.success).length;
    return successes / slice.length;
  }

  void recordOutcome(SessionAttemptOutcome outcome) {
    _outcomes.add(outcome);
    _recomputeTargetDifficulty();
  }

  void _recomputeTargetDifficulty() {
    final rate = recentSuccessRate();
    if (rate < kTargetSuccessMin) {
      targetDifficulty = (targetDifficulty - kDifficultyStep).clamp(0.0, 1.0);
    } else if (rate > kTargetSuccessMax) {
      targetDifficulty = (targetDifficulty + kDifficultyStep).clamp(0.0, 1.0);
    }
  }

  SessionPracticeType _nextPreferredType() {
    if (_recentTypes.isEmpty) {
      return kRequiredTypeRotation.first;
    }
    for (final type in kRequiredTypeRotation) {
      if (!_recentTypes.contains(type)) {
        return type;
      }
    }
    final counts = <SessionPracticeType, int>{};
    for (final t in _recentTypes) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    SessionPracticeType? leastUsed;
    var minCount = 1 << 30;
    for (final type in kRequiredTypeRotation) {
      final c = counts[type] ?? 0;
      if (c < minCount) {
        minCount = c;
        leastUsed = type;
      }
    }
    return leastUsed ?? kRequiredTypeRotation.first;
  }

  String? _lastVoice() => _recentVoices.isEmpty ? null : _recentVoices.last;

  /// Picks the next candidate from [pool] or null when empty.
  AdaptiveSessionCandidate? pickNext(List<AdaptiveSessionCandidate> pool) {
    if (pool.isEmpty) {
      return null;
    }

    final preferredType = _nextPreferredType();
    final lastVoice = _lastVoice();

    var candidates = pool.where((c) => c.type == preferredType).toList();
    if (candidates.isEmpty) {
      candidates = List.of(pool);
    }

    if (lastVoice != null) {
      final alternateVoice =
          candidates.where((c) => c.voiceId != lastVoice).toList();
      if (alternateVoice.isNotEmpty) {
        candidates = alternateVoice;
      }
    }

    candidates.sort((a, b) {
      final da = (a.difficulty - targetDifficulty).abs();
      final db = (b.difficulty - targetDifficulty).abs();
      return da.compareTo(db);
    });

    final chosen = candidates.first;
    _recentTypes.add(chosen.type);
    if (_recentTypes.length > kRequiredTypeRotation.length) {
      _recentTypes.removeAt(0);
    }
    _recentVoices.add(chosen.voiceId);
    if (_recentVoices.length > kRequiredTypeRotation.length) {
      _recentVoices.removeAt(0);
    }
    return chosen;
  }

  /// Builds a full session plan by repeatedly calling [pickNext].
  List<AdaptiveSessionCandidate> planSession(
    List<AdaptiveSessionCandidate> pool, {
    required int length,
  }) {
    final plan = <AdaptiveSessionCandidate>[];
    final remaining = List<AdaptiveSessionCandidate>.of(pool);
    for (var i = 0; i < length && remaining.isNotEmpty; i++) {
      final next = pickNext(remaining);
      if (next == null) {
        break;
      }
      plan.add(next);
      remaining.removeWhere((c) => c.id == next.id);
    }
    return plan;
  }
}
