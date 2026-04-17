import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/config/sync_outbox_operation_types.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  String _hashKey(String type, Map<String, dynamic> payload) {
    final canonical = jsonEncode(payload);
    return sha256.convert(utf8.encode('$type|$canonical')).toString();
  }

  /// Enqueue a typed operation. Returns the client operation id.
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
    final clientOperationId = _uuid.v4();
    final idempotencyKey = _hashKey(type, payload);
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

  /// Push up to [batchSize] operations to the server; removes successful rows.
  /// Retries transient failures (5xx, 429, network) with bounded backoff.
  /// Skips work when [ConnectivityService] reports no internet (cached ~5s).
  Future<int> flushPending({int batchSize = 50}) async {
    await ensureOpen();

    if (!await ConnectivityService.hasInternet()) {
      logger.debug('Outbox flush skipped — no connectivity');
      return 0;
    }

    await ApiService.initialize();

    final pending = _pendingRecords();
    if (pending.isEmpty) return 0;

    final batch = pending.take(batchSize).map((e) {
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

    final pushUrl = ApiContract.url(ApiContract.syncV2.outboxPush);

    Future<int> applyServerResults(Response<dynamic> res) async {
      final data = res.data;
      if (data is! Map) return 0;
      final results = data['results'];
      if (results is! List) return 0;

      final batchIds = batch
          .map((e) => e['clientOperationId']?.toString())
          .whereType<String>()
          .toSet();

      var removed = 0;
      for (final item in results) {
        if (item is! Map) continue;
        final clientId = item['clientOperationId']?.toString();
        if (clientId == null || !batchIds.contains(clientId)) continue;

        final ok = item['ok'] == true;
        if (ok) {
          await _box!.delete(clientId);
          removed++;
          continue;
        }

        final err = item['error']?.toString() ?? 'sync_error';
        final raw = _box!.get(clientId);
        if (raw == null) continue;
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          final prev = (m['attempts'] as num?)?.toInt() ?? 0;
          m['attempts'] = prev + 1;
          m['lastError'] = err;
          await _box!.put(clientId, jsonEncode(m));
        } catch (_) {}
      }
      return removed;
    }

    for (var attempt = 0; attempt < _flushMaxAttempts; attempt++) {
      try {
        final res = await ApiService.post(
          pushUrl,
          data: {'operations': batch},
        );
        if (res.statusCode == 200) {
          return applyServerResults(res);
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
        return 0;
      } catch (e, st) {
        if (attempt < _flushMaxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (1 << attempt)));
          continue;
        }
        logger.error('Outbox flush failed', error: e, stackTrace: st);
        return 0;
      }
    }
    return 0;
  }

  int get pendingCount {
    if (_box == null || !_box!.isOpen) return 0;
    return _box!.length;
  }
}
