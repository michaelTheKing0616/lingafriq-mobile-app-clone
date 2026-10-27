import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_detector.dart';

AfricanObjectSet _loadFixtureSet() {
  final path = File(
    'assets/lens/african_object_set.json',
  ).absolute;
  final json =
      jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
  final set = AfricanObjectSet.fromJson(json);
  AfricanObjectSet.validateContent(set);
  return set;
}

void main() {
  late ObjectSetMapper mapper;
  late LensOnDeviceDetector detector;

  setUp(() {
    final set = _loadFixtureSet();
    mapper = ObjectSetMapper(set);
    detector = LensOnDeviceDetector(mapper: mapper);
  });

  group('ObjectSetMapper', () {
    test('maps Cup to curated object set id and lexeme id', () {
      final m = mapper.mapLabel('Cup');
      expect(m.kind, LensLabelMappingKind.mapped);
      expect(m.objectSetId, 'afr.cup');
      expect(m.livingDictionaryLexemeId, 'yo.lex.ọkọ.vehicle');
    });

    test('Food is coarse Unsure without a word', () {
      final m = mapper.mapLabel('Food');
      expect(m.kind, LensLabelMappingKind.coarseUnsure);
      expect(m.isUnsure, isTrue);
      expect(m.objectSetId, isNull);
    });

    test('unknown label is unmapped Unsure', () {
      final m = mapper.mapLabel('Satellite dish');
      expect(m.kind, LensLabelMappingKind.unmapped);
      expect(m.isUnsure, isTrue);
    });

    test('content check rejects missing lexeme id', () {
      expect(
        () => AfricanObjectSet.validateContent(
          AfricanObjectSet(
            version: 1,
            entries: [
              AfricanObjectSetEntry(
                objectSetId: 'afr.bad',
                mlKitLabels: ['X'],
                livingDictionaryLexemeId: '',
              ),
            ],
          ),
        ),
        throwsFormatException,
      );
    });
  });

  group('LensOnDeviceDetector', () {
    test('display label is Unsure for coarse categories', () {
      final mapped = detector.mapFrameLabels(['Home good']);
      expect(mapped.single.displayLabel, 'Unsure');
      expect(mapped.single.offersServerFallback, isTrue);
    });

    test('timeout offers server fallback and no fake labels', () async {
      final results = await detector.detectWithTimeout(() async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return ['Cup'];
      });
      expect(results, isEmpty);
      expect(detector.shouldOfferServerFallback, isTrue);
      expect(detector.sessionState, LensDetectionSessionState.timedOut);
    });

    test('successful detect maps labels', () async {
      final results = await detector.detectWithTimeout(
        () async => ['Chair', 'Food'],
      );
      expect(results.length, 2);
      expect(results[0].mapping.objectSetId, 'afr.chair');
      expect(results[1].displayLabel, 'Unsure');
    });
  });
}
