import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/griot/griot_chip.dart';
import 'package:rive/rive.dart' as rive;

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/golden_harness_test.dart'),
    );
  });

  test('a pixel diff above the threshold is not a pass', () async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      await solidPng(const Color(0xFFFF0000)),
      await solidPng(const Color(0xFF00FF00)),
    );
    expect(result.diffPercent, greaterThan(goldenDiffTolerance));
    expect(result.passed, isFalse);
    result.dispose();
  });

  testWidgets('design-system chip matches the stored golden', (WidgetTester tester) async {
    await pinSurface(tester);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            theme: ThemeData(
              fontFamily: goldenFontFamily,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF8C4A2F),
                onPrimary: Color(0xFFFFF8F0),
                surfaceContainerHighest: Color(0xFFE7DDD0),
                onSurfaceVariant: Color(0xFF322E25),
              ),
            ),
            home: const Scaffold(
              body: Center(
                child: GriotChip(label: 'Yoruba', selected: true),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await expectLater(
      find.byType(GriotChip),
      matchesGoldenFile('goldens/griot_chip_selected.png'),
    );
  });

  testWidgets('Rive character chip captures frame zero', (WidgetTester tester) async {
    await rive.RiveNative.init();
    final rive.File file = (await rive.File.decode(
      File('assets/rive/lingafriq_cast.riv').readAsBytesSync(),
      riveFactory: rive.Factory.flutter,
    ))!;
    final rive.RiveWidgetController controller = rive.RiveWidgetController(
      file,
      artboardSelector: const rive.ArtboardNamed('CharacterChip'),
      stateMachineSelector: const rive.StateMachineNamed('CharacterSM'),
    );
    controller.active = false;

    await pinSurface(tester, size: const Size(64, 64));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: rive.RiveWidget(
                controller: controller,
                fit: rive.Fit.contain,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(rive.RiveWidget),
      matchesGoldenFile('goldens/character_chip_frame0.png'),
    );
    controller.dispose();
  });
}
