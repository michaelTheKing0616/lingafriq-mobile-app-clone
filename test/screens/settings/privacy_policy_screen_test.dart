import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/settings/privacy_policy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() {
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/settings/privacy_policy_screen_test.dart'),
    );
  });

  Future<void> pumpPolicy(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            theme: ThemeData(fontFamily: goldenFontFamily),
            home: const PrivacyPolicyScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('shows version and acknowledges policy update', (tester) async {
    await pumpPolicy(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key(PrivacyPolicyScreen.privacyPolicyTitleKey)), findsOneWidget);
    expect(find.textContaining('Version 1.0.0'), findsOneWidget);
    expect(find.text('I understand'), findsOneWidget);

    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    expect(find.text('I understand'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kPrivacyPolicyAckPref), '1.0.0');
  });

  testWidgets('privacy_policy_title_golden', (tester) async {
    await pumpPolicy(tester);
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(PrivacyPolicyScreen),
      matchesGoldenFile('goldens/privacy_policy_title_golden.png'),
    );
  });
}
