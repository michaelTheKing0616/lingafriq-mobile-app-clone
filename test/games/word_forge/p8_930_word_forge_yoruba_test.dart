import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/games/word_forge/morphology_slots.dart';
import 'package:lingafriq/games/word_forge/word_forge_game.dart';
import 'package:lingafriq/games/word_forge/word_forge_screen.dart';
import 'package:lingafriq/games/word_forge/yoruba_serial_verbs.dart';

import 'p8_926_word_forge_test.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('yo templates use three serial-verb slots', () {
    expect(kWordForgeTemplatesYo.first.slots, hasLength(3));
    expect(
      kWordForgeTemplatesYo.first.slots.map((s) => s.kind),
      containsAll([
        WordForgeSlotKind.yoSubject,
        WordForgeSlotKind.yoSerialV1,
        WordForgeSlotKind.yoSerialV2,
      ]),
    );
  });

  test('Mo mú wá composes with lexicon tone marks', () {
    final template = kWordForgeTemplatesYo.first;
    final selection = WordForgeSelection({
      WordForgeSlotKind.yoSubject: optionById(template, 'yo.subj.mo'),
      WordForgeSlotKind.yoSerialV1: optionById(template, 'yo.v1.mu'),
      WordForgeSlotKind.yoSerialV2: optionById(template, 'yo.v2.wa'),
    });
    final composed = composeYorubaSerial(selection);
    expect(composed.surface, 'Mo mú wá');
    final validation = validateYorubaSerial(
      template: template,
      selection: selection,
    );
    expect(validation.isCorrect, isTrue);
  });

  test('unlisted verb pair fails with grammar rule', () {
    final template = kWordForgeTemplatesYo.first;
    final selection = WordForgeSelection({
      WordForgeSlotKind.yoSubject: optionById(template, 'yo.subj.mo'),
      WordForgeSlotKind.yoSerialV1: optionById(template, 'yo.v1.lo'),
      WordForgeSlotKind.yoSerialV2: optionById(template, 'yo.v2.je'),
    });
    final validation = validateYorubaSerial(
      template: template,
      selection: selection,
    );
    expect(validation.isCorrect, isFalse);
    expect(validation.invalidRule, contains('listed serial'));
  });

  test('beta verb excluded from slot pools', () {
    final v1Slot = kYoSerialSlotDefinitions[1];
    expect(
      v1Slot.poolOptions().any((o) => o.id == 'yo.v1.je-unverified'),
      isFalse,
    );
  });

  test('yo session builds from templates', () {
    final plan = buildWordForgeSession(
      languageCode: 'yo',
      rng: Random(2),
      maxRounds: 2,
    );
    expect(plan.rounds, hasLength(2));
    expect(plan.languageCode, 'yo');
  });

  testWidgets('word_forge yo playing shows serial prompt', (tester) async {
    final template = kWordForgeTemplatesYo.first;
    await pumpWordForge(
      tester,
      WordForgeScreen(
        language: 'yo',
        initialPhase: WordForgePhase.playing,
        initialRound: WordForgeRound(
          template: template,
          selection: emptySelection(template),
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(template.promptEn), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Check form'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Check form'), findsOneWidget);
  });

  testWidgets('word_forge_yoruba_playing golden', (tester) async {
    final template = kWordForgeTemplatesYo.first;
    await pumpWordForge(
      tester,
      WordForgeScreen(
        language: 'yo',
        initialPhase: WordForgePhase.playing,
        initialRound: WordForgeRound(
          template: template,
          selection: WordForgeSelection({
            WordForgeSlotKind.yoSubject: optionById(template, 'yo.subj.mo'),
            WordForgeSlotKind.yoSerialV1: optionById(template, 'yo.v1.mu'),
            WordForgeSlotKind.yoSerialV2: optionById(template, 'yo.v2.wa'),
          }),
          roundIndex: 0,
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(WordForgeScreen),
      matchesGoldenFile('goldens/word_forge_yoruba_playing.png'),
    );
  });

  testWidgets('word_forge_yoruba_why_wrong golden', (tester) async {
    final template = kWordForgeTemplatesYo.first;
    await pumpWordForge(
      tester,
      WordForgeScreen(
        language: 'yo',
        initialPhase: WordForgePhase.wrong,
        initialRound: WordForgeRound(
          template: template,
          selection: emptySelection(template),
          roundIndex: 0,
        ),
      ),
    );
    // State-only golden: wrong pane with default copy.
    await tester.pump();
    await expectLater(
      find.byType(WordForgeScreen),
      matchesGoldenFile('goldens/word_forge_yoruba_why_wrong.png'),
    );
  });

  testWidgets('word_forge_yoruba_results golden', (tester) async {
    await pumpWordForge(
      tester,
      WordForgeScreen(
        language: 'yo',
        initialPhase: WordForgePhase.results,
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(WordForgeScreen),
      matchesGoldenFile('goldens/word_forge_yoruba_results.png'),
    );
  });
}
