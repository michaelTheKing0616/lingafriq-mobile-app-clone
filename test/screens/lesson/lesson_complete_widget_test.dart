import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/lesson/widgets/lesson_complete_widget.dart';

Widget _wrap(Widget child, {bool reducedMotion = false}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('LessonCompleteWidget', () {
    testWidgets('animated path shows the celebration and XP, then reveals full stats on tap', (
      tester,
    ) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      var continued = false;
      await tester.pumpWidget(
        _wrap(
          LessonCompleteWidget(
            totalXP: 42,
            accuracy: 90,
            timeTaken: 125,
            bestCombo: 5,
            comboBonus: 10,
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Lesson Complete!'), findsOneWidget);
      expect(find.textContaining('+42'), findsOneWidget);

      // Let the entrance animations (pops) play out. The confetti layer
      // loops forever by design, so we deliberately avoid pumpAndSettle()
      // here -- it would never terminate while confetti is still ticking.
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Continue'));
      await tester.pump(); // Start the bottom-sheet route transition.
      await tester.pump(const Duration(milliseconds: 500)); // Let it settle.

      expect(find.textContaining('XP Earned'), findsOneWidget);
      expect(find.textContaining('Accuracy'), findsOneWidget);
      expect(continued, isFalse); // Tapping "Continue" opens the sheet first.

      // Two "Continue" buttons now exist in the tree (the celebration layer
      // behind, and the stats sheet on top) -- target the sheet's.
      await tester.tap(find.text('Continue').last);
      await tester.pump();
      expect(continued, isTrue);
    });

    testWidgets('reduced-motion path renders the full summary statically, with no tap required', (
      tester,
    ) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        _wrap(
          LessonCompleteWidget(
            totalXP: 42,
            accuracy: 90,
            timeTaken: 125,
            bestCombo: 5,
            comboBonus: 10,
            onContinue: () {},
          ),
          reducedMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      // No celebration confetti/elastic pops, but the same information is
      // immediately visible without an extra tap.
      expect(find.textContaining('Lesson Complete!'), findsOneWidget);
      expect(find.textContaining('XP Earned'), findsOneWidget);
      expect(find.textContaining('Accuracy'), findsOneWidget);
      expect(find.text('Combo Bonus: +10 XP'), findsOneWidget);
    });

    testWidgets('Continue and Share actions are accessible and Continue mirrors for RTL', (
      tester,
    ) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(
          LessonCompleteWidget(
            totalXP: 10,
            accuracy: 80,
            timeTaken: 60,
            onContinue: () {},
            onShare: () {},
          ),
          reducedMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Continue to next lesson'), findsOneWidget);
      expect(find.bySemanticsLabel('Share your result'), findsOneWidget);

      handle.dispose();
    });
  });
}
