/// One practice observation for a single skill.
///
/// The fields are the only mastery signals. [sessionLengthSeconds] stays on
/// the event so the observation can be recorded. It is not copied into a
/// learner profile and it does not change the estimate.
class MasteryEvent {
  const MasteryEvent({
    required this.skillId,
    this.correct,
    this.responseTimeSeconds,
    this.hintUsed = false,
    this.pronunciationScore,
    this.toneScore,
    this.sessionLengthSeconds,
    this.droppedOff = false,
  });

  /// Skill this observation belongs to.
  final String skillId;

  /// Whether the attempt was correct. Null skips the accuracy update.
  final bool? correct;

  /// Seconds until the learner answered. Null skips the time update.
  final double? responseTimeSeconds;

  /// True when the learner used a hint.
  final bool hintUsed;

  /// Pronunciation score in [0, 1], when a scorer produced one.
  final double? pronunciationScore;

  /// Tone score in [0, 1], when a scorer produced one.
  final double? toneScore;

  /// Session length in seconds. Kept on the event and ignored by the estimate.
  final double? sessionLengthSeconds;

  /// True when the learner left before finishing the attempt.
  final bool droppedOff;
}
