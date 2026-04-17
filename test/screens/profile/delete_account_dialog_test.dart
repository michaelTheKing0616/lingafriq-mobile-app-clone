import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/tabs_view/profile/delete_account_dialogue.dart';

void main() {
  testWidgets('DeleteAccountDialog returns false when user taps No', (testTester) async {
    await testTester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => testTester.binding.setSurfaceSize(null));

    bool? result;

    await testTester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    result = await DeleteAccountDialog.showDeleteAccountDialog(context) as bool?;
                  },
                  child: const Text('open_dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await testTester.tap(find.text('open_dialog'));
    await testTester.pumpAndSettle();

    expect(find.text('No'), findsOneWidget);
    await testTester.tap(find.text('No'));
    await testTester.pumpAndSettle();

    expect(result, false);
  });

  testWidgets('DeleteAccountDialog returns true when user taps Yes', (testTester) async {
    await testTester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => testTester.binding.setSurfaceSize(null));

    bool? result;

    await testTester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    result = await DeleteAccountDialog.showDeleteAccountDialog(context) as bool?;
                  },
                  child: const Text('open_dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await testTester.tap(find.text('open_dialog'));
    await testTester.pumpAndSettle();

    await testTester.tap(find.text('Yes'));
    await testTester.pumpAndSettle();

    expect(result, true);
  });
}
