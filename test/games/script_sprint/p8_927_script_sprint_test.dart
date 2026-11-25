import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/script_sprint/handwriting_recognizer.dart';
import 'package:lingafriq/games/script_sprint/script_sets.dart';
import 'package:lingafriq/games/script_sprint/script_sprint_game.dart';
import 'package:lingafriq/games/script_sprint/script_sprint_screen.dart';

Future<void> pumpScriptSprint(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

ScriptSprintSet _fixturePlayableSet() {
  final strokes = scriptSprintGeezStrokeCatalog();
  return ScriptSprintSet(
    scriptId: 'geez_fidel',
    title: "Ge'ez / Fidel",
    glyphs: const [
      ScriptSprintGlyph(
        character: '\u1200',
        romanization: 'ha',
        sourceId: 'unicode:U+1200',
        soundLabel: 'Ethiopic letter ha',
      ),
    ],
    strokeCatalog: strokes,
    recognizerReady: true,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('confidence threshold rejects unsure short traces', () {
    final catalog = scriptSprintGeezStrokeCatalog();
    final recognition = recognizeScriptSprintStroke(
      points: const [Offset(1, 1)],
      character: '\u1200',
      catalog: catalog,
    );
    expect(recognition.isUnsure, isTrue);
    expect(scriptSprintConfidenceAccepts(recognition), isFalse);
  });

  test('session builds rounds from playable set', () {
    final plan = buildScriptSprintSession(
      set: _fixturePlayableSet(),
      rng: Random(2),
      maxRounds: 2,
    );
    expect(plan.rounds, hasLength(2));
    expect(scoreScriptSprintSession(rounds: plan.rounds, results: [true, false]), 1);
  });

  test('P8-927 headliner shipped in registry', () {
    expect(AllGamesRegistry.headlinerElevationShipped('P8-927'), isTrue);
    expect(AllGamesRegistry.headlinerIsPlayable(kArcadeHeadlinerOrder[7]), isTrue);
    expect(
      AllGamesRegistry.buildHeadlinerScreen(
        gameId: 'script_sprint',
        language: 'am',
      ),
      isA<ScriptSprintScreen>(),
    );
  });

  testWidgets('script_sprint playing state shows flight lane', (tester) async {
    final set = _fixturePlayableSet();
    await pumpScriptSprint(
      tester,
      ScriptSprintScreen(
        language: 'am',
        initialPhase: ScriptSprintPhase.playing,
        initialSet: set,
      ),
    );
    await tester.pump();
    expect(find.text(ScriptSprintScreen.instructions), findsOneWidget);
    expect(find.text('\u1200'), findsOneWidget);
  });

  testWidgets('script_sprint error for unsupported language', (tester) async {
    await pumpScriptSprint(
      tester,
      const ScriptSprintScreen(
        language: 'yo',
        initialPhase: ScriptSprintPhase.error,
      ),
    );
    await tester.pump();
    expect(find.text(ScriptSprintScreen.errorCopy), findsOneWidget);
  });

  testWidgets('script_sprint script unavailable state', (tester) async {
    await pumpScriptSprint(
      tester,
      ScriptSprintScreen(
        language: 'am',
        initialPhase: ScriptSprintPhase.scriptUnavailable,
        initialSet: ScriptSprintSet(
          scriptId: 'nko',
          title: "N'Ko",
          glyphs: const [],
          strokeCatalog: scriptSprintGeezStrokeCatalog(),
          recognizerReady: false,
          unavailableReason: 'Coming later',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Coming later'), findsOneWidget);
  });
}
