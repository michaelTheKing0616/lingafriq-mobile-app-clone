import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/utils/diacritics_enforcer.dart';

void main() {
  group('DiacriticsEnforcer P6-026', () {
    test('lexicon-only mode applies exact phrase match', () {
      final result = DiacriticsEnforcer.enforceWithMetadata(
        'e kaaro',
        'yoruba',
        patchModelOutput: false,
      );
      expect(result['changed'], isTrue);
      expect(result['text'], 'Ẹ káàrọ̀');
    });

    test('lexicon-only mode does not fuzzy-patch arbitrary model text', () {
      final result = DiacriticsEnforcer.enforceWithMetadata(
        'Mo n lo si ile',
        'yoruba',
        patchModelOutput: false,
      );
      expect(result['changed'], isFalse);
      expect(result['text'], 'Mo n lo si ile');
    });

    test('legacy patch mode still token-corrects when enabled', () {
      final result = DiacriticsEnforcer.enforceWithMetadata(
        'e kaaro',
        'yoruba',
        patchModelOutput: true,
      );
      expect(result['changed'], isTrue);
      expect(result['text'], 'Ẹ káàrọ̀');
    });
  });
}
