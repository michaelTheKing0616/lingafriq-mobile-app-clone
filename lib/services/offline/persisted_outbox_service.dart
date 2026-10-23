import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/config/sync_outbox_operation_types.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/services/sync/outbox_worker.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/offline/sync_v2_service.dart';
import 'package:uuid/uuid.dart';

/// In-memory state of the durable outbox. Hive is only the store; completion
/// is decided here and only when the server result says `ok == true`.
class DurableOutbox {
  DurableOutbox({DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final DateTime Function() _clock;
  final Map<String, Map<String, dynamic>> rows = {};

  static String idempotencyKeyFor(String type, Map<String, dynamic> payload) {
    final canonical = jsonEncode(payload);
    return sha256.convert(utf8.encode('$type|$canonical')).toString();
  }

  String? idForIdempotencyKey(String key) {
    for (final row in rows.values) {
      if (row['idempotencyKey'] == key) {
        return row['clientOperationId']?.toString();
      }
    }
    return null;
  }

  void restore(Map<String, dynamic> row) {
    final id = row['clientOperationId']?.toString();
    if (id == null || id.isEmpty) return;
    rows[id] = row;
  }

  bool contains(String id) => rows.containsKey(id);

  List<Map<String, dynamic>> due({required int batchSize}) {
    final now = _clock();
    final ready = rows.values.where((row) => _isDue(row, now)).toList()
      ..sort(
        (a, b) => (a['createdAt']?.toString() ?? '').compareTo(b['createdAt']?.toString() ?? ''),
      );
    if (ready.length <= batchSize) return ready;
    return ready.sublist(0, batchSize);
  }

  bool _isDue(Map<String, dynamic> row, DateTime now) {
    final next = row['nextAttemptAt']?.toString();
    if (next == null || next.isEmpty) return true;
    final at = DateTime.tryParse(next);
    if (at == null) return true;
    return !at.isAfter(now);
  }

  /// Deletes a row only when that result is `ok == true`. Any other result
  /// stays queued, with attempts and a future `nextAttemptAt`.
  int applyServerResults(List<dynamic> results, Set<String> batchIds) {
    var removed = 0;
    for (final item in results) {
      if (item is! Map) continue;
      final clientId = item['clientOperationId']?.toString();
      if (clientId == null || !batchIds.contains(clientId)) continue;
      if (item['ok'] == true) {
        rows.remove(clientId);
        removed++;
        continue;
      }
      final err = item['error']?.toString() ?? 'sync_error';
      _scheduleRetry(clientId, err);
    }
    return removed;
  }

  void markTransportFailure(Iterable<String> ids, String error) {
    for (final id in ids) {
      _scheduleRetry(id, error);
    }
  }

  List<Map<String, dynamic>> conflicts() {
    return rows.values
        .where((row) => row['conflict'] == true)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  void _scheduleRetry(String id, String error) {
    final row = rows[id];
    if (row == null) return;
    final prev = (row['attempts'] as num?)?.toInt() ?? 0;
    final nextAttempts = prev + 1;
    row['attempts'] = nextAttempts;
    row['lastError'] = error;
    final shift = nextAttempts > 8 ? 8 : nextAttempts;
    final delayMs = 250 * (1 << (shift - 1));
    row['nextAttemptAt'] = _clock().add(Duration(milliseconds: delayMs)).toUtc().toIso8601String();
    if (error.toLowerCase().contains('conflict')) {
      row['conflict'] = true;
    }
  }

  Map<String, String> encode() {
    return {
      for (final entry in rows.entries) entry.key: jsonEncode(entry.value),
    };
  }

  static DurableOutbox decode(Map<String, String> raw, {DateTime Function()? clock}) {
    final box = DurableOutbox(clock: clock);
    for (final encoded in raw.values) {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        box.restore(decoded);
      } else if (decoded is Map) {
        box.restore(decoded.cast<String, dynamic>());
      }
    }
    return box;
  }
}

/// Persistent offline outbox — survives process restarts.
/// Operations are pushed to `POST /api/v2/sync/outbox/push` with idempotency.
class PersistedOutboxService {
  PersistedOutboxService._();
  static final PersistedOutboxService instance = PersistedOutboxService._();

  static const _uuid = Uuid();
  static const _installIdKey = 'lingafriq_install_id_v1';
  static const int _schemaVersion = 1;

  final OutboxService _store = OutboxService();
  String? _installId;
  String? _appVersion;

  Future<void> ensureOpen() async {
    await _store.openShared();
    await _ensureClientMetadata();
  }

  Future<void> _ensureClientMetadata() async {
    if (_installId != null && _appVersion != null) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey);
    if (existing != null && existing.isNotEmpty && existing.length <= 128) {
      _installId = existing;
    } else {
      final newId = _uuid.v4();
      _installId = newId;
      await prefs.setString(_installIdKey, newId);
    }

    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = null;
    }
  }

