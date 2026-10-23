import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingafriq/config/sync_outbox_operation_types.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:uuid/uuid.dart';

/// One queued sync write. The idempotency key is created on the device and
/// stored in Drift, so it is still there after the process restarts.
class OutboxRecord {
  OutboxRecord({
    required this.id,
    required this.idempotencyKey,
    required this.type,
    required this.payload,
    required this.state,
    required this.attempts,
    required this.createdAt,
    this.nextAttemptAt,
    this.lastError,
    this.lastStatusCode,
    this.clientCreatedAt,
    this.clientInstallId,
    this.clientAppVersion,
    this.schemaVersion,
  });

  final String id;
  final String idempotencyKey;
  final String type;
  final Map<String, dynamic> payload;
  final String state;
  final int attempts;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final int? lastStatusCode;
  final String? clientCreatedAt;
  final String? clientInstallId;
  final String? clientAppVersion;
  final int? schemaVersion;

  bool get isDeadLetter => state == outboxDeadLetterState;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'type': type,
        'payload': payload,
        'state': state,
        'attempts': attempts,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'nextAttemptAt': nextAttemptAt?.toUtc().toIso8601String(),
        'lastError': lastError,
        'lastStatusCode': lastStatusCode,
        'clientCreatedAt': clientCreatedAt,
        'clientInstallId': clientInstallId,
        'clientAppVersion': clientAppVersion,
        'schemaVersion': schemaVersion,
      };

  factory OutboxRecord.fromJson(Map<String, dynamic> json) {
    return OutboxRecord(
      id: '${json['id']}',
      idempotencyKey: '${json['idempotencyKey']}',
      type: '${json['type']}',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      state: '${json['state'] ?? outboxPendingState}',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ?? DateTime.now().toUtc(),
      nextAttemptAt: json['nextAttemptAt'] == null
          ? null
          : DateTime.tryParse('${json['nextAttemptAt']}')?.toUtc(),
      lastError: json['lastError']?.toString(),
      lastStatusCode: (json['lastStatusCode'] as num?)?.toInt(),
      clientCreatedAt: json['clientCreatedAt']?.toString(),
      clientInstallId: json['clientInstallId']?.toString(),
      clientAppVersion: json['clientAppVersion']?.toString(),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt(),
    );
  }
}

const String outboxPendingState = 'pending';
const String outboxDeadLetterState = 'dead_letter';

class OutboxService {
  OutboxService({
    LingAfriqDatabase? database,
    DateTime Function()? clock,
    String Function()? newId,
  })  : _database = database,
        _clock = clock ?? (() => DateTime.now().toUtc()),
        _newId = newId ?? const Uuid().v4;

  final LingAfriqDatabase? _database;
  final DateTime Function() _clock;
  final String Function() _newId;
  final Map<String, OutboxRecord> _rows = {};
  LingAfriqDatabase? _openDb;
  bool _opened = false;

  DateTime get now => _clock();

  Future<void> openShared() async {
    await LocalDatabaseService().init();
    await open(LocalDatabaseService().database);
    await _importHiveIfEmpty();
  }

  Future<void> open(LingAfriqDatabase database) async {
    if (_opened) return;
    _openDb = database;
    await database.customSelect('SELECT 1').get();
    final stored = await readPayloads(database, 'outbox');
    for (final row in stored) {
      final record = OutboxRecord.fromJson(Map<String, dynamic>.from(row));
      _rows[record.id] = record;
    }
    _opened = true;
  }

