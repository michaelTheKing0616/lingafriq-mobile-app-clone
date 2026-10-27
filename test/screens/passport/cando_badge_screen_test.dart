import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/passport/cando_badge_screen.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('locked state when badge not earned', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        CanDoBadgeScreen(
          unitId: 'yoruba-A1-u1',
          canDoId: 'greet',
          canDoText: 'I can greet by time of day.',
          cefrLevel: 'A1',
          earned: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Finish the checkpoint first'), findsOneWidget);
    expect(find.textContaining('I can greet by time of day'), findsOneWidget);
  });
}
