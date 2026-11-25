import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/drum_rhythm/drum_rhythm_game.dart';
import 'package:lingafriq/games/talking_drum/talking_drum_game.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_models.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';

ToneGameLexeme _lex(String id, String form, List<String> pattern) {
  return ToneGameLexeme(
    lexemeId: id,
    language: 'yo',
    toneMarkedForm: form,
    tonePattern: pattern,
    syllables: pattern,
  );
}

void main() {
  final model = const ToneLanguageModel(
    languageCode: 'yo',
    systemId: 'yo_hml',
    levels: ['H', 'M', 'L'],
    contourKinds: ['level'],
    hasDownstep: false,
    sourceId: 'models.json',
  );

  group('drum contour mapping', () {
    test('maps H/M/L to descending heights', () {
      final contour = drumContourFromTonePattern(['H', 'L'], model);
      expect(contour, [1.0, 0.0]);
    });
  });

  group('candidate generation', () {
    test('includes correct phrase and wrong-tone distractors', () {
      final correct = _lex('a', 'ọkọ́', ['H', 'M']);
      final pool = [
        correct,
        _lex('b', 'ọkọ̀', ['L', 'M']),
        _lex('c', 'ọkọ', ['M', 'M']),
      ];
      final candidates = buildTalkingDrumCandidates(
        correct: correct,
        pool: pool,
        rng: Random(1),
        minOptions: 2,
        maxOptions: 4,
      );
      expect(candidates.length, greaterThanOrEqualTo(2));
      expect(
        candidates.any((c) => c.lexemeId == 'a'),
        isTrue,
      );
    });
  });

  group('rhythm harvest', () {
    test('drum rhythm patterns are stable', () {
      expect(drumRhythmShadowPatternForTurn(0), contains('DUM'));
    });
  });

  group('local perception verdict', () {
    test('is synchronous correct check', () {
      expect(
        talkingDrumPerceptionIsCorrect(
          selectedLexemeId: 'x',
          correctLexemeId: 'x',
        ),
        isTrue,
      );
    });
  });
}
