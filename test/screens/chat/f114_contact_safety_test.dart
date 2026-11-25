import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/chat/contact_info_screen.dart';
import 'package:lingafriq/screens/chat/report_block_sheet.dart';

void main() {
  testWidgets('Contact info routes report and block sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const ProviderScope(
          child: MaterialApp(
            home: ContactInfoScreen(
              contactName: 'Ada',
              contactId: '42',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reportTarget = find.text('Report Ada');
    await tester.ensureVisible(reportTarget);
    await tester.tap(reportTarget);
    await tester.pumpAndSettle();

    expect(find.byType(ReportBlockSheet), findsOneWidget);
    expect(find.text('Report'), findsWidgets);
  });
}
