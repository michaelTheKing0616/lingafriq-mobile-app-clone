import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/server_recognizer.dart';

void main() {
  group('parseRecognizeBody', () {
    test('maps confident recognition with model disclosure', () {
      final outcome = parseRecognizeBody({
        'ok': true,
        'result': {
          'object_set_id': 'afr.cup',
          'label': 'Cup',
          'confidence': 0.82,
          'unsure': false,
          'model': {
            'id': 'google/siglip-base-patch16-224',
            'revision': '7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed',
          },
        },
      });
      expect(outcome.phase, LensRecognizePhase.recognized);
      expect(outcome.recognition?.objectSetId, 'afr.cup');
      expect(outcome.recognition?.unsure, isFalse);
      expect(outcome.modelDisclosure, contains('siglip'));
    });

    test('low confidence maps to unsure phase', () {
      final outcome = parseRecognizeBody({
        'ok': true,
        'result': {
          'object_set_id': 'afr.chair',
          'label': 'Chair',
          'confidence': 0.12,
          'unsure': true,
          'model': {'id': 'google/siglip-base-patch16-224', 'revision': 'rev'},
        },
      });
      expect(outcome.phase, LensRecognizePhase.unsure);
      expect(outcome.recognition?.unsure, isTrue);
    });
  });

  group('LensServerRecognizer', () {
    test('candidatesFromObjectSet uses curated ids and labels', () async {
      final set = AfricanObjectSet.fromJson({
        'version': 1,
        'entries': [
          {
            'object_set_id': 'afr.book',
            'ml_kit_labels': ['Book'],
            'living_dictionary_lexeme_id': 'yo.lex.f86f9f1be056',
          },
        ],
      });
      final recognizer = LensServerRecognizer();
      final candidates = recognizer.candidatesFromObjectSet(set);
      expect(candidates, hasLength(1));
      expect(candidates.first['object_set_id'], 'afr.book');
      expect(candidates.first['labels'], ['Book']);
    });

    test('budget exhaustion surfaces retryable error', () async {
      final recognizer = LensServerRecognizer();
      final outcome = await recognizer.recognizeCrop(
        post: (_, __) async => Response(
          requestOptions: RequestOptions(path: kLensRecognizePath),
          statusCode: 429,
          data: {'ok': false, 'code': 'mode_budget_exhausted', 'retryable': true},
        ),
        imageBase64: 'aGVsbG8=',
        candidates: [
          {'object_set_id': 'afr.cup', 'labels': ['Cup']},
        ],
      );
      expect(outcome.phase, LensRecognizePhase.error);
      expect(outcome.retryable, isTrue);
    });
  });
}
