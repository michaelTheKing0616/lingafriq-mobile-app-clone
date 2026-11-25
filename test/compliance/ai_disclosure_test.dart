import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/ai/ai_disclosure.dart';

import 'golden_kit.dart';

Widget _screen() => Scaffold(
  appBar: AppBar(title: const Text('Polie')),
  body: const Column(
    children: [
      AiDisclosureBar(),
      Expanded(child: Center(child: Text('Polie'))),
    ],
  ),
);

void main() {
  setUpAll(
    () => loadComplianceFonts('test/compliance/ai_disclosure_test.dart'),
  );

  for (final v in goldenVariants) {
    testWidgets('AI disclosure never truncates: ${v.name}', (tester) async {
      await pumpVariant(tester, v, _screen());
      expectNoLayoutErrors(tester);
      final bar = find.byKey(const ValueKey('ai-disclosure'));
      expect(tester.getSize(bar).height, greaterThanOrEqualTo(48));
      final label = find.descendant(
        of: bar,
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().length > 20,
        ),
      );
      final para = tester.renderObject<RenderParagraph>(label.first);
      expect(para.didExceedMaxLines, isFalse);
      expect(tester.widget<RichText>(label.first).maxLines, isNull);
      expect(
        tester.widget<RichText>(label.first).overflow,
        isNot(TextOverflow.ellipsis),
      );
      // Text scales with the user's setting (12sp floor at 1x).
      expect(para.textScaler.scale(13), greaterThanOrEqualTo(12 * v.scale));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/ai_disclosure_${v.name}.png'),
      );
    });
  }

  testWidgets('tap opens full explanation sheet, announced as a button', (
    tester,
  ) async {
    await pumpVariant(tester, goldenVariants.first, _screen());
    final s = tester.getSemantics(find.byKey(const ValueKey('ai-disclosure')));
    expect(s.label, contains('AI-generated'));
    expect(s.hint, 'Learn how AI is used here');
    await tester.tap(find.byKey(const ValueKey('ai-disclosure')));
    await tester.pumpAndSettle();
    expect(find.text('About AI in LingAfriq'), findsOneWidget);
    expect(find.textContaining('are not people'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ai_disclosure_sheet_ltr_390.png'),
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('About AI in LingAfriq'), findsNothing);
  });

  test('every AI-generated surface carries the disclosure', () {
    const files = [
      'lib/features/polie_workspace/build_host/polie_workspace_build_host_scaffold.dart',
      'lib/screens/persona_missions/persona_mission_session_screen.dart',
      'lib/screens/tutor/tutor_assess_mode_screen.dart',
      'lib/screens/tutor/tutor_dialogue_mode_screen.dart',
      'lib/screens/tutor/tutor_grammar_mode_screen.dart',
      'lib/screens/tutor/tutor_story_mode_screen.dart',
      'lib/screens/tutor/tutor_translation_mode_screen.dart',
      'lib/screens/tutor/tutor_pronunciation_mode_screen.dart',
    ];
    for (final f in files) {
      expect(
        File(f).readAsStringSync(),
        matches(RegExp(r'AiDisclos(ureBar|ed)\(')),
        reason: '$f lacks the AI disclosure label',
      );
    }
    expect(
      File(
        'lib/screens/personalities/personality_chat_screen.dart',
      ).readAsStringSync(),
      contains('_personaAiDisclosure'),
    );
  });
}
