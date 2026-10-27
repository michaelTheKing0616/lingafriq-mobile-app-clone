import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/greeting_gauntlet/greeting_gauntlet_game.dart';
import 'package:lingafriq/games/greeting_gauntlet/greeting_gauntlet_screen.dart';
import 'package:lingafriq/games/greeting_gauntlet/scenario_matrix.dart';

Future<void> pumpGauntletPreview(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

GauntletRound _sampleRound() {
  return GauntletRound(
    time: GauntletTimeOfDay.morning,
    person: GauntletPerson.elder,
    setting: GauntletSetting.home,
    promptEn: 'You meet your aunt in the morning. What do you say first?',
    choices: const [
      GauntletChoice(
        text: 'Ẹ kú àárọ̀',
        translationEn: 'Good morning (to elders)',
        isCorrect: true,
        gesture: CulturalGesture.kneel,
      ),
      GauntletChoice(
        text: 'Báwo ni',
        translationEn: 'How are you? (informal)',
        isCorrect: false,
        gesture: CulturalGesture.handshake,
      ),
    ],
    correctIndex: 0,
    correctGesture: CulturalGesture.kneel,
    whyWrongEn:
        '"Báwo ni" sounds too casual for an elder. Say "Ẹ kú àárọ̀" and show a respectful kneel.',
    sourceRef: 'test',
    culturalReviewFlag: true,
    correctPhraseForAudio: 'Ẹ kú àárọ̀',
  );
}

void main() {
  test('yo register matrix excludes unverified units', () {
    final raw = File('assets/data/units/register/yo.json').readAsStringSync();
    final matrix = buildVerifiedScenarioMatrix(
      languageCode: 'yo',
      registerJsonRaw: raw,
      rng: Random(0),
    );
    expect(matrix, isNotEmpty);
    expect(matrix.every((r) => r.choices.length >= 2), isTrue);
    expect(
      matrix.every((r) => r.correctGesture != CulturalGesture.waveChild || r.person == GauntletPerson.child),
      isTrue,
    );
  });

  test('gesture mapping for Yoruba elder is kneel', () {
    expect(
      gestureForLanguageAndPerson(
        languageCode: 'yo',
        person: GauntletPerson.elder,
      ),
      CulturalGesture.kneel,
    );
  });

  test('score marks timeout as incorrect', () {
    final round = _sampleRound();
    final score = scoreGauntletPick(
      round: round,
      selectedIndex: null,
      timedOut: true,
    );
    expect(score.correct, isFalse);
    expect(score.timedOut, isTrue);
  });

  testWidgets('greeting_gauntlet_playing golden', (tester) async {
    await pumpGauntletPreview(
      tester,
      GreetingGauntletPreview(
        phaseLabel: 'Playing',
        body: Text(_sampleRound().promptEn),
      ),
    );
    await expectLater(
      find.byType(GreetingGauntletPreview),
      matchesGoldenFile('goldens/greeting_gauntlet_playing.png'),
    );
  });

  testWidgets('greeting_gauntlet_why_wrong golden', (tester) async {
    await pumpGauntletPreview(
      tester,
      GreetingGauntletPreview(
        phaseLabel: 'Why wrong',
        body: Text(_sampleRound().whyWrongEn),
      ),
    );
    await expectLater(
      find.byType(GreetingGauntletPreview),
      matchesGoldenFile('goldens/greeting_gauntlet_why_wrong.png'),
    );
  });

  testWidgets('greeting_gauntlet_results golden', (tester) async {
    await pumpGauntletPreview(
      tester,
      GreetingGauntletPreview(
        phaseLabel: 'Results',
        body: const Column(
          children: [
            Text('Round complete'),
            Text('You matched 4 of 6 scenes.'),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(GreetingGauntletPreview),
      matchesGoldenFile('goldens/greeting_gauntlet_results.png'),
    );
  });
}
