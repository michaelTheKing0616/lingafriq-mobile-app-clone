import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/grading/diacritic_grader.dart';
import 'package:lingafriq/services/learning/answer_matcher.dart';

void main() {
  const canonical = 'àárọ̀';

  test('early level accepts missing tone marks', () {
    final outcome = gradeDiacriticResponse(
      response: 'àárọ',
      correct: canonical,
      learnerLevel: 1,
    );
    expect(outcome.accepted, isTrue);
    expect(outcome.fullyCorrect, isFalse);
    expect(outcome.phase, 'diacritic-hint');
  });

  test('graded answer always exposes the marked canonical form', () {
    final partial = gradeDiacriticResponse(
      response: 'àárọ',
      correct: canonical,
      learnerLevel: 0,
    );
    expect(partial.displayCorrect, canonical);

    final exact = gradeDiacriticResponse(
      response: canonical,
      correct: canonical,
      learnerLevel: 0,
    );
    expect(exact.displayCorrect, canonical);
    expect(exact.fullyCorrect, isTrue);
  });

  test('higher learner levels tighten tone tolerance via config bands', () {
    expect(policyForLearnerLevel(0).toneLenientThroughLevel, 2);
    expect(policyForLearnerLevel(2).toneLenientThroughLevel, 2);
    expect(policyForLearnerLevel(4).toneLenientThroughLevel, 1);

    final stillLenient = gradeDiacriticResponse(
      response: 'àárọ',
      correct: canonical,
      learnerLevel: 2,
    );
    expect(stillLenient.accepted, isTrue);

    final midMissing = gradeDiacriticResponse(
      response: 'àárọ',
      correct: canonical,
      learnerLevel: 3,
    );
    expect(midMissing.accepted, isFalse);

    final advancedMissing = gradeDiacriticResponse(
      response: 'àárọ',
      correct: canonical,
      learnerLevel: 5,
    );
    expect(advancedMissing.accepted, isFalse);

    final advancedFull = gradeDiacriticResponse(
      response: canonical,
      correct: canonical,
      learnerLevel: 5,
    );
    expect(advancedFull.accepted, isTrue);
    expect(advancedFull.fullyCorrect, isTrue);
  });

  test('strict items never lenient-grade at early levels', () {
    final outcome = gradeDiacriticResponse(
      response: 'àárọ',
      correct: canonical,
      diacriticMatching: DiacriticMatching.strict,
      learnerLevel: 0,
    );
    expect(outcome.accepted, isFalse);
  });
}
