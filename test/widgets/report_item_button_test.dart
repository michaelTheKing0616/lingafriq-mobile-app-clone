import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/content/item_report_service.dart';
import 'package:lingafriq/widgets/report_item_button.dart';

import '../helpers/test_utils.dart';

void main() {
  group('ReportItemButton', () {
    testWidgets('shows 48dp CTA with semantics label', (tester) async {
      final service = ItemReportService(
        post: (_) async {},
        isOnline: () async => true,
      );

      await pumpWidgetWithScreenUtil(
        tester,
        ReportItemButton(
          itemId: 'item-1',
          packVersion: '1.0.0',
          service: service,
        ),
      );
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();

      expect(find.text('This is wrong'), findsOneWidget);
      expect(find.bySemanticsLabel('Report a problem with this exercise item'), findsOneWidget);
      handle.dispose();
      final box = tester.getSize(find.bySemanticsLabel('Report a problem with this exercise item'));
      expect(box.height, greaterThanOrEqualTo(48));
    });

    testWidgets('successful submit shows sent copy not fake success on failure path',
        (tester) async {
      final service = ItemReportService(
        post: (_) async {},
        isOnline: () async => true,
      );

      await pumpWidgetWithScreenUtil(
        tester,
        ReportItemButton(
          itemId: 'item-1',
          packVersion: '2.0.0',
          service: service,
        ),
      );

      await tester.tap(find.text('This is wrong'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Wrong tone mark');
      await tester.tap(find.text('Send report'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Report sent to reviewers'), findsOneWidget);
    });

    testWidgets('offline queues and shows pending state', (tester) async {
      final store = InMemoryItemReportPendingStore();
      final service = ItemReportService(
        post: (_) async {
          throw Exception('network');
        },
        loadPending: store.load,
        savePending: store.save,
        isOnline: () async => false,
      );

      await pumpWidgetWithScreenUtil(
        tester,
        ReportItemButton(
          itemId: 'item-9',
          packVersion: '3.1.0',
          service: service,
        ),
      );

      await tester.tap(find.text('This is wrong'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bad translation');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.textContaining('saved offline'), findsOneWidget);
      expect(service.pendingCount, 1);
    });
  });

  group('ItemReportService', () {
    test('network failure enqueues without claiming sent', () async {
      final store = InMemoryItemReportPendingStore();
      var postCalls = 0;
      final service = ItemReportService(
        post: (_) async {
          postCalls++;
          throw Exception('fail');
        },
        loadPending: store.load,
        savePending: store.save,
        isOnline: () async => true,
      );

      final state = await service.submitReport(
        itemId: 'x',
        packVersion: '1.0.0',
        reason: 'issue',
      );

      expect(state, ItemReportSubmitState.queuedOffline);
      expect(postCalls, 1);
      expect(service.pendingCount, 1);
    });
  });
}
