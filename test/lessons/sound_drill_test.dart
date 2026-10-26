import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/lessons/sound_drill.dart';

String _fixtureJson() {
  return File('assets/data/sound/clicks_vowels.json').readAsStringSync();
}

void main() {
  group('parseSoundDrillCatalog', () {
    test('loads xh/zu click drills with WAXAL licence (AC1)', () {
      final catalog = loadSoundDrillCatalogFromJson(_fixtureJson());
      expect(catalog.cardId, 'P5-028');

      for (final code in ['xh', 'zu']) {
        final pack = catalog.packs[code]!;
        expect(pack.waxalLicence, isNotNull);
        expect(pack.waxalLicence!.registerId, 'waxal-other');
        expect(pack.waxalLicence!.licence, contains('CC BY'));
        expect(pack.drills, isNotEmpty);
        for (final drill in pack.drills) {
          expect(drill.kind, SoundDrillKind.clickContrast);
          expect(drill.audioUri, startsWith('assets/audio/'));
        }
      }
    });

    test('loads Swahili stress and vowel drills (AC2)', () {
      final catalog = loadSoundDrillCatalogFromJson(_fixtureJson());
      final sw = soundDrillsForLanguage(catalog, 'sw');
      expect(sw.where((d) => d.kind == SoundDrillKind.stress), isNotEmpty);
      expect(sw.where((d) => d.kind == SoundDrillKind.vowelPurity), isNotEmpty);
      expect(catalog.packs['sw']!.fsiReference!.use, 'reference_only');
    });

    test('missing audio_uri fails AudioMissing (AC3)', () {
      expect(
        () => parseSoundDrillCatalog({
          'card': 'P5-028',
          'languages': {
            'sw': {
              'fsi_reference': {
                'name': 'FSI',
                'licence': 'public-domain',
                'uri_or_citation': 'register:fsi-swahili',
                'use': 'reference_only',
              },
              'drills': [
                {
                  'id': 'bad',
                  'kind': 'stress',
                  'prompt_gloss_en': 'x',
                  'correct_option_id': 'a',
                  'pair_source_id': 'register:fsi-swahili',
                  'audio_uri': '',
                  'options': [
                    {
                      'id': 'a',
                      'form': 'a',
                      'gloss_en': 'a',
                      'source_id': 'register:fsi-swahili',
                    },
                  ],
                },
              ],
            },
          },
        }),
        throwsA(isA<AudioMissing>()),
      );
    });

    test('every fixture drill has non-empty audio (content test)', () {
      final catalog = loadSoundDrillCatalogFromJson(_fixtureJson());
      for (final pack in catalog.packs.values) {
        for (final drill in pack.drills) {
          expect(drill.audioUri, isNotEmpty);
        }
      }
    });

    test('gradeSoundChoice is correct/incorrect only', () {
      final catalog = loadSoundDrillCatalogFromJson(_fixtureJson());
      final drill = soundDrillsForLanguage(catalog, 'xh').first;
      final ok = gradeSoundChoice(
        drill: drill,
        selectedOptionId: drill.correctOptionId,
      );
      expect(ok.correct, isTrue);
    });
  });

  testWidgets('SoundDrillScreen reaches result phase', (tester) async {
    final catalog = loadSoundDrillCatalogFromJson(_fixtureJson());
    final drill = soundDrillsForLanguage(catalog, 'sw').first;
    await tester.pumpWidget(
      MaterialApp(
        home: SoundDrillScreen(drill: drill),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsOneWidget);
  });
}
