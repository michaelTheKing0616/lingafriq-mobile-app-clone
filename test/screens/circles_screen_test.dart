import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/village/circles_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('circles empty offline state shows warm copy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => const CirclesScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your circles'), findsOneWidget);
  });
}
