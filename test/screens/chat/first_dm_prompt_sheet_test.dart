import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/chat/first_dm_prompt_sheet.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('P9-929 inbound request exposes accept, report, and block', (tester) async {
    var accepted = false;
    await tester.pumpWidget(
      _wrap(
        FirstDmPromptSheet(
            mode: FirstDmSheetMode.inboundRequest,
            peerDisplayName: 'Amara',
            inboundIntro: 'Hi, I am in your Yoruba class.',
            onAccept: () async {
              accepted = true;
            },
            onReport: () async {},
            onBlock: () async {},
            onDecline: () async {},
          ),
        ),
    );

    expect(find.text(FirstDmCopy.requestTitle), findsOneWidget);
    expect(find.text('Hi, I am in your Yoruba class.'), findsOneWidget);
    await tester.tap(find.text(FirstDmCopy.acceptLabel));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
  });

  testWidgets('P9-929 outbound intro sends one short note', (tester) async {
    String? sent;
    await tester.pumpWidget(
      _wrap(
        FirstDmPromptSheet(
          mode: FirstDmSheetMode.outboundIntro,
          peerDisplayName: 'Bayo',
          onSendIntro: (msg) async {
            sent = msg;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hi Bayo, it is Tunde from class.');
    await tester.tap(find.text(FirstDmCopy.sendIntroLabel));
    await tester.pumpAndSettle();
    expect(sent, 'Hi Bayo, it is Tunde from class.');
  });
}
