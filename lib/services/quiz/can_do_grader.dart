/// Conversation tasks scored against can-do statements.
///
/// A can-do is met only from a turn the scorer actually returned. There is no
/// numeric fallback when evidence is thin or the scorer did not answer.
class ConversationCopy {
  static const conv = 'Have this conversation';
  static const candos = 'Can-do statements';
  static const unavailable = 'Scoring is unavailable. Nothing was stored.';
  static const unsure = 'Not enough evidence. This can-do is not met.';
}

/// One learner turn already tied to a can-do. [confidence] and [met] stay null
/// when the scorer did not return them.
class EvidenceTurn {
  const EvidenceTurn({
    required this.id,
    required this.canDoId,
    required this.text,
    required this.scorerAvailable,
    required this.confidence,
    required this.met,
  });

  final String id;
  final String canDoId;
  final String text;
  final bool scorerAvailable;
  final double? confidence;
  final bool? met;
}

/// One can-do after grading. [status] is `met`, `not-met`, or `unsure`.
class CanDoResult {
  const CanDoResult({
    required this.canDoId,
    required this.status,
    required this.evidenceTurnIds,
  });

  final String canDoId;
  final String status;
  final List<String> evidenceTurnIds;

  bool get isMet => status == 'met';
}

/// Outcome of one conversation task.
///
/// [stored] means this grade object exists. It is never a made-up score.
/// Unsure can-dos are not met. When the scorer is unavailable, [stored] is
/// false and [results] is empty.
class ConversationGrade {
  const ConversationGrade({
    required this.phase,
    required this.results,
    required this.stored,
  });

  final String phase;
  final List<CanDoResult> results;
  final bool stored;

  /// Can-dos demonstrated by scored evidence. Unsure and not-met are excluded.
  List<String> get metCanDoIds => [
    for (final result in results)
      if (result.isMet) result.canDoId,
  ];
}

/// Confidence below this is not evidence. A missing or non-finite value is not evidence.
const double _evidenceConfidenceFloor = 0.6;

bool _isConfident(double? confidence) {
  return confidence != null &&
      confidence.isFinite &&
      confidence >= _evidenceConfidenceFloor;
}

/// Grades [canDoIds] from [turns].
///
/// Inputs are the mapped can-dos, the evidence turns, and whether the scorer
/// answered at all. Output is a [ConversationGrade]. This function does not
/// write storage and does not call a network.
///
/// When [scorerAvailable] is false the phase is `unavailable`, nothing is
/// stored, and no can-do is met. Otherwise each can-do is `met` only if a
/// matching turn was scored, with finite confidence at or above 0.6 and
/// `met` true. A scored `met: false` at that confidence is `not-met`.
/// No usable turn leaves the can-do `unsure`, which is not met.
ConversationGrade gradeConversation({
  required List<String> canDoIds,
  required List<EvidenceTurn> turns,
  required bool scorerAvailable,
}) {
  if (!scorerAvailable) {
    return const ConversationGrade(
      phase: 'unavailable',
      results: <CanDoResult>[],
      stored: false,
    );
  }

  final results = <CanDoResult>[];
  for (final canDoId in canDoIds) {
    final supportingMet = <String>[];
    final supportingNotMet = <String>[];
    for (final turn in turns) {
      if (turn.canDoId != canDoId || !turn.scorerAvailable) continue;
      if (!_isConfident(turn.confidence) || turn.met == null) continue;
      if (turn.met == true) {
        supportingMet.add(turn.id);
      } else {
        supportingNotMet.add(turn.id);
      }
    }
    if (supportingMet.isNotEmpty) {
      results.add(
        CanDoResult(
          canDoId: canDoId,
          status: 'met',
          evidenceTurnIds: List<String>.unmodifiable(supportingMet),
        ),
      );
    } else if (supportingNotMet.isNotEmpty) {
      results.add(
        CanDoResult(
          canDoId: canDoId,
          status: 'not-met',
          evidenceTurnIds: List<String>.unmodifiable(supportingNotMet),
        ),
      );
    } else {
      results.add(
        CanDoResult(
          canDoId: canDoId,
          status: 'unsure',
          evidenceTurnIds: const <String>[],
        ),
      );
    }
  }

  final everyUnsure = results.every((result) => result.status == 'unsure');
  return ConversationGrade(
    phase: everyUnsure ? 'unsure' : 'graded',
    results: List<CanDoResult>.unmodifiable(results),
    stored: true,
  );
}
