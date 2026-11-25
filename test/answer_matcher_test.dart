import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/answer_matcher.dart';

void main() {
  const specLenient = V2AnswerSpec(
    correct: 'àárọ̀',
    acceptedVariants: const ['aaro', 'àárọ'],
    diacriticMatching: DiacriticMatching.toneLenient,
  );

  test('early level accepts missing tone marks under tone_lenient', () {
    final result = matchLearnerAnswer(
      response: 'àárọ',
      spec: specLenient,
      learnerLevel: 1,
    );
    expect(result.accepted, isTrue);
    expect(result.fullyCorrect, isFalse);
    expect(result.phase, 'diacritic-hint');
    expect(result.displayCorrect, 'àárọ̀');
  });

  test('displayCorrect always shows the marked canonical form', () {
    final exact = matchLearnerAnswer(
      response: 'àárọ̀',
      spec: specLenient,
      learnerLevel: 0,
    );
    expect(exact.displayCorrect, 'àárọ̀');

    final wrong = matchLearnerAnswer(
      response: 'xyz',
      spec: specLenient,
      learnerLevel: 0,
    );
    expect(wrong.displayCorrect, 'àárọ̀');
  });

  test('higher levels require tone marks for tone_lenient items', () {
    const strictLater = V2AnswerSpec(
      correct: 'àárọ̀',
      acceptedVariants: const [],
      diacriticMatching: DiacriticMatching.toneLenient,
    );
    final missingTone = matchLearnerAnswer(
      response: 'àárọ',
      spec: strictLater,
      learnerLevel: 4,
    );
    expect(missingTone.accepted, isFalse);

    final full = matchLearnerAnswer(
      response: 'àárọ̀',
      spec: strictLater,
      learnerLevel: 4,
    );
    expect(full.accepted, isTrue);
    expect(full.fullyCorrect, isTrue);
  });

  test('ascii fallback only passes under diacritic_insensitive or listed variants', () {
    final lenientEarly = matchLearnerAnswer(
      response: 'aaro',
      spec: const V2AnswerSpec(
        correct: 'àárọ̀',
        acceptedVariants: const [],
        diacriticMatching: DiacriticMatching.toneLenient,
      ),
      learnerLevel: 0,
    );
    expect(lenientEarly.accepted, isFalse);

    final viaVariant = matchLearnerAnswer(
      response: 'aaro',
      spec: specLenient,
      learnerLevel: 0,
    );
    expect(viaVariant.accepted, isTrue);

    final insensitive = matchLearnerAnswer(
      response: 'aaro',
      spec: const V2AnswerSpec(
        correct: 'àárọ̀',
        acceptedVariants: const [],
        diacriticMatching: DiacriticMatching.diacriticInsensitive,
      ),
      learnerLevel: 5,
    );
    expect(insensitive.accepted, isTrue);
  });

  test('strict mode rejects tone-dropped forms at every level', () {
    final result = matchLearnerAnswer(
      response: 'àárọ',
      spec: const V2AnswerSpec(
        correct: 'àárọ̀',
        acceptedVariants: const [],
        diacriticMatching: DiacriticMatching.strict,
      ),
      learnerLevel: 0,
    );
    expect(result.accepted, isFalse);
  });

  test('parseDiacriticMatching maps v2 schema strings', () {
    expect(parseDiacriticMatching('tone_lenient'), DiacriticMatching.toneLenient);
    expect(parseDiacriticMatching('diacritic_insensitive'), DiacriticMatching.diacriticInsensitive);
  });
}
