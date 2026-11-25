import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/widgets/sync_status_chip.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/sync_status_chip_test.dart'),
    );
  });

  test('offline is never labelled synced', () {
    expect(
      syncVisibility(online: false, syncing: false, pending: 0, failed: 0),
      SyncVisibility.offline,
    );
    expect(
      syncVisibility(online: false, syncing: true, pending: 3, failed: 1),
      SyncVisibility.offline,
    );
    expect(
      syncVisibility(online: true, syncing: false, pending: 4, failed: 0),
      SyncVisibility.pending,
    );
    expect(
      syncVisibility(online: true, syncing: false, pending: 1, failed: 2),
      SyncVisibility.failed,
    );
    expect(
      syncVisibility(online: true, syncing: true, pending: 1, failed: 0),
      SyncVisibility.syncing,
    );
    expect(
      syncVisibility(online: true, syncing: false, pending: 0, failed: 0),
      SyncVisibility.synced,
    );
  });

  testWidgets('sync chip states match the stored golden', (WidgetTester tester) async {
    await pinSurface(tester, size: const Size(220, 320));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        home: const Scaffold(
          body: Column(
            children: [
              SyncStatusChip(online: true, syncing: false, pending: 0, failed: 0),
              SyncStatusChip(online: true, syncing: false, pending: 4, failed: 0),
              SyncStatusChip(online: true, syncing: true, pending: 4, failed: 0),
              SyncStatusChip(online: true, syncing: false, pending: 1, failed: 2),
              SyncStatusChip(online: false, syncing: false, pending: 3, failed: 0),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending 4'), findsOneWidget);
    expect(find.text('Failed 2'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    final retry = tester.getSize(find.byType(TextButton));
    expect(retry.width, greaterThanOrEqualTo(48));
    expect(retry.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel(RegExp('Offline')), findsWidgets);

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/sync_status_chip_states.png'),
    );
  });
}
