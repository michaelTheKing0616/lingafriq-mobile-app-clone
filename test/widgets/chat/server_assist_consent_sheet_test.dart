import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/chat/server_assist_consent_sheet.dart';

void main() {
  testWidgets('P9-940 consent sheet states what is sent', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: ServerAssistConsentSheet(
              messagePreview: 'Ẹ kú àárọ̀',
              feature: ServerAssistFeature.aiGloss,
            ),
          ),
        ),
      ),
    );

    expect(find.text(ServerAssistConsentCopy.title), findsOneWidget);
    expect(find.text(ServerAssistConsentCopy.body), findsOneWidget);
    expect(find.text('Ẹ kú àárọ̀'), findsOneWidget);
    expect(find.text(ServerAssistConsentCopy.allowOnceLabel), findsOneWidget);
    expect(find.text(ServerAssistConsentCopy.declineLabel), findsOneWidget);
  });
}
