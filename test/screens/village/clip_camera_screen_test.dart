import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/village/clip_camera_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ClipCameraScreen shows record affordance and duration hint', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => const ClipCameraScreen(loadCirclesOnInit: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Share a clip'), findsOneWidget);
    expect(find.textContaining('15–60 sec'), findsOneWidget);
    expect(find.bySemanticsLabel('Record video clip'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });
}
