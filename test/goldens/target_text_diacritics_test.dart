import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/target_text.dart';

import '../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/goldens/target_text_diacritics_test.dart'),
    );
  });

  Future<void> pumpSample(
    WidgetTester tester, {
    required double textScale,
    required String fileName,
    required String text,
    List<String>? tonePattern,
    Size surface = const Size(200, 96),
  }) async {
    await pinSurface(tester, size: surface);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: TargetText(
                text: text,
                tonePattern: tonePattern,
                debugFontFamily: goldenFontFamily,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/$fileName'),
    );
  }

  testWidgets('yo tone lens at 1.0x', (tester) async {
    await pumpSample(
      tester,
      textScale: 1.0,
      fileName: 'target_text_yo_1x.png',
      text: 'ọkọ̀',
      tonePattern: const ['M', 'L'],
    );
  });

  testWidgets('ig dot below at 2.0x', (tester) async {
    await pumpSample(
      tester,
      textScale: 2.0,
      fileName: 'target_text_ig_2x.png',
      text: 'ọ́ ẹ́',
      surface: const Size(220, 140),
    );
  });

  testWidgets('ha hooked at 1.0x', (tester) async {
    await pumpSample(
      tester,
      textScale: 1.0,
      fileName: 'target_text_ha_1x.png',
      text: 'ƙwà',
    );
  });
}
