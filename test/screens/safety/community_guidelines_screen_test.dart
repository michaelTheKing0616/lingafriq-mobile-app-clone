import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/safety/community_guidelines_screen.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/safety/community_guidelines_screen_test.dart'),
    );
  });

  Future<void> pumpGuidelines(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            theme: ThemeData(fontFamily: goldenFontFamily),
            home: const CommunityGuidelinesScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('loads six rules with title', (tester) async {
    await pumpGuidelines(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byKey(const Key(CommunityGuidelinesScreen.guidelinesTitleKey)), findsOneWidget);
    expect(find.textContaining('1. Be kind'), findsOneWidget);
    expect(find.textContaining('6. Play fair'), findsOneWidget);
  });

  testWidgets('guidelines_default golden', (tester) async {
    await pumpGuidelines(tester);
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(CommunityGuidelinesScreen),
      matchesGoldenFile('goldens/guidelines_default.png'),
    );
  });
}
