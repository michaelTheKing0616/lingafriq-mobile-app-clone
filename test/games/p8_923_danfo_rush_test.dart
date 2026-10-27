import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/games/danfo_rush/danfo_rush_game.dart';
import 'package:lingafriq/games/danfo_rush/danfo_rush_screen.dart';
import 'package:lingafriq/games/danfo_rush/speed_curve.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';

Future<void> pumpDanfoPreview(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

const _fixtureCall = DanfoStopCall(
  callId: 'sw.stop.sokoni',
  stopLabel: 'Sokoni',
  conductorPhrase: 'Sokoni!',
  displayHintEn: 'Market',
  sourceRef: 'test',
  humanRecordingPath: 'assets/audio/test/sokoni.wav',
  speakerId: 'spk-1',
  accentTag: 'dar_es_salaam',
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('speed curve tightens with level', () {
    expect(
      danfoDecisionWindowMs(1).inMilliseconds,
      greaterThan(danfoDecisionWindowMs(8).inMilliseconds),
    );
    expect(
      danfoCallGapMs(1).inMilliseconds,
      greaterThan(danfoCallGapMs(6).inMilliseconds),
    );
  });

  test('audio filter rejects missing, TTS, and http paths', () {
    const good = _fixtureCall;
    const missing = DanfoStopCall(
      callId: 'x',
      stopLabel: 'X',
      conductorPhrase: 'X',
      displayHintEn: 'X',
      sourceRef: 'test',
    );
    const tts = DanfoStopCall(
      callId: 'y',
      stopLabel: 'Y',
      conductorPhrase: 'Y',
      displayHintEn: 'Y',
      sourceRef: 'test',
      humanRecordingPath: 'tts://synthetic',
      speakerId: 's',
      accentTag: 'a',
    );
    final filtered = filterCallsWithHumanAudio([good, missing, tts]);
    expect(filtered.length, 1);
    expect(filtered.single.callId, 'sw.stop.sokoni');
  });

  test('lexicon without recordings yields empty playable pool', () {
    expect(filterCallsWithHumanAudio(lexiconForLanguage('sw')), isEmpty);
  });

  test('round builder uses accent tags from pool', () {
    final pool = [
      _fixtureCall,
      const DanfoStopCall(
        callId: 'sw.stop.kariakoo',
        stopLabel: 'Kariakoo',
        conductorPhrase: 'Kariakoo!',
        displayHintEn: 'Market',
        sourceRef: 'test',
        humanRecordingPath: 'assets/audio/test/kariakoo.wav',
        speakerId: 'spk-2',
        accentTag: 'mombasa',
      ),
      const DanfoStopCall(
        callId: 'sw.stop.ubungo',
        stopLabel: 'Ubungo',
        conductorPhrase: 'Ubungo!',
        displayHintEn: 'Terminal',
        sourceRef: 'test',
        humanRecordingPath: 'assets/audio/test/ubungo.wav',
        speakerId: 'spk-3',
        accentTag: 'nairobi',
      ),
      const DanfoStopCall(
        callId: 'sw.stop.kinondoni',
        stopLabel: 'Kinondoni',
        conductorPhrase: 'Kinondoni!',
        displayHintEn: 'District',
        sourceRef: 'test',
        humanRecordingPath: 'assets/audio/test/kinondoni.wav',
        speakerId: 'spk-4',
        accentTag: 'arusha',
      ),
    ];
    final round = buildDanfoRound(playablePool: pool, level: 3, rng: Random(2));
    expect(round.busOptions.length, 4);
    expect(round.accentTag, isNotEmpty);
  });

  test('P8-923 headliner stays coming soon until recordings ship', () {
    final slot = kArcadeHeadlinerOrder[3];
    expect(slot.elevationCardId, 'P8-923');
    expect(AllGamesRegistry.headlinerIsPlayable(slot), isFalse);
  });

  testWidgets('recordings pending state', (tester) async {
    await pumpDanfoPreview(
      tester,
      DanfoRushScreen(language: 'sw'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('still on the way'), findsOneWidget);
  });

  testWidgets('danfo_rush_playing golden', (tester) async {
    await pumpDanfoPreview(
      tester,
      DanfoRushPreview(
        phaseLabel: 'Playing',
        conductorLine: 'Sokoni! Sokoni!',
        timerProgress: 0.72,
        body: FilledButton(onPressed: () {}, child: const Text('Sokoni')),
      ),
    );
    await expectLater(
      find.byType(DanfoRushPreview),
      matchesGoldenFile('goldens/danfo_rush_playing.png'),
    );
  });

  testWidgets('danfo_rush_why_wrong golden', (tester) async {
    await pumpDanfoPreview(
      tester,
      DanfoRushPreview(
        phaseLabel: 'Why wrong',
        conductorLine: 'Wrong bus',
        timerProgress: 0.2,
        body: const Text('Replay the call and match the stop you heard.'),
      ),
    );
    await expectLater(
      find.byType(DanfoRushPreview),
      matchesGoldenFile('goldens/danfo_rush_why_wrong.png'),
    );
  });

  testWidgets('danfo_rush_results golden', (tester) async {
    await pumpDanfoPreview(
      tester,
      DanfoRushPreview(
        phaseLabel: 'Results',
        conductorLine: 'Route complete',
        timerProgress: 1,
        body: const Text('4 of 5 stops matched'),
      ),
    );
    await expectLater(
      find.byType(DanfoRushPreview),
      matchesGoldenFile('goldens/danfo_rush_results.png'),
    );
  });
}