  /// Enqueue a typed operation. Returns the client operation id.
  /// The same type and payload reuse the pending row so a retry is one key.
  Future<String> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    if (!isValidSyncOutboxOperationType(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'Unknown sync v2 outbox operation (must match server ALLOWED_TYPES)',
      );
    }
    await ensureOpen();
    final idempotencyKey = DurableOutbox.idempotencyKeyFor(type, payload);
    final record = await _store.enqueue(
      type: type,
      payload: payload,
      idempotencyKey: idempotencyKey,
      clientCreatedAt: DateTime.now().toUtc().toIso8601String(),
      clientInstallId: _installId,
      clientAppVersion: _appVersion,
      schemaVersion: _schemaVersion,
    );
    return record.id;
  }

  /// Push due operations. A row is removed only after the server applies it
  /// once. A permanent 4xx stays in the dead-letter list.
  Future<int> flushPending({int batchSize = 50}) async {
    await ensureOpen();

    if (!await ConnectivityService.hasInternet()) {
      logger.debug('Outbox flush skipped — no connectivity');
      return 0;
    }

    await ApiService.initialize();
    final worker = OutboxWorker(
      store: _store,
      transport: _ApiOutboxTransport(),
      random: Random(),
    );
    final removed = await worker.flush(batchSize: batchSize);
    await _observeConflicts();
    return removed;
  }

  Future<void> _observeConflicts() async {
    final conflicts = _store.deadLetters
        .where((row) => (row.lastError ?? '').toLowerCase().contains('conflict'))
        .map((row) => row.toJson())
        .toList();
    if (conflicts.isEmpty) return;
    try {
      await SyncV2Service.instance.observeOutboxConflicts(conflicts);
    } catch (e, st) {
      logger.error('Outbox conflict hook failed; rows kept', error: e, stackTrace: st);
    }
  }

  int get pendingCount => _store.pendingCount;

  int get retryingCount => _store.retryingCount;

  int get deadLetterCount => _store.deadLetterCount;

  List<OutboxRecord> get deadLetters => _store.deadLetters;
}

class _ApiOutboxTransport implements OutboxTransport {
  @override
  Future<OutboxBatchResponse> push(List<OutboxRecord> batch) async {
    final pushUrl = ApiContract.url(ApiContract.syncV2.outboxPush);
    final body = batch.map((row) {
      return {
        'idempotencyKey': row.idempotencyKey,
        'clientOperationId': row.id,
        'type': row.type,
        'payload': row.payload,
        'clientCreatedAt': row.clientCreatedAt,
        'clientInstallId': row.clientInstallId,
        'clientAppVersion': row.clientAppVersion,
        'schemaVersion': row.schemaVersion,
      };
    }).toList();
    try {
      final res = await ApiService.post(pushUrl, data: {'operations': body});
      final data = res.data;
      final rawResults = data is Map ? data['results'] : null;
      final results = <OutboxItemResult>[];
      if (rawResults is List) {
        for (final item in rawResults) {
          if (item is! Map) continue;
          results.add(OutboxItemResult(
            clientOperationId: item['clientOperationId']?.toString() ?? '',
            ok: item['ok'] == true,
            duplicate: item['duplicate'] == true,
            error: item['error']?.toString(),
          ));
        }
      }
      return OutboxBatchResponse(statusCode: res.statusCode, results: results);
    } catch (error) {
      logger.error('Outbox flush failed', error: error);
      return const OutboxBatchResponse(statusCode: null, transportFailed: true);
    }
  }
}
