import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/passport/cat_rules_golden_test.dart'),
    );
  });

  testWidgets('cat_rules_golden', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: goldenFontFamily,
          brightness: Brightness.dark,
        ),
        home: Scaffold(
          backgroundColor: PolieColors.obsidian,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Before you begin',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: PolieColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stay in the app while you record. Use a quiet room and speak alone — we only keep audio long enough to score, then delete it.',
                    style: TextStyle(fontSize: 16, height: 1.5, color: PolieColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Max break: 10s. Voice consent is required for this proctored check.',
                    style: TextStyle(fontSize: 14, color: PolieColors.textSecondary),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PolieColors.electricTeal,
                        foregroundColor: PolieColors.obsidian,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('I understand — start'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/cat_rules_golden.png'),
    );
  });
}
