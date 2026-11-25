import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/safety/appeal_screen.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppealScreen P9-932', () {
    testWidgets('appeal_default shows decision reason and submit affordance', (tester) async {
      final service = AppealService(
        isOnline: () async => true,
        get: (_) async => {
          'ok': true,
          'notices': [
            {
              'action_id': 'act-3',
              'action': 'warn',
              'reason': 'Policy reminder',
              'decided_at': DateTime.now().toIso8601String(),
              'appeal_open': true,
            },
          ],
        },
      );

      await tester.pumpWidget(_wrap(AppealScreen(appealService: service)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(AppealCopy.reasonLabel), findsOneWidget);
      expect(find.text(AppealCopy.submit), findsOneWidget);
    });

    test('submitAppeal posts to safety appeals API', () async {
      Map<String, Object?>? captured;
      final service = AppealService(
        isOnline: () async => true,
        post: (_, {data}) async {
          captured = data;
          return {'ok': true, 'appeal_id': 'ap-1'};
        },
      );
      final id = await service.submitAppeal(
        actionId: 'act-2',
        reason: 'This was a shared family device mistake',
      );
      expect(captured?['action_id'], 'act-2');
      expect(id, 'ap-1');
    });

    testWidgets('empty state when no notices', (tester) async {
      final service = AppealService(
        isOnline: () async => true,
        get: (_) async => {'ok': true, 'notices': []},
      );

      await tester.pumpWidget(_wrap(AppealScreen(appealService: service)));
      await tester.pumpAndSettle();

      expect(find.text(AppealCopy.emptyTitle), findsOneWidget);
    });

    testWidgets('a11y appeal form has semantics label', (tester) async {
      final service = AppealService(
        isOnline: () async => true,
        get: (_) async => {
          'ok': true,
          'notices': [
            {
              'action_id': 'act-3',
              'action': 'warn',
              'reason': 'Policy reminder',
              'decided_at': DateTime.now().toIso8601String(),
              'appeal_open': true,
            },
          ],
        },
      );

      await tester.pumpWidget(_wrap(AppealScreen(appealService: service)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(AppealCopy.reasonLabel), findsOneWidget);
      expect(find.text(AppealCopy.submit), findsOneWidget);
    });
  });
}
