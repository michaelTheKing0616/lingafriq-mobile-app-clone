import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/lesson_download_service.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/services/offline/offline_resilience_harness.dart';
import 'package:lingafriq/services/offline/point_and_say_queue_service.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/services/sync/outbox_worker.dart';

import 'network_fault_injector.dart';

void main() {
  group('P12-019 chaos / offline resilience', () {
    test('AC1 airplane mode: downloads gate, Point & Say queue, review outbox persist', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      });

      expect(
        downloadGate(wifiOnly: true, onWifi: false, allowMobile: false, lowStorage: false),
        DownloadGate.waitForWifi,
      );

      await LocalDatabaseService().init();
      await LocalDatabaseService().clearAll();

      final audioDir = await Directory.systemTemp.createTemp('p12-019-pas-');
      final audioFile = File('${audioDir.path}/clip.wav');
      await audioFile.writeAsBytes(const [0, 1, 2]);

      final pasId = await PointAndSayQueueService.instance.enqueue(
        language: 'yo',
        expectedText: 'Ẹ kú àárọ̀',
        audioPath: audioFile.path,
        evaluateTone: false,
      );
      expect(PointAndSayQueueService.instance.pendingCount, 1);
      expect(PointAndSayQueueService.instance.pendingWithState().single['id'], pasId);

      var now = DateTime.utc(2026, 10, 28);
      final harness = await OfflineResilienceHarness.inTempFile(clock: () => now);
      await harness.enqueueProgressMerge({'language': 'yo', 'reviews_completed': 1});
      expect(harness.pendingCount, 1);

      await harness.close();
      await audioDir.delete(recursive: true);
      await LocalDatabaseService().close();
    });

    test('AC2 network flap: no lost or duplicate applies after reconnect', () async {
      var now = DateTime.utc(2026, 10, 28);
      final ledger = IdempotentLedger();
      final inner = RecordingOutboxTransport(ledger: ledger);
      final transport = periodicFlapTransport(inner: inner, period: 2);
      final harness = await OfflineResilienceHarness.inTempFile(
        clock: () => now,
        random: Random(1),
      );
      harness.sharedLedger = ledger;

      const actionCount = 12;
      for (var i = 0; i < actionCount; i++) {
        await harness.enqueueProgressMerge({'language': 'yo', 'seq': i});
      }
      expect(harness.pendingCount, actionCount);

      var guard = 0;
      while (harness.pendingCount > 0 && guard < 40) {
        transport.setFault(NetworkFault.none);
        await harness.flush(transport, batchSize: 4);
        now = now.add(const Duration(seconds: 5));
        guard++;
      }

      expect(harness.pendingCount, 0);
      expect(inner.appliedIdempotencyKeys.length, actionCount);
      expect(ledger.applications, actionCount);

      await harness.close();
    });

    test('AC3 kill mid-sync: outbox resumes and applies exactly once', () async {
      var now = DateTime.utc(2026, 10, 28);
      final ledger = IdempotentLedger();
      final inner = RecordingOutboxTransport(ledger: ledger);
      final harness = await OfflineResilienceHarness.inTempFile(clock: () => now);
      harness.sharedLedger = ledger;

      await harness.enqueueProgressMerge({'language': 'ig', 'kill': 'mid'});
      expect(harness.pendingCount, 1);

      final flaky = FaultInjectingOutboxTransport(
        inner: inner,
        fault: NetworkFault.transportDrop,
      );
      await harness.flush(flaky);
      expect(harness.pendingCount, 1);
      now = now.add(const Duration(minutes: 2));

      await harness.simulateProcessKill();
      flaky.setFault(NetworkFault.none);
      final removed = await harness.flush(flaky);
      expect(removed, 1);
      expect(harness.pendingCount, 0);
      expect(ledger.applications, 1);

      await harness.close();
    });

    test('AC4 server 5xx: backoff, degraded visibility, no fake success', () async {
      var now = DateTime.utc(2026, 10, 28, 12);
      final ledger = IdempotentLedger();
      final inner = RecordingOutboxTransport(ledger: ledger);
      final transport = FaultInjectingOutboxTransport(inner: inner, fault: NetworkFault.http503);
      final harness = await OfflineResilienceHarness.inTempFile(
        clock: () => now,
        random: Random(2),
      );
      harness.sharedLedger = ledger;

      final id = await harness.enqueueProgressMerge({'language': 'ha', 'xp': 4});
      await harness.flush(transport);
      expect(harness.pendingCount, 1);
      expect(ledger.applications, 0);

      final row = harness.recordById(id);
      expect(row, isNotNull);
      expect(row!.attempts, greaterThan(0));
      expect(row.lastError, contains('503'));

      final visibility = syncVisibility(
        online: true,
        syncing: false,
        pending: harness.pendingCount,
        failed: 0,
      );
      expect(visibility, SyncVisibility.pending);
      expect(visibility, isNot(equals(SyncVisibility.synced)));

      transport.setFault(NetworkFault.none);
      now = now.add(const Duration(minutes: 2));
      final removed = await harness.flush(transport);
      expect(removed, 1);
      expect(harness.pendingCount, 0);
      expect(ledger.applications, 1);

      await harness.close();
    });
  });
}
