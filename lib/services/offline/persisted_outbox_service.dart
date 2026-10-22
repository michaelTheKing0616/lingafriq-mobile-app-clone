import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/config/sync_outbox_operation_types.dart';
import 'package:lingafriq/services/connectivity_service.dart';
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

  static const _boxName = 'lingafriq_sync_outbox_v1';
  static const _uuid = Uuid();
  static const _installIdKey = 'lingafriq_install_id_v1';
  static const int _schemaVersion = 1;

  Box<String>? _box;
  String? _installId;
  String? _appVersion;

  Future<void> ensureOpen() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(_boxName);
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
    for (final existing in _pendingRecords()) {
      if (existing['idempotencyKey'] == idempotencyKey) {
        final id = existing['clientOperationId']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    final clientOperationId = _uuid.v4();
    final rec = <String, dynamic>{
      'clientOperationId': clientOperationId,
      'idempotencyKey': idempotencyKey,
      'type': type,
      'payload': payload,
      'clientCreatedAt': DateTime.now().toUtc().toIso8601String(),
      'clientInstallId': _installId,
      'clientAppVersion': _appVersion,
      'schemaVersion': _schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
      'lastError': null,
    };
    await _box!.put(clientOperationId, jsonEncode(rec));
    return clientOperationId;
  }

  List<Map<String, dynamic>> _pendingRecords() {
    if (_box == null || !_box!.isOpen) return [];
    final out = <Map<String, dynamic>>[];
    for (final key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        out.add(m);
      } catch (_) {}
    }
    out.sort((a, b) {
      final ta = a['createdAt']?.toString() ?? '';
      final tb = b['createdAt']?.toString() ?? '';
      return ta.compareTo(tb);
    });
    return out;
  }

  static const int _flushMaxAttempts = 3;

  ({DurableOutbox machine, Set<String> loadedIds}) _loadMachine() {
    final machine = DurableOutbox();
    final loadedIds = <String>{};
    if (_box == null || !_box!.isOpen) {
      return (machine: machine, loadedIds: loadedIds);
    }
    for (final key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final row = decoded.cast<String, dynamic>();
        final id = row['clientOperationId']?.toString();
        if (id == null || id.isEmpty) continue;
        machine.restore(row);
        loadedIds.add(id);
      } catch (_) {
        // Leave unreadable rows in the box. A parse error is not an ack.
      }
    }
    return (machine: machine, loadedIds: loadedIds);
  }

  Future<void> _persistMachine(DurableOutbox machine, Set<String> loadedIds) async {
    for (final id in loadedIds) {
      final row = machine.rows[id];
      if (row == null) {
        await _box!.delete(id);
      } else {
        await _box!.put(id, jsonEncode(row));
      }
    }
  }

  /// Push up to [batchSize] due operations. A row is deleted only after the
  /// server result says `ok == true`. Transport errors and `ok: false` keep
  /// the row, increment attempts, and set `nextAttemptAt`.
  Future<int> flushPending({int batchSize = 50}) async {
    await ensureOpen();

    if (!await ConnectivityService.hasInternet()) {
      logger.debug('Outbox flush skipped — no connectivity');
      return 0;
    }

    await ApiService.initialize();

    final loaded = _loadMachine();
    final due = loaded.machine.due(batchSize: batchSize);
    if (due.isEmpty) return 0;

    final batch = due.map((e) {
      return {
        'idempotencyKey': e['idempotencyKey'],
        'clientOperationId': e['clientOperationId'],
        'type': e['type'],
        'payload': e['payload'],
        'clientCreatedAt': e['clientCreatedAt'],
        'clientInstallId': e['clientInstallId'],
        'clientAppVersion': e['clientAppVersion'],
        'schemaVersion': e['schemaVersion'],
      };
    }).toList();
    final batchIds = batch
        .map((e) => e['clientOperationId']?.toString())
        .whereType<String>()
        .toSet();

    final pushUrl = ApiContract.url(ApiContract.syncV2.outboxPush);

    for (var attempt = 0; attempt < _flushMaxAttempts; attempt++) {
      try {
        final res = await ApiService.post(
          pushUrl,
          data: {'operations': batch},
        );
        if (res.statusCode == 200) {
          final data = res.data;
          final results = data is Map ? data['results'] : null;
          final removed = results is List
              ? loaded.machine.applyServerResults(results, batchIds)
              : 0;
          if (results is! List) {
            loaded.machine.markTransportFailure(batchIds, 'missing_results');
          }
          await _persistMachine(loaded.machine, loaded.loadedIds);
          await _observeConflicts(loaded.machine);
          return removed;
        }
        final code = res.statusCode ?? 0;
        final retryable = (code >= 500 && code < 600) || code == 429;
        if (retryable && attempt < _flushMaxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (1 << attempt)));
          continue;
        }
        logger.warn('Outbox push non-200', context: {
          'status': res.statusCode,
          'data': res.data,
          'attempt': attempt + 1,
        });
        loaded.machine.markTransportFailure(batchIds, 'http_$code');
        await _persistMachine(loaded.machine, loaded.loadedIds);
        return 0;
      } catch (e, st) {
        if (attempt < _flushMaxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (1 << attempt)));
          continue;
        }
        logger.error('Outbox flush failed', error: e, stackTrace: st);
        loaded.machine.markTransportFailure(batchIds, 'transport_error');
        await _persistMachine(loaded.machine, loaded.loadedIds);
        return 0;
      }
    }
    return 0;
  }

  Future<void> _observeConflicts(DurableOutbox machine) async {
    final conflicts = machine.conflicts();
    if (conflicts.isEmpty) return;
    try {
      await SyncV2Service.instance.observeOutboxConflicts(conflicts);
    } catch (e, st) {
      logger.error('Outbox conflict hook failed; rows kept', error: e, stackTrace: st);
    }
  }

  int get pendingCount {
    if (_box == null || !_box!.isOpen) return 0;
    return _box!.length;
  }

  int get retryingCount {
    var count = 0;
    for (final row in _pendingRecords()) {
      final attempts = (row['attempts'] as num?)?.toInt() ?? 0;
      if (attempts > 0) count++;
    }
    return count;
  }
}
