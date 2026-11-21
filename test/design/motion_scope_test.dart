import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/motion/motion_scope.dart';
import 'package:lingafriq/design/tokens.g.dart';

void main() {
  test(
    'reduced motion stays within the slow token and motion off keeps fast',
    () {
      final LingMotionPlan reduced = LingMotionPlan.resolve(reduced: true);
      final LingMotionPlan open = LingMotionPlan.resolve(reduced: false);
      expect(reduced.reduced, isTrue);
      expect(reduced.move, LingMotionMove.fade);
      expect(reduced.duration.inMilliseconds, inInclusiveRange(1, 300));
      expect(
        reduced.duration.inMilliseconds,
        lessThanOrEqualTo(LingAfriqTokens.motionProductSlow),
      );
      expect(
        reduced.duration.inMilliseconds,
        LingAfriqTokens.motionProductSlow,
      );
      expect(
        reduced.duration.inMilliseconds,
        lessThan(LingAfriqTokens.motionRareLessonComplete),
      );
      expect(
        reduced.duration.inMilliseconds,
        lessThan(LingAfriqTokens.motionRareLevelUp),
      );
      expect(open.reduced, isFalse);
      expect(open.duration.inMilliseconds, LingAfriqTokens.motionProductFast);
      expect(open.duration.inMilliseconds, lessThanOrEqualTo(300));
      expect(reduced.duration, greaterThan(open.duration));

      final LingMotionPlan chosen = LingMotionPlan.resolve(
        reduced: false,
        fast: const Duration(
          milliseconds: LingAfriqTokens.motionProductInstant,
        ),
      );
      expect(
        chosen.duration.inMilliseconds,
        LingAfriqTokens.motionProductInstant,
      );

      final LingMotionPlan rareIgnored = LingMotionPlan.resolve(
        reduced: true,
        fast: const Duration(milliseconds: LingAfriqTokens.motionRareLevelUp),
        move: LingMotionMove.scale,
      );
      expect(rareIgnored.move, LingMotionMove.scale);
      expect(
        rareIgnored.duration.inMilliseconds,
        LingAfriqTokens.motionProductSlow,
      );
      expect(rareIgnored.duration.inMilliseconds, lessThanOrEqualTo(300));

      final LingMotionPlan blankFast = LingMotionPlan.resolve(
        reduced: false,
        fast: Duration.zero,
      );
      expect(
        blankFast.duration.inMilliseconds,
        LingAfriqTokens.motionProductFast,
      );
    },
  );

  test('the scope source reads the setting and the slow token', () {
    final String source = File(
      'lib/design/motion/motion_scope.dart',
    ).readAsStringSync();
    expect(source.contains('MediaQuery.disableAnimationsOf'), isTrue);
    expect(source.contains('LingAfriqTokens.motionProductSlow'), isTrue);
    expect(source.contains('TweenAnimationBuilder'), isTrue);
    expect(source.contains('LingAfriqTokens.motionProductFast'), isTrue);
  });

  testWidgets('reduced motion fades a celebration to a visible end state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        reduced: true,
        child: const LingMotionScope(child: Text('Lesson complete')),
      ),
    );

    expect(find.text('Lesson complete'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LingMotionScope.fadeMark),
        matching: find.text('Lesson complete'),
      ),
      findsOneWidget,
    );
    final Opacity opening = tester.widget<Opacity>(
      find.byKey(LingMotionScope.fadeMark),
    );
    expect(opening.opacity, greaterThan(0));
    expect(opening.opacity, lessThan(1));

    final TweenAnimationBuilder<double> motion = tester
        .widget<TweenAnimationBuilder<double>>(
          find.byType(TweenAnimationBuilder<double>),
        );
    expect(motion.duration.inMilliseconds, inInclusiveRange(1, 300));
    expect(
      motion.duration.inMilliseconds,
      lessThanOrEqualTo(LingAfriqTokens.motionProductSlow),
    );
    expect(motion.duration.inMilliseconds, LingAfriqTokens.motionProductSlow);
    final Cubic curve = motion.curve as Cubic;
    expect(curve.a, closeTo(0.23, 0.0001));
    expect(curve.b, closeTo(1, 0.0001));
    expect(curve.c, closeTo(0.32, 0.0001));
    expect(curve.d, closeTo(1, 0.0001));

    final LingMotionPlan plan = LingMotionScope.of(
      tester.element(find.text('Lesson complete')),
    );
    expect(plan.reduced, isTrue);
    expect(plan.duration, motion.duration);
    expect(plan.duration.inMilliseconds, lessThanOrEqualTo(300));

    await tester.pump(motion.duration);
    final Opacity settled = tester.widget<Opacity>(
      find.byKey(LingMotionScope.fadeMark),
    );
    expect(settled.opacity, 1);
    expect(find.text('Lesson complete'), findsOneWidget);
    expect(tester.getSize(find.text('Lesson complete')).height, greaterThan(0));

    await tester.pump(const Duration(seconds: 2));
    final Opacity held = tester.widget<Opacity>(
      find.byKey(LingMotionScope.fadeMark),
    );
    expect(held.opacity, 1);
    expect(find.text('Lesson complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion scales a transition and keeps the end state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        reduced: true,
        child: const LingMotionScope(
          move: LingMotionMove.scale,
          fast: Duration(
            milliseconds: LingAfriqTokens.motionRareLessonComplete,
          ),
          child: Text('Word card'),
        ),
      ),
    );

    expect(find.text('Word card'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LingMotionScope.scaleMark),
        matching: find.text('Word card'),
      ),
      findsOneWidget,
    );
    final Transform opening = tester.widget<Transform>(
      find.byKey(LingMotionScope.scaleMark),
    );
    expect(opening.transform.entry(0, 0), greaterThan(0));
    expect(opening.transform.entry(0, 0), lessThan(1));

    final LingMotionPlan plan = LingMotionScope.of(
      tester.element(find.text('Word card')),
    );
    expect(plan.reduced, isTrue);
    expect(plan.move, LingMotionMove.scale);
    expect(plan.duration.inMilliseconds, LingAfriqTokens.motionProductSlow);
    expect(
      plan.duration.inMilliseconds,
      lessThan(LingAfriqTokens.motionRareLessonComplete),
    );

    await tester.pump(plan.duration);
    final Transform settled = tester.widget<Transform>(
      find.byKey(LingMotionScope.scaleMark),
    );
    expect(settled.transform.entry(0, 0), 1);
    expect(find.text('Word card'), findsOneWidget);
    expect(tester.getSize(find.text('Word card')).height, greaterThan(0));

    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<Transform>(find.byKey(LingMotionScope.scaleMark))
          .transform
          .entry(0, 0),
      1,
    );
    expect(find.text('Word card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('motion off leaves the fast duration and shows the child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        reduced: false,
        child: const LingMotionScope(child: Text('Lesson complete')),
      ),
    );

    expect(find.text('Lesson complete'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.byKey(LingMotionScope.fadeMark), findsNothing);
    expect(find.byKey(LingMotionScope.scaleMark), findsNothing);
    expect(tester.getSize(find.text('Lesson complete')).height, greaterThan(0));

    final LingMotionPlan plan = LingMotionScope.of(
      tester.element(find.text('Lesson complete')),
    );
    expect(plan.reduced, isFalse);
    expect(plan.duration.inMilliseconds, LingAfriqTokens.motionProductFast);
    expect(plan.duration.inMilliseconds, lessThanOrEqualTo(300));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _host(
        reduced: false,
        child: const LingMotionScope(
          fast: Duration(milliseconds: LingAfriqTokens.motionProductInstant),
          child: Text('Level up'),
        ),
      ),
    );
    final LingMotionPlan chosen = LingMotionScope.of(
      tester.element(find.text('Level up')),
    );
    expect(chosen.reduced, isFalse);
    expect(
      chosen.duration.inMilliseconds,
      LingAfriqTokens.motionProductInstant,
    );
    expect(find.text('Level up'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('200 percent text still shows the settled celebration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        reduced: true,
        textScale: 2,
        child: const LingMotionScope(child: Text('You said the greeting.')),
      ),
    );
    await tester.pump(
      const Duration(milliseconds: LingAfriqTokens.motionProductSlow),
    );
    expect(find.text('You said the greeting.'), findsOneWidget);
    expect(
      tester.widget<Opacity>(find.byKey(LingMotionScope.fadeMark)).opacity,
      1,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  required bool reduced,
  required Widget child,
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (BuildContext context, Widget? built) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: built ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(body: child),
  );
}
