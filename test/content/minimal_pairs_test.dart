import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/tutorials/minimal_pair_demo.dart';

import '../helpers/test_utils.dart';

const _tutorialAsset = 'assets/tutorials/minimal_pairs.json';
const _drillAsset = 'assets/data/tone/minimal_pairs.json';

void main() {
  late Map<String, dynamic> packJson;
  late Map<String, dynamic> drillJson;

  setUpAll(() {
    packJson =
        jsonDecode(File(_tutorialAsset).readAsStringSync()) as Map<String, dynamic>;
    drillJson =
        jsonDecode(File(_drillAsset).readAsStringSync()) as Map<String, dynamic>;
  });

  group('minimal pair tutorial pack', () {
    test('AC1: Yoruba demo matches sourced P5-026 forms', () {
      final pack = parseMinimalPairTutorialPack(packJson);
      expect(pack.cardId, 'P7-941');
      expect(pack.demos, hasLength(1));

      final yo = pack.demos.single;
      final drills =
          ((drillJson['languages'] as Map)['yo'] as Map)['drills'] as List;
      final drill = drills.single as Map<String, dynamic>;
      final options = (drill['options'] as List).cast<Map<String, dynamic>>();
      final citedForms = options.map((o) => o['form'] as String).toSet();

      expect(yo.words.map((w) => w.form).toSet(), citedForms);
      expect(yo.words.map((w) => w.glossEn), ['hoe', 'vehicle']);
    });

    test('AC2: each word has audio URI and meaning', () {
      final pack = parseMinimalPairTutorialPack(packJson);
      for (final demo in pack.demos) {
        for (final w in demo.words) {
          expect(w.audioUri, isNotEmpty);
          expect(w.glossEn, isNotEmpty);
          expect(w.sourceId, isNotEmpty);
        }
      }
    });

    test('AC3: not publishable until native sign-off recorded', () {
      final pack = parseMinimalPairTutorialPack(packJson);
      expect(pack.signOffs, isEmpty);
      expect(minimalPairPackPublishable(pack), isFalse);
    });
  });

  group('MinimalPairDemoScreen', () {
    MinimalPairTutorialPack pack() => parseMinimalPairTutorialPack(packJson);

    Future<void> pumpDemo(
      WidgetTester tester, {
      bool isOffline = false,
      MinimalPairAudioPlayer? audioPlayer,
    }) async {
      await pumpWidgetWithScreenUtil(
        tester,
        MinimalPairDemoScreen(
          languageCode: 'yo',
          initialPack: pack(),
          isOffline: isOffline,
          audioPlayer: audioPlayer ?? (_) async {},
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('pair intro then compare shows both words', (tester) async {
      await pumpDemo(tester);
      expect(find.byKey(const ValueKey('pair-demo-intro')), findsOneWidget);
      expect(find.text('ọkọ́'), findsOneWidget);
      expect(find.text('ọkọ̀'), findsOneWidget);

      await tester.ensureVisible(find.text('Compare meanings'));
      await tester.tap(find.text('Compare meanings'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pair-demo-compare')), findsOneWidget);
      expect(find.text('hoe'), findsOneWidget);
      expect(find.text('vehicle'), findsOneWidget);
    });

    testWidgets('listen buttons invoke audio player', (tester) async {
      var played = 0;
      await pumpDemo(
        tester,
        audioPlayer: (_) async {
          played++;
        },
      );
      await tester.tap(find.text('Listen').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(played, 1);
    });

    testWidgets('offline state offers retry', (tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const MinimalPairDemoScreen(isOffline: true),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pair-demo-offline')), findsOneWidget);
    });
  });
}
