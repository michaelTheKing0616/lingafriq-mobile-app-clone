import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/settings/data_export_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('data export screen shows export and delete actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: DataExportScreen(loadStatusOnMount: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your data'), findsOneWidget);
    expect(find.text('Export my data'), findsWidgets);
    expect(find.text('Delete account'), findsWidgets);
    expect(find.text('Current password'), findsOneWidget);
  });
}
