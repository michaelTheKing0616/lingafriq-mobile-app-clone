import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/proverb_weaver/proverb_weaver_game.dart';
import 'package:lingafriq/games/proverb_weaver/proverb_weaver_screen.dart';

Future<void> pumpWeaverPreview(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

const _fixture = ProverbWeaverRecord(
  id: 'zu.proverb.izandla',
  languageCode: 'zu',
  text: 'Izandla ziyagezana',
  translationEn: 'Hands wash each other.',
  fragments: ['Izandla', 'ziyagezana'],
  reviewedBy: 'zu-linguist-1',
  reviewerRole: 'linguist',
  sourceRef: 'register:peace-corps-zu',
  situations: const [
    ProverbSituationChoice(
      id: 'ok',
      labelEn: 'Helping each other',
      isCorrect: true,
    ),
    ProverbSituationChoice(
      id: 'no',
      labelEn: 'Refusing help',
      isCorrect: false,
    ),
  ],
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('B1 gate blocks A2 learners', () {
    expect(proverbWeaverUnlockedForLevel('A2'), isFalse);
    expect(proverbWeaverUnlockedForLevel('B1'), isTrue);
  });

  test('pool excludes proverbs without reviewer', () {
    const bad = ProverbWeaverRecord(
      id: 'x',
      languageCode: 'zu',
      text: 'a',
      translationEn: 'a',
      fragments: ['a'],
      reviewedBy: '',
      reviewerRole: 'linguist',
      sourceRef: 'r',
      situations: const [],
    );
    expect(proverbHasReviewer(bad), isFalse);
    expect(proverbHasReviewer(_fixture), isTrue);
  });

  test('fragment assembly validates order', () {
    expect(
      assemblyMatches(_fixture, ['Izandla', 'ziyagezana']),
      isTrue,
    );
    expect(
      assemblyMatches(_fixture, ['ziyagezana', 'Izandla']),
      isFalse,
    );
  });

  test('audio gate rejects synthetic paths', () {
    const synth = ProverbWeaverRecord(
      id: 'z',
      languageCode: 'zu',
      text: 't',
      translationEn: 't',
      fragments: ['t'],
      reviewedBy: 'r',
      reviewerRole: 'linguist',
      sourceRef: 's',
      humanRecordingPath: 'tts://voice',
      situations: const [],
    );
    expect(proverbAudioPlayable(synth), isFalse);
    expect(proverbAudioPlayable(_fixture), isFalse);
  });

  test('P8-924 headliner playable when card shipped', () {
    final slot = kArcadeHeadlinerOrder[4];
    expect(slot.elevationCardId, 'P8-924');
    expect(AllGamesRegistry.headlinerIsPlayable(slot), isTrue);
  });

  testWidgets('locked below B1', (tester) async {
    await pumpWeaverPreview(
      tester,
      ProverbWeaverScreen(language: 'zu', learnerLevel: 'A2'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Reach B1'), findsOneWidget);
  });

  testWidgets('proverb_weaver_playing golden', (tester) async {
    await pumpWeaverPreview(
      tester,
      ProverbWeaverPreview(
        phaseLabel: 'Playing',
        hintEn: 'Hands wash each other.',
        body: FilledButton(onPressed: () {}, child: const Text('Izandla')),
      ),
    );
    await expectLater(
      find.byType(ProverbWeaverPreview),
      matchesGoldenFile('goldens/proverb_weaver_playing.png'),
    );
  });

  testWidgets('proverb_weaver_why_wrong golden', (tester) async {
    await pumpWeaverPreview(
      tester,
      ProverbWeaverPreview(
        phaseLabel: 'Why wrong',
        hintEn: 'Read the note',
        body: const Text('That situation does not fit'),
      ),
    );
    await expectLater(
      find.byType(ProverbWeaverPreview),
      matchesGoldenFile('goldens/proverb_weaver_why_wrong.png'),
    );
  });

  testWidgets('proverb_weaver_results golden', (tester) async {
    await pumpWeaverPreview(
      tester,
      ProverbWeaverPreview(
        phaseLabel: 'Results',
        hintEn: 'Session complete',
        body: const Text('2 of 3 situations matched'),
      ),
    );
    await expectLater(
      find.byType(ProverbWeaverPreview),
      matchesGoldenFile('goldens/proverb_weaver_results.png'),
    );
  });
}
