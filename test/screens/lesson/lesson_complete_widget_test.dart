import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/lesson/widgets/lesson_complete_widget.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

import '../../compliance/golden_kit.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _screen({
  int xp = 42,
  double accuracy = 90,
  int questions = 6,
  bool online = true,
  bool child = false,
  int bestCombo = 5,
  int comboBonus = 10,
  VoidCallback? onContinue,
  VoidCallback? onShare,
}) => Scaffold(
  backgroundColor: PanAfricanColors.backgroundLight,
  body: LessonCompleteWidget(
    totalXP: xp,
    accuracy: accuracy,
    timeTaken: 125,
    bestCombo: bestCombo,
    comboBonus: comboBonus,
    totalQuestions: questions,
    online: online,
    childMode: child,
    onContinue: onContinue ?? () {},
    onShare: onShare ?? () {},
  ),
);

Future<void> _pump(WidgetTester t, GoldenVariant v, Widget w) async {
  await pumpVariant(t, v, w);
  await t.runAsync(() async {
    for (final a in kLessonCompleteCast) {
      await precacheImage(AssetImage(a), t.element(find.byType(Scaffold)));
    }
  });
  await t.pumpAndSettle();
}

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/lesson/lesson_complete_widget_test.dart',
    ),
  );

  for (final v in goldenVariants) {
    testWidgets('golden ${v.name}', (t) async {
      await _pump(t, v, _screen());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/lesson_complete_${v.name}.png'),
      );
    });
  }

  testWidgets('golden fr + tablet + states', (t) async {
    await _pump(
      t,
      const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
      _screen(),
    );
    expect(find.text('Leçon terminée !'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/lesson_complete_fr_390.png'),
    );
    await _pump(t, const GoldenVariant('tablet', Size(820, 1180)), _screen());
    expectNoLayoutErrors(t);
    expect(
      t.getSize(find.byKey(const Key('lc-continue'))).width,
      allOf(lessThan(520), greaterThan(380)),
      reason: 'footer buttons use the tablet column, not a narrow strip',
    );
    final footer = t.getRect(find.byKey(const Key('lc-continue')));
    expect(footer.left + footer.width / 2, closeTo(410 + 0, 120));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/lesson_complete_tablet_820.png'),
    );
    await _pump(t, goldenVariants[0], _screen(online: false, child: true));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/lesson_complete_offline_child.png'),
    );
    await _pump(
      t,
      goldenVariants[3],
      _screen(questions: 0, accuracy: 0, bestCombo: 0, comboBonus: 0),
    );
    expectNoLayoutErrors(t);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/lesson_complete_teach_only_320.png'),
    );
  });

  testWidgets('Continue fires straight away (no extra sheet step)', (t) async {
    var continued = 0;
    await _pump(t, goldenVariants[0], _screen(onContinue: () => continued++));
    await t.tap(find.byKey(const Key('lc-continue')));
    await t.pump();
    expect(continued, 1);
  });

  testWidgets('stats, run chip and combo bonus are all shown', (t) async {
    await _pump(t, goldenVariants[0], _screen());
    expect(find.text('Lesson Complete!'), findsOneWidget);
    expect(find.text('+42'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('2m 5s'), findsOneWidget);
    expect(find.text('Best run: 5 in a row'), findsOneWidget);
    expect(find.text('Combo bonus +10 XP'), findsOneWidget);
    expect(
      find.text("You're building real conversational confidence."),
      findsOneWidget,
    );
  });

  testWidgets('teach-only lesson says "Not quizzed", never 0%', (t) async {
    await _pump(t, goldenVariants[0], _screen(questions: 0, accuracy: 0));
    expect(find.text('NOT QUIZZED'), findsNothing);
    expect(find.text('Not quizzed'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('child mode hides Share; offline pauses it and says why', (
    t,
  ) async {
    var shared = 0;
    await _pump(t, goldenVariants[0], _screen(child: true));
    expect(find.byKey(const Key('lc-share')), findsNothing);
    expect(find.byKey(const Key('lc-continue')), findsOneWidget);

    await _pump(
      t,
      goldenVariants[0],
      _screen(online: false, onShare: () => shared++),
    );
    expect(find.byKey(const Key('lc-offline')), findsOneWidget);
    await t.tap(find.byKey(const Key('lc-share')));
    await t.pump();
    expect(shared, 0);

    await _pump(t, goldenVariants[0], _screen(onShare: () => shared++));
    expect(find.byKey(const Key('lc-offline')), findsNothing);
    await t.tap(find.byKey(const Key('lc-share')));
    expect(shared, 1);
  });

  testWidgets('Continue arrow grows with 200% text', (t) async {
    await _pump(t, goldenVariants[0], _screen());
    final normal = t.getSize(find.byIcon(Icons.arrow_forward_rounded)).width;
    await t.pumpWidget(const SizedBox());
    await _pump(t, goldenVariants[2], _screen());
    final big = t.getSize(find.byIcon(Icons.arrow_forward_rounded)).width;
    expect(big, greaterThanOrEqualTo(normal * 1.8));
  });

  testWidgets('a11y: labels, 48dp targets, one summary, RTL arrow', (t) async {
    final h = t.ensureSemantics();
    await _pump(t, goldenVariants[1], _screen());
    expect(find.bySemanticsLabel('المتابعة إلى الدرس التالي'), findsOneWidget);
    expect(find.bySemanticsLabel('شارك نتيجتك'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^اكتمل الدرس\\. 42')), findsOneWidget);
    // One forward arrow, mirrored by the RTL Directionality (not swapped).
    final arrow = find.byIcon(Icons.arrow_forward_rounded);
    expect(arrow, findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(Icons.arrow_forward_rounded.matchTextDirection, isTrue);
    expect(Directionality.of(t.element(arrow)), TextDirection.rtl);
    for (final k in ['lc-continue', 'lc-share']) {
      expect(t.getSize(find.byKey(Key(k))).height, greaterThanOrEqualTo(48));
    }
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  test('tile header bands carry white labels at AA', () {
    for (final c in [
      kLessonResultXp,
      kLessonResultAccuracy,
      kLessonResultTime,
    ]) {
      expect(
        _contrast(c, Colors.white),
        greaterThanOrEqualTo(4.5),
        reason: '$c',
      );
    }
  });

  testWidgets('reduced motion renders everything with no animation', (t) async {
    await pumpVariant(
      t,
      goldenVariants[0],
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _screen(),
      ),
    );
    await t.pump();
    expect(find.byKey(const Key('lc-tile-2')), findsOneWidget);
    expect(t.binding.hasScheduledFrame, isFalse);
  });
}
