import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/report_mistake_sheet.dart';

import '../helpers/test_utils.dart';

void main() {
  group('reportMistakeCategories', () {
    test('AC2 lists exactly five categories in curriculum order', () {
      expect(
        reportMistakeCategories.map((c) => c.label).toList(),
        [
          'Wrong meaning',
          'Tone/spelling',
          'Audio',
          'Unnatural',
          'Offensive',
        ],
      );
      expect(
        reportMistakeCategories.map((c) => c.apiValue).toList(),
        [
          'wrong_meaning',
          'tone_spelling',
          'audio',
          'unnatural',
          'offensive',
        ],
      );
    });
  });

  group('ReportMistakeSheet', () {
    testWidgets('shows title and category chips with 48dp targets', (tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showReportMistakeSheet(
                  context: context,
                  itemId: 'item-1',
                  packVersion: '1.0.0',
                  submitter: ReportMistakeSubmitter(post: (_) async {}),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Report a mistake'), findsOneWidget);
      for (final category in reportMistakeCategories) {
        expect(find.text(category.label), findsOneWidget);
      }
      final chipFinder = find.ancestor(
        of: find.text('Wrong meaning'),
        matching: find.byType(ConstrainedBox),
      );
      expect(tester.getSize(chipFinder.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('successful submit closes sheet with sent outcome', (tester) async {
      ReportMistakeOutcome? outcome;
      await pumpWidgetWithScreenUtil(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                outcome = await showReportMistakeSheet(
                  context: context,
                  itemId: 'item-2',
                  packVersion: '2.0.0',
                  submitter: ReportMistakeSubmitter(post: (_) async {}),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(outcome, ReportMistakeOutcome.sent);
    });

    testWidgets('offline submit shows queued copy', (tester) async {
      final store = InMemoryContentFlagPendingStore();
      await pumpWidgetWithScreenUtil(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showReportMistakeSheet(
                  context: context,
                  itemId: 'item-3',
                  packVersion: '3.0.0',
                  submitter: ReportMistakeSubmitter(
                    post: (_) async {},
                    loadPending: store.load,
                    savePending: store.save,
                    isOnline: () async => false,
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unnatural'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('queued'), findsNothing);
      final pending = await store.load();
      expect(pending, hasLength(1));
      expect(pending.first['category'], 'unnatural');
    });

    testWidgets('online failure shows retryable error', (tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showReportMistakeSheet(
                  context: context,
                  itemId: 'item-4',
                  packVersion: '4.0.0',
                  submitter: ReportMistakeSubmitter(
                    post: (_) async {
                      throw Exception('network');
                    },
                    isOnline: () async => true,
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Offensive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Try again'), findsOneWidget);
      expect(find.text('Send report'), findsOneWidget);
    });
  });
}
