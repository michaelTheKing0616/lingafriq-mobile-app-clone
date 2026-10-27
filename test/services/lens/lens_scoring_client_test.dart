import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';

void main() {
  group('parseScoreBody', () {
    test('unsure when retry_requested without numeric overall score', () {
      final outcome = parseScoreBody({
        'status': 'ok',
        'retry_requested': true,
        'syllables': [
          {
            'label': 'ọ',
            'expected_tone_label': 'M',
            'correct': true,
            'native_contour': [0, 1],
            'learner_contour': [0, 0.9],
          },
        ],
        'tone': {'score': 0.92},
      });
      expect(outcome.phase, ToneOverlayStatus.unsure);
      expect(outcome.syllables, isNotEmpty);
      expect(outcome.celebrate, isFalse);
    });

    test('celebrate when all syllables correct', () {
      final outcome = parseScoreBody({
        'status': 'scored',
        'syllables': [
          {
            'label': 'ọ',
            'expected_tone_label': 'M',
            'correct': true,
            'native_contour': [0, 1],
            'learner_contour': [0, 1],
          },
          {
            'label': 'kọ̀',
            'expected_tone_label': 'L',
            'correct': true,
            'native_contour': [1, 0],
            'learner_contour': [1, 0],
          },
        ],
      });
      expect(outcome.phase, ToneOverlayStatus.scored);
      expect(outcome.celebrate, isTrue);
    });

    test('low confidence syllable maps to unsure phase', () {
      final outcome = parseScoreBody({
        'syllables': [
          {
            'label': 'a',
            'expected_tone_label': 'H',
            'reason': 'unsure',
            'native_contour': [],
            'learner_contour': [],
          },
        ],
      });
      expect(outcome.phase, ToneOverlayStatus.unsure);
    });
  });

  group('LensScoringClient', () {
    test('uses score utterance path not tone trainer', () async {
      String? seenPath;
      final client = LensScoringClient();
      await client.scoreUtterance(
        post: (path, data) async {
          seenPath = path;
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 503,
            data: {'code': 'scorer_unavailable'},
          );
        },
        audioPath: __filePathForTest(),
        expectedText: 'ọkọ̀',
        language: 'yo',
      );
      expect(seenPath, kLensScoreUtterancePath);
    });

    test('scorer unreachable is retryable error', () async {
      final client = LensScoringClient();
      final outcome = await client.scoreUtterance(
        post: (_, __) async => Response(
          requestOptions: RequestOptions(path: kLensScoreUtterancePath),
          statusCode: 503,
          data: {'retryable': true},
        ),
        audioPath: __filePathForTest(),
        expectedText: 'sannu',
        language: 'ha',
      );
      expect(outcome.phase, ToneOverlayStatus.error);
      expect(outcome.retryable, isTrue);
      expect(outcome.errorMessage, lensSayErrorCopy);
    });
  });
}

String __filePathForTest() {
  return 'test/services/lens/lens_scoring_client_test.dart';
}
