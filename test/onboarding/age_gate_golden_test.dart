import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/onboarding/age_gate_screen.dart';

import '../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/onboarding/age_gate_golden_test.dart'),
    );
    await loadPinnedFont();
  });

  testWidgets('age_gate_default golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const ProviderScope(
          child: MaterialApp(
            home: AgeGateScreen(deviceKeyOverride: 'golden-device'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AgeGateScreen),
      matchesGoldenFile('goldens/age_gate_default.png'),
    );
  });
}
