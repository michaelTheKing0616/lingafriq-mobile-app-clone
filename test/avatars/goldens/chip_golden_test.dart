import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';
import 'package:lingafriq/avatars/cast/cast_stage.dart';
import 'package:rive/rive.dart';

import '../../golden/golden_harness.dart';

/// P11-040: CharacterChip goldens at 32 / 48 / 64 px for each expression state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const chipExpressions = <String>[
    'neutral',
    'happy',
    'encouraging',
    'thinking',
    'concerned',
  ];
  const sizes = <double>[32, 48, 64];

  // rootBundle caches string futures; one settled in an earlier test's
  // zone never resumes under this test's fake clock, so start fresh.
  setUp(rootBundle.clear);

  setUpAll(() async {
    await RiveNative.init();
    CastFileCache.instance.renderer = Factory.flutter;
    await CastFileCache.instance.load(); // warm the decoded .riv in real time
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/avatars/goldens/chip_golden_test.dart'),
    );
  });

  for (final expression in chipExpressions) {
    for (final size in sizes) {
      testWidgets(
        'CharacterChip $expression at ${size.toInt()}px golden',
        (tester) async {
          final session = CastSession(preset: 'Polie');
          addTearDown(session.dispose);
          session.expression(expression, 0.85);
          session.reducedMotion(true);

          await pinSurface(tester, size: Size.square(size + 8));
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: Center(
                    child: RepaintBoundary(
                      key: ValueKey('chip-$expression-$size'),
                      child: CastChip(session: session, size: size),
                    ),
                  ),
                ),
              ),
            ),
          );
          await _untilRive(tester);
          session.expression(expression, 0.85);
          final widget = tester.widget<RiveWidget>(find.byType(RiveWidget));
          widget.controller.active = false;
          await tester.pump();

          expect(tester.getSize(find.byType(CastChip)), Size.square(size));
          await expectLater(
            find.byKey(ValueKey('chip-$expression-$size')),
            matchesGoldenFile(
              'goldens/chip_${expression}_${size.toInt()}.png',
            ),
          );
        },
      );
    }
  }
}

Future<void> _untilRive(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    // Let real-time asset futures settle; the fake clock cannot run them.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(RiveWidget).evaluate().isNotEmpty) return;
  }
  fail('CharacterChip did not produce a RiveWidget');
}