  Future<OutboxRecord> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
    String? clientCreatedAt,
    String? clientInstallId,
    String? clientAppVersion,
    int? schemaVersion,
  }) async {
    final db = _requireDb();
    if (!isValidSyncOutboxOperationType(type)) {
      throw ArgumentError.value(type, 'type', 'Unknown sync outbox operation');
    }
    final key = (idempotencyKey == null || idempotencyKey.isEmpty) ? _newId() : idempotencyKey;
    final existing = _byKey(key);
    if (existing != null) return existing;
    final record = OutboxRecord(
      id: _newId(),
      idempotencyKey: key,
      type: type,
      payload: payload,
      state: outboxPendingState,
      attempts: 0,
      createdAt: _clock(),
      clientCreatedAt: clientCreatedAt,
      clientInstallId: clientInstallId,
      clientAppVersion: clientAppVersion,
      schemaVersion: schemaVersion,
    );
    await _persist(db, record);
    _rows[record.id] = record;
    return record;
  }

  List<OutboxRecord> due({int batchSize = 50}) {
    final ready = _rows.values.where((row) {
      if (row.state != outboxPendingState) return false;
      final next = row.nextAttemptAt;
      if (next == null) return true;
      return !next.isAfter(_clock());
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (ready.length <= batchSize) return ready;
    return ready.sublist(0, batchSize);
  }

  List<OutboxRecord> get deadLetters =>
      _rows.values.where((row) => row.isDeadLetter).toList();

  int get pendingCount => _rows.values.where((row) => !row.isDeadLetter).length;

  int get retryingCount => _rows.values
      .where((row) => !row.isDeadLetter && row.attempts > 0)
      .length;

  int get deadLetterCount => deadLetters.length;

  OutboxRecord? byId(String id) => _rows[id];

  Future<void> complete(String id) async {
    final db = _requireDb();
    _rows.remove(id);
    await deleteLocalRow(db, 'outbox', 'id', id);
  }

  Future<void> deadLetter(String id, {required String error, int? statusCode}) async {
    final current = _rows[id];
    if (current == null) return;
    final next = OutboxRecord(
      id: current.id,
      idempotencyKey: current.idempotencyKey,
      type: current.type,
      payload: current.payload,
      state: outboxDeadLetterState,
      attempts: current.attempts + 1,
      createdAt: current.createdAt,
      nextAttemptAt: null,
      lastError: error,
      lastStatusCode: statusCode,
      clientCreatedAt: current.clientCreatedAt,
      clientInstallId: current.clientInstallId,
      clientAppVersion: current.clientAppVersion,
      schemaVersion: current.schemaVersion,
    );
    await _persist(_requireDb(), next);
    _rows[id] = next;
  }

  Future<void> scheduleRetry(String id, {required String error, required Duration delay, int? statusCode}) async {
    final current = _rows[id];
    if (current == null || current.isDeadLetter) return;
    final next = OutboxRecord(
      id: current.id,
      idempotencyKey: current.idempotencyKey,
      type: current.type,
      payload: current.payload,
      state: outboxPendingState,
      attempts: current.attempts + 1,
      createdAt: current.createdAt,
      nextAttemptAt: _clock().add(delay),
      lastError: error,
      lastStatusCode: statusCode,
      clientCreatedAt: current.clientCreatedAt,
      clientInstallId: current.clientInstallId,
      clientAppVersion: current.clientAppVersion,
      schemaVersion: current.schemaVersion,
    );
    await _persist(_requireDb(), next);
    _rows[id] = next;
  }

  Future<void> _importHiveIfEmpty() async {
    if (_rows.isNotEmpty) return;
    const boxName = 'lingafriq_sync_outbox_v1';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
    }
    final box = Hive.box<String>(boxName);
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        continue;
      }
      if (decoded is! Map) continue;
      final row = Map<String, dynamic>.from(decoded);
      final type = row['type']?.toString() ?? '';
      if (!isValidSyncOutboxOperationType(type)) continue;
      final keyValue = row['idempotencyKey']?.toString();
      final record = OutboxRecord(
        id: row['clientOperationId']?.toString().isNotEmpty == true
            ? row['clientOperationId'].toString()
            : _newId(),
        idempotencyKey: (keyValue == null || keyValue.isEmpty) ? _newId() : keyValue,
        type: type,
        payload: Map<String, dynamic>.from(row['payload'] as Map? ?? const {}),
        state: outboxPendingState,
        attempts: (row['attempts'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse('${row['createdAt']}')?.toUtc() ?? _clock(),
        nextAttemptAt: row['nextAttemptAt'] == null
            ? null
            : DateTime.tryParse('${row['nextAttemptAt']}')?.toUtc(),
        lastError: row['lastError']?.toString(),
      );
      if (_byKey(record.idempotencyKey) != null) continue;
      await _persist(_requireDb(), record);
      _rows[record.id] = record;
    }
  }

  OutboxRecord? _byKey(String key) {
    for (final row in _rows.values) {
      if (row.idempotencyKey == key) return row;
    }
    return null;
  }

  LingAfriqDatabase _requireDb() {
    final db = _openDb ?? _database;
    if (db == null || !_opened) {
      throw StateError('OutboxService.open must run before a write');
    }
    return db;
  }

  Future<void> _persist(LingAfriqDatabase db, OutboxRecord record) async {
    final when = record.nextAttemptAt?.millisecondsSinceEpoch;
    await db.customInsert(
      'INSERT INTO outbox (id, idempotency_key, state, next_attempt_at, attempts, payload) '
      'VALUES (?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET '
      'idempotency_key = excluded.idempotency_key, '
      'state = excluded.state, '
      'next_attempt_at = excluded.next_attempt_at, '
      'attempts = excluded.attempts, '
      'payload = excluded.payload',
      variables: [
        Variable.withString(record.id),
        Variable.withString(record.idempotencyKey),
        Variable.withString(record.state),
        Variable<int>(when),
        Variable.withInt(record.attempts),
        Variable.withString(jsonEncode(record.toJson())),
      ],
    );
  }
}
