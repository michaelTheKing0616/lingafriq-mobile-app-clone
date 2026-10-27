import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/word_forge/morphology_slots.dart';
import 'package:lingafriq/games/word_forge/word_forge_game.dart';
import 'package:lingafriq/games/word_forge/word_forge_screen.dart';

Future<void> pumpWordForge(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('sw templates expose four morphology slots', () {
    expect(kWordForgeTemplatesSw.first.slots, hasLength(4));
    expect(kWordForgeTemplatesZu.first.slots.first.labelEn, 'Subject concord');
  });

  test('sw slot grammar composes anakupenda', () {
    final template = kWordForgeTemplatesSw.first;
    final selection = WordForgeSelection({
      WordForgeSlotKind.subjectPrefix: optionById(template, 'sw.subj.a'),
      WordForgeSlotKind.tenseInfix: optionById(template, 'sw.tense.na'),
      WordForgeSlotKind.objectPrefix: optionById(template, 'sw.obj.ku'),
      WordForgeSlotKind.verbStem: optionById(template, 'sw.stem.penda'),
    });
    final composed = composeWordForge(selection);
    expect(composed.surface, 'anakupenda');
    final validation = validateWordForge(
      template: template,
      selection: selection,
    );
    expect(validation.isCorrect, isTrue);
  });

  test('invalid concord returns typed rule not fabricated surface', () {
    final template = kWordForgeTemplatesZu.first;
    final selection = WordForgeSelection({
      WordForgeSlotKind.subjectPrefix: optionById(template, 'zu.subj.ba'),
      WordForgeSlotKind.tenseInfix: optionById(template, 'zu.tense.ya'),
      WordForgeSlotKind.objectPrefix: optionById(template, 'zu.obj.none'),
      WordForgeSlotKind.verbStem: optionById(template, 'zu.stem.hamba'),
    });
    final validation = validateWordForge(
      template: template,
      selection: selection,
    );
    expect(validation.isCorrect, isFalse);
    expect(validation.invalidRule, contains('Class 1'));
    expect(validation.surface, isNotEmpty);
  });

  test('beta morphemes excluded from pools', () {
    final template = kWordForgeTemplatesSw.first;
    for (final slot in template.slots) {
      for (final opt in slot.poolOptions()) {
        expect(kWordForgeAllowedLabels, contains(opt.label));
      }
    }
  });

  test('session scoring counts correct rounds', () {
    final plan = buildWordForgeSession(
      languageCode: 'sw',
      rng: Random(1),
      maxRounds: 2,
    );
    final solved = <WordForgeRound>[];
    for (final round in plan.rounds) {
      final t = round.template;
      solved.add(
        withSelection(
          round,
          WordForgeSelection({
            for (final e in t.solutionBySlotKind.entries)
              e.key: optionById(t, e.value),
          }),
        ),
      );
    }
    expect(scoreWordForgeSession(solved), 2);
  });

  test('P8-926 headliner shipped in registry', () {
    expect(
      AllGamesRegistry.headlinerElevationShipped('P8-926'),
      isTrue,
    );
    expect(AllGamesRegistry.headlinerIsPlayable(kArcadeHeadlinerOrder[6]), isTrue);
  });

  testWidgets('word_forge error state for unsupported language', (tester) async {
    await pumpWordForge(
      tester,
      const WordForgeScreen(language: 'yo'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(WordForgeScreen.errorCopy), findsOneWidget);
  });
}
