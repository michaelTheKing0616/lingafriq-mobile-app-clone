import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/dialect_preference.dart';
import 'package:lingafriq/services/content/dialect_resolver.dart';

void main() {
  group('DialectPreference.migrateStoredTag', () {
    test('maps legacy short tag to canonical dialect id', () {
      expect(DialectPreference.migrateStoredTag('yo', 'lagos'), 'yo-lagos');
      expect(DialectPreference.migrateStoredTag('yo', 'yo-lagos'), 'yo-lagos');
      expect(DialectPreference.migrateStoredTag('ig', 'standard'), 'standard');
    });

    test('v1 prefs key differs from legacy key', () {
      expect(DialectPreference.prefsKeyV1('YO'), 'learning_dialect_preferred_tag_v1_yo');
      expect(DialectPreference.legacyPrefsKey('yo'), 'learning_dialect_preferred_tag_yo');
    });
  });

  group('DialectResolver', () {
    const labels = {
      'yo-lagos': 'Lagos accent',
      'yo-ibadan': 'Ibadan accent',
    };

    final standard = {
      'umbrella_language': 'yo',
      'lemma': 'ọkọ̀',
      'form_kind': 'standard',
    };

    final regional = [
      {
        'dialect_tag': 'yo-lagos',
        'region': 'Lagos State',
        'lemma': 'ọkọ̀',
        'form_kind': 'regional',
      },
    ];

    test('returns matching regional variant', () {
      final resolver = DialectResolver(dialectLabels: labels);
      final result = resolver.resolve(
        preferredDialectId: 'yo-lagos',
        standardEntry: standard,
        regionalVariants: regional,
      );
      expect(result.usedPreferredDialect, isTrue);
      expect(result.entry['form_kind'], 'regional');
      expect(result.uiDialectLabel, 'Lagos accent');
    });

    test('falls back to standard with dialect UI label', () {
      final resolver = DialectResolver(dialectLabels: labels);
      final result = resolver.resolve(
        preferredDialectId: 'yo-ibadan',
        standardEntry: standard,
        regionalVariants: regional,
      );
      expect(result.usedPreferredDialect, isFalse);
      expect(result.entry['form_kind'], 'standard');
      expect(result.uiDialectLabel, 'Ibadan accent');
    });
  });
}
