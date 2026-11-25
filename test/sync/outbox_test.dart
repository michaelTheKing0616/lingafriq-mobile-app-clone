import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/services/sync/outbox_worker.dart';

void main() {
  test('an enqueued key survives a restart and a second enqueue is the same row', () async {
    final file = File(
      '${Directory.systemTemp.path}/lingafriq-outbox-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final firstDb = LingAfriqDatabase(NativeDatabase(file));
    final first = OutboxService(
      clock: () => DateTime.utc(2026, 1, 1),
      newId: () => 'op-1',
    );
    await first.open(firstDb);
    final saved = await first.enqueue(
      type: 'noop',
      payload: const {'n': 1},
      idempotencyKey: 'client-key-1',
    );
    final again = await first.enqueue(
      type: 'noop',
      payload: const {'n': 2},
      idempotencyKey: 'client-key-1',
    );
    expect(again.id, saved.id);
    expect(first.pendingCount, 1);
    await firstDb.close();

    final secondDb = LingAfriqDatabase(NativeDatabase(file));
    addTearDown(secondDb.close);
    final restored = OutboxService();
    await restored.open(secondDb);
    expect(restored.pendingCount, 1);
    expect(restored.byId('op-1')?.idempotencyKey, 'client-key-1');
    expect(restored.byId('op-1')?.payload['n'], 1);
  });

  test('backoff grows and stays within the documented cap', () {
    expect(outboxBackoffMs(1, 0), 250);
    expect(outboxBackoffMs(2, 0), 500);
    expect(outboxBackoffMs(3, 0), 1000);
    expect(outboxBackoffMs(2, 0), greaterThan(outboxBackoffMs(1, 0)));
    expect(outboxBackoffMs(9, 0), outboxBackoffCapMs);
    expect(outboxBackoffMs(12, 900), outboxBackoffCapMs);
    expect(outboxBackoffMs(1, 400), lessThan(outboxBackoffMs(2, 0) + 400));
  });

  test('a repeated onboarding step stays one visible row', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final store = OutboxService(
      clock: () => DateTime.utc(2026, 1, 1),
      newId: () => 'onb-1',
    );
    await store.open(db);
    await store.enqueue(
      type: 'onboarding_sync',
      payload: const {'step': 'age_category', 'age_category': 'adult'},
      idempotencyKey: 'onboarding:7:age_category',
    );
    final updated = await store.enqueue(
      type: 'onboarding_sync',
      payload: const {'step': 'age_category', 'age_category': 'teen'},
      idempotencyKey: 'onboarding:7:age_category',
      refreshPayload: true,
    );
    expect(store.pendingCount, 1);
    expect(updated.payload['age_category'], 'teen');
    expect(File('lib/services/offline/offline_service.dart').existsSync(), isFalse);
    expect(File('lib/providers/backend_sync_provider.dart').existsSync(), isFalse);
    expect(File('lib/services/offline/selective_sync.dart').existsSync(), isFalse);
    expect(File('lib/services/offline/sync_v2_service.dart').existsSync(), isFalse);
    expect(File('lib/services/offline/background_sync_service.dart').existsSync(), isFalse);
    expect(File('lib/services/offline/offline_handler.dart').existsSync(), isFalse);
  });

  test('the same key applies the effect once', () {
    final ledger = IdempotentLedger();
    expect(ledger.apply('k', () => 'first'), 'first');
    expect(ledger.apply('k', () => 'second'), 'first');
    expect(ledger.applications, 1);
  });

  test('a permanent 4xx stays visible and is not sent again', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final store = OutboxService(
      clock: () => DateTime.utc(2026, 1, 1),
      newId: () => 'op-4xx',
    );
    await store.open(db);
    await store.enqueue(type: 'noop', payload: const {'n': 1}, idempotencyKey: 'k');
    var pushes = 0;
    final worker = OutboxWorker(
      store: store,
      random: Random(1),
      transport: _ScriptedTransport(() {
        pushes += 1;
        return const OutboxBatchResponse(statusCode: 400);
      }),
    );
    expect(await worker.flush(), 0);
    expect(pushes, 1);
    expect(store.deadLetterCount, 1);
    expect(store.deadLetters.single.lastError, 'http_400');
    expect(store.pendingCount, 0);
    expect(await worker.flush(), 0);
    expect(pushes, 1);
  });

  test('a transient failure waits with backoff and a duplicate completes once', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final store = OutboxService(
      clock: () => DateTime.utc(2026, 1, 1),
      newId: () => 'op-retry',
    );
    await store.open(db);
    await store.enqueue(type: 'noop', payload: const {'n': 1}, idempotencyKey: 'k');
    final ledger = IdempotentLedger();
    final worker = OutboxWorker(
      store: store,
      random: Random(1),
      ledger: ledger,
      transport: _ScriptedTransport(() {
        return const OutboxBatchResponse(statusCode: 503);
      }),
    );
    expect(await worker.flush(), 0);
    final waiting = store.byId('op-retry');
    expect(waiting?.state, outboxPendingState);
    expect(waiting?.attempts, 1);
    expect(waiting?.nextAttemptAt?.isAfter(DateTime.utc(2026, 1, 1)), isTrue);
    expect(store.due(), isEmpty);

    await store.scheduleRetry('op-retry', error: 'force-due', delay: Duration.zero);
    final done = OutboxWorker(
      store: store,
      random: Random(1),
      ledger: ledger,
      transport: _ScriptedTransport(() {
        return const OutboxBatchResponse(
          statusCode: 200,
          results: [
            OutboxItemResult(clientOperationId: 'op-retry', ok: true, duplicate: true),
          ],
        );
      }),
    );
    expect(store.due(), isNotEmpty);
    expect(await done.flush(), 1);
    expect(store.pendingCount, 0);
    expect(store.deadLetterCount, 0);
    expect(ledger.applications, 1);
    expect(ledger.apply('k', () => 'again'), 'op-retry');
    expect(ledger.applications, 1);
  });
}

class _ScriptedTransport implements OutboxTransport {
  _ScriptedTransport(this._next);

  final OutboxBatchResponse Function() _next;

  @override
  Future<OutboxBatchResponse> push(List<OutboxRecord> batch) async => _next();
}
