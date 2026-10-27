import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/settings/privacy_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('voice_store_optin toggle is off by default with plain copy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: PrivacySettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Practice recordings'), findsOneWidget);
    expect(find.text('Save my practice recordings'), findsOneWidget);
    expect(find.textContaining('Off by default'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
  });
}
