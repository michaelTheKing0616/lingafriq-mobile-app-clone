import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/learning_path/learning_path_painter.dart';
import 'package:lingafriq/widgets/learning_path/path_motion.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('PathMotion timings', () {
    test('recipe durations match REFERENCE.md', () {
      expect(PathMotion.doneGoldFill, const Duration(milliseconds: 300));
      expect(PathMotion.trailDraw, const Duration(milliseconds: 400));
      expect(PathMotion.polieHop, const Duration(milliseconds: 500));
      expect(PathMotion.unitUnlockShine, const Duration(milliseconds: 700));
      expect(PathMotion.flameBurst, const Duration(milliseconds: 600));
      expect(PathMotion.reduced, const Duration(milliseconds: 150));
    });

    test('resolve swaps to 150ms when reducedMotion', () {
      expect(
        PathMotion.resolve(PathMotion.flameBurst, reducedMotion: true),
        PathMotion.reduced,
      );
      expect(
        PathMotion.resolve(PathMotion.flameBurst, reducedMotion: false),
        PathMotion.flameBurst,
      );
    });
  });

  group('PathTrailDrawOverlay', () {
    testWidgets('exposes progress that animates to 1', (tester) async {
      await tester.pumpWidget(
        wrap(
          PathTrailDrawOverlay(
            play: true,
            reducedMotion: true,
            child: Builder(
              builder: (context) {
                final p = pathTrailDrawProgressOf(context);
                return Text('p=${p.toStringAsFixed(2)}');
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.textContaining('p=1'), findsOneWidget);
    });

    testWidgets('connector respects drawProgress', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 200,
            height: 120,
            child: PathRowConnector(
              fromLane: 0,
              toLane: 0,
              traveled: true,
              clayRoad: true,
              drawProgress: 0.4,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(PathRowConnector), findsOneWidget);
    });
  });

  group('PathUnitUnlockShine', () {
    testWidgets('plays without throwing (reduced)', (tester) async {
      await tester.pumpWidget(
        wrap(
          PathUnitUnlockShine(
            play: true,
            reducedMotion: true,
            child: Container(
              width: 200,
              height: 72,
              color: PathBrandColors.coral,
              child: const Text('Unit'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text('Unit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PathStreakFlameBurst', () {
    testWidgets('day-1 burst settles under reduced motion', (tester) async {
      await tester.pumpWidget(
        wrap(
          PathStreakFlameBurst(
            play: true,
            reducedMotion: true,
            streakCount: 1,
            child: const Icon(Icons.local_fire_department_rounded),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PathBrandColors', () {
    test('done is gold not Duo green', () {
      expect(PathBrandColors.done, PathBrandColors.gold);
      expect(PathBrandColors.done, isNot(const Color(0xFF58CC02)));
      expect(PathBrandColors.done, isNot(const Color(0xFF5BC236)));
    });
  });
}
