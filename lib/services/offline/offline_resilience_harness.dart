import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/services/sync/outbox_worker.dart';

/// Deterministic harness for P12-019 chaos scenarios (outbox flush, restart, flap).
class OfflineResilienceHarness {
  OfflineResilienceHarness({
    required this.database,
    DateTime Function()? clock,
    Random? random,
  })  : _clock = clock ?? (() => DateTime.now().toUtc()),
        _random = random ?? Random(0);

  final LingAfriqDatabase database;
  final DateTime Function() _clock;
  final Random _random;

  late OutboxService _store;
  IdempotentLedger? sharedLedger;

  DateTime get clock => _clock();

  Future<void> open() async {
    _store = OutboxService(database: database, clock: _clock);
    await _store.open(database);
  }

  /// Same Drift file, new process — pending rows must survive.
  Future<void> simulateProcessKill() async {
    _store = OutboxService(database: database, clock: _clock);
    await _store.open(database);
  }

  static Future<OfflineResilienceHarness> inTempFile({
    DateTime Function()? clock,
    Random? random,
  }) async {
    final dir = await Directory.systemTemp.createTemp('p12-019-outbox-');
    final file = File('${dir.path}/lingafriq.sqlite');
    final db = LingAfriqDatabase(NativeDatabase(file));
    final harness = OfflineResilienceHarness(database: db, clock: clock, random: random);
    await harness.open();
    return harness;
  }

  Future<void> close() => database.close();

  Future<String> enqueueProgressMerge(Map<String, dynamic> payload) async {
    final row = await _store.enqueue(
      type: 'progress_metrics_merge',
      payload: payload,
    );
    return row.id;
  }

  Future<int> flush(OutboxTransport transport, {int batchSize = 50}) {
    final worker = OutboxWorker(
      store: _store,
      transport: transport,
      random: _random,
      ledger: sharedLedger,
    );
    return worker.flush(batchSize: batchSize);
  }

  int get pendingCount => _store.pendingCount;

  int get retryingCount => _store.retryingCount;

  OutboxRecord? recordById(String id) => _store.byId(id);
}
