import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/gamification/gamification_widgets.dart';

void main() {
  testWidgets('CowriesBalanceChip exposes semantics label', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await ScreenUtil.ensureScreenSize();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(body: CowriesBalanceChip(amount: 1200)),
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Cowries balance')), findsOneWidget);
      expect(find.text('1.2K'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
