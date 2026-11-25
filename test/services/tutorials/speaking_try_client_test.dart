import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';
import 'package:lingafriq/services/tutorials/speaking_try_client.dart';

void main() {
  group('unsure gate', () {
    test('low confidence maps to unsure without numeric score', () {
      final lens = parseSpeakingTryScoreBody({
        'syllables': [
          {
            'label': 'a',
            'expected_tone_label': 'H',
            'reason': 'unsure',
            'native_contour': [0, 1],
            'learner_contour': [0, 0.5],
          },
        ],
      });
      final result = speakingTryResultFromLens(lens);
      expect(result.completion, SpeakingTryCompletion.unsure);
      expect(speakingTryShouldHideNumericScore(result), isTrue);
      expect(result.syllables.single.isUnsure, isTrue);
    });

    test('retry_requested hides fabricated overall score', () {
      final lens = parseSpeakingTryScoreBody({
        'retry_requested': true,
        'syllables': [
          {
            'label': 'ọ',
            'expected_tone_label': 'M',
            'correct': true,
            'native_contour': [0, 1],
            'learner_contour': [0, 1],
          },
        ],
        'tone': {'score': 0.99},
      });
      final result = speakingTryResultFromLens(lens);
      expect(result.completion, SpeakingTryCompletion.unsure);
      expect(speakingTryShouldHideNumericScore(result), isTrue);
    });
  });

  group('skip', () {
    test('records skipped outcome with step id', () {
      const client = SpeakingTryClient();
      final record = client.recordSkip(stepId: 'lesson-yo-1-try');
      expect(record.stepId, 'lesson-yo-1-try');
      expect(record.toJson()['outcome'], 'skipped');
      expect(record.toJson()['step_id'], 'lesson-yo-1-try');
    });
  });

  group('scorer unreachable', () {
    test('503 yields typed error result', () async {
      const client = SpeakingTryClient();
      final result = await client.scoreAttempt(
        post: (_, __) async => Response(
          requestOptions: RequestOptions(path: kLensScoreUtterancePath),
          statusCode: 503,
          data: {'code': 'scorer_unavailable', 'retryable': true},
        ),
        audioPath: _testAudioPath(),
        expectedText: 'sannu',
        language: 'ha',
      );
      expect(result.completion, SpeakingTryCompletion.error);
      expect(result.retryable, isTrue);
      expect(result.errorMessage, isNotNull);
      expect(speakingTryShouldHideNumericScore(result), isTrue);
    });
  });

  group('scored path', () {
    test('correct syllables yield scored completion', () {
      final lens = parseSpeakingTryScoreBody({
        'syllables': [
          {
            'label': 'ọ',
            'expected_tone_label': 'M',
            'correct': true,
            'native_contour': [0, 1],
            'learner_contour': [0, 1],
          },
        ],
      });
      expect(lens.phase, ToneOverlayStatus.scored);
      final result = speakingTryResultFromLens(lens);
      expect(result.completion, SpeakingTryCompletion.scored);
      expect(speakingTryShouldHideNumericScore(result), isFalse);
    });
  });
}

String _testAudioPath() =>
    'test/services/tutorials/speaking_try_client_test.dart';
