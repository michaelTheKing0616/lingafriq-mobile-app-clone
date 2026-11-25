import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/village/clip_duet_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => child,
        ),
      ),
    );
  }

  testWidgets('ClipDuetScreen recording split shows start duet control', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      wrap(
        const ClipDuetScreen(
          sourceClipId: 'clip_test',
          sourceCaption: 'Practice greeting',
          languageTag: 'yo',
          prefetchAccess: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Start duet'), findsNWidgets(2));
    expect(find.text('Your turn'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });
}
