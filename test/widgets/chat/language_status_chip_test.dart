import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/chat_room_learning_service.dart';
import 'package:lingafriq/widgets/chat/language_status_chip.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('LanguageStatusChip hides when not visible to viewer', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LanguageStatusChip(
          entry: ChatLanguageStatusEntry(
            languageCode: 'yo',
            role: ChatLanguageRole.learning,
            visibleToViewer: false,
            displayName: 'Yoruba',
          ),
        ),
      ),
    );
    expect(find.text('Learning Yoruba'), findsNothing);
  });

  testWidgets('LanguageStatusChip shows learning label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LanguageStatusChip(
          entry: ChatLanguageStatusEntry(
            languageCode: 'yo',
            role: ChatLanguageRole.learning,
            visibleToViewer: true,
            displayName: 'Yoruba',
          ),
        ),
      ),
    );
    expect(find.text('Learning Yoruba'), findsOneWidget);
  });
}
