/// Level-aware lenient diacritic grading for path lessons (P5-043, EP-§6.7-08/09).
library;

import 'package:lingafriq/services/learning/answer_matcher.dart';

/// Inclusive learner path level ceiling for a [DiacriticGradingPolicy.toneLenientThroughLevel].
class DiacriticGradingBand {
  const DiacriticGradingBand({
    required this.upToLearnerLevel,
    required this.toneLenientThroughLevel,
  });

  final int upToLearnerLevel;
  final int toneLenientThroughLevel;
}

/// Ordered bands: first match wins. Tolerance tightens as the learner advances.
const List<DiacriticGradingBand> kDiacriticGradingBands = [
  DiacriticGradingBand(upToLearnerLevel: 2, toneLenientThroughLevel: 2),
  DiacriticGradingBand(upToLearnerLevel: 4, toneLenientThroughLevel: 1),
  DiacriticGradingBand(upToLearnerLevel: 999, toneLenientThroughLevel: 0),
];

DiacriticGradingPolicy policyForLearnerLevel(int learnerLevel) {
  for (final band in kDiacriticGradingBands) {
    if (learnerLevel <= band.upToLearnerLevel) {
      return DiacriticGradingPolicy(toneLenientThroughLevel: band.toneLenientThroughLevel);
    }
  }
  return DiacriticGradingPolicy.defaults;
}

class DiacriticGradeOutcome {
  const DiacriticGradeOutcome({
    required this.accepted,
    required this.fullyCorrect,
    required this.displayCorrect,
    required this.policy,
  });

  final bool accepted;
  final bool fullyCorrect;

  /// Canonical marked form shown after submission (EP-§6.7-09).
  final String displayCorrect;
  final DiacriticGradingPolicy policy;

  String get phase {
    if (fullyCorrect) return 'correct';
    if (accepted) return 'diacritic-hint';
    return 'wrong';
  }
}

DiacriticGradeOutcome gradeDiacriticResponse({
  required String response,
  required String correct,
  List<String> acceptedVariants = const [],
  DiacriticMatching diacriticMatching = DiacriticMatching.toneLenient,
  required int learnerLevel,
}) {
  final policy = policyForLearnerLevel(learnerLevel);
  final match = matchLearnerAnswer(
    response: response,
    spec: V2AnswerSpec(
      correct: correct,
      acceptedVariants: acceptedVariants,
      diacriticMatching: diacriticMatching,
    ),
    learnerLevel: learnerLevel,
    policy: policy,
  );
  return DiacriticGradeOutcome(
    accepted: match.accepted,
    fullyCorrect: match.fullyCorrect,
    displayCorrect: match.displayCorrect,
    policy: policy,
  );
}
