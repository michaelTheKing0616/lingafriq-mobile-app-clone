import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';

String _fixtureJson() {
  return File('assets/data/tone/models.json').readAsStringSync();
}

void main() {
  late ToneModelsCatalog catalog;

  setUp(() {
    catalog = loadToneModelsCatalogFromJson(_fixtureJson());
  });

  group('model selection', () {
    test('Yoruba uses H/M/L with glides (AC1)', () {
      final model = resolveToneModel(catalog, 'yo');
      expect(model.systemId, 'yoruba_hml_glides');
      expect(model.levels, ['H', 'M', 'L']);
      expect(model.contourKinds, containsAll(['R', 'F']));
      expect(isToneTrainerAvailable(catalog, 'yo'), isTrue);
    });

    test('Igbo uses H/L and downstep, not 3-tone HML (AC1)', () {
      final model = resolveToneModel(catalog, 'ig');
      expect(model.levels, ['H', 'L']);
      expect(model.hasDownstep, isTrue);
      expect(model.isThreeLevelHml, isFalse);
      expect(wouldUseGlobalThreeToneFallback(catalog, 'ig'), isFalse);
    });

    test('Hausa uses H/L/F, not Yoruba mid (AC1)', () {
      final model = resolveToneModel(catalog, 'ha');
      expect(model.levels, ['H', 'L', 'F']);
      expect(model.isThreeLevelHml, isFalse);
    });

    test('Swahili is non-tonal — no trainer, no default (AC1)', () {
      expect(isToneTrainerAvailable(catalog, 'sw'), isFalse);
      expect(
        () => resolveToneModel(catalog, 'sw'),
        throwsA(isA<ToneModelMissing>().having((e) => e.code, 'code', 'ToneModelMissing')),
      );
    });
  });

  group('ToneModelMissing', () {
    test('unconfigured language hides trainer (AC2)', () {
      expect(isToneTrainerAvailable(catalog, 'tw'), isFalse);
      expect(
        () => resolveToneModel(catalog, 'tw'),
        throwsA(isA<ToneModelMissing>()),
      );
    });

    test('incomplete tonal entry fails closed (AC2)', () {
      final broken = parseToneModelsCatalog({
        'card': 'P5-027',
        'languages': {
          'yo': {'tonal': true, 'levels': ['H'], 'source_id': ''},
        },
      });
      expect(isToneTrainerAvailable(broken, 'yo'), isFalse);
      expect(() => resolveToneModel(broken, 'yo'), throwsA(isA<ToneModelMissing>()));
    });
  });
}
