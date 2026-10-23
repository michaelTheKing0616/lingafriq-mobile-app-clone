import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/config/sync_outbox_operation_types.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/services/sync/outbox_worker.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/offline/tone_trainer_queue_service.dart';
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
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _connectivityTimer;

  bool get isOnline => _isOnline;

  /// Opens the queue, restores selective-sync preferences, and starts one
  /// background flush. An in-memory callback queue is not kept: a callback
  /// cannot survive a restart, so callers flush a durable queue instead.
  Future<void> start() async {
    await ensureOpen();
    await SelectiveSyncService().initialize();
    _connectivityTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_refreshConnectivity());
    });
    try {
      await Workmanager().initialize(backgroundSyncCallback, isInDebugMode: kDebugMode);
      await Workmanager().registerPeriodicTask(
        'background-sync',
        'backgroundSync',
        frequency: const Duration(hours: 1),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (error, stack) {
      logger.error('Background sync did not start', error: error, stackTrace: stack);
    }
  }

  Future<void> _refreshConnectivity() async {
    final wasOnline = _isOnline;
    try {
      _isOnline = await ConnectivityService.hasInternet();
    } catch (_) {
      return;
    }
    if (!wasOnline && _isOnline) {
      await flushPending();
      await ToneTrainerQueueService.instance.flushPending();
    }
  }

  Map<String, dynamic> getSyncStatus() {
    return {
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
      'queue_length': pendingCount,
      'pending_count': pendingCount,
      'failed_count': deadLetterCount,
      'dead_letter_count': deadLetterCount,
    };
  }

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
    Map<String, dynamic>? payload,
    Map<String, dynamic>? data,
  }) async {
    final body = payload ?? data;
    if (body == null) {
      throw ArgumentError('enqueue requires payload');
    }
    payload = body;
    if (!isValidSyncOutboxOperationType(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'Unknown sync outbox operation',
      );
    }
    await ensureOpen();
    final idempotencyKey = type == 'onboarding_sync' && (payload['step']?.toString().isNotEmpty ?? false)
        ? 'onboarding:${payload['user_id'] ?? ''}:${payload['step']}'
        : DurableOutbox.idempotencyKeyFor(type, payload);
    final record = await _store.enqueue(
      type: type,
      payload: payload,
      idempotencyKey: idempotencyKey,
      clientCreatedAt: DateTime.now().toUtc().toIso8601String(),
      clientInstallId: _installId,
      clientAppVersion: _appVersion,
      schemaVersion: _schemaVersion,
      refreshPayload: type == 'onboarding_sync',
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
    _isSyncing = true;
    try {
      final worker = OutboxWorker(
        store: _store,
        transport: _ApiOutboxTransport(),
        random: Random(),
      );
      final removed = await worker.flush(batchSize: batchSize);
      try {
        await ToneTrainerQueueService.instance.flushPending();
      } catch (error, stack) {
        logger.error('Tone trainer flush failed; rows kept', error: error, stackTrace: stack);
      }
      await _observeConflicts();
      return removed;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _observeConflicts() async {
    final conflicts = _store.deadLetters
        .where((row) => (row.lastError ?? '').toLowerCase().contains('conflict'))
        .map((row) => row.toJson())
        .toList();
    if (conflicts.isEmpty) return;
    try {
      logger.warn('Outbox conflict retained', context: {'count': conflicts.length});
      await pullDeltaAndCache();
    } catch (e, st) {
      logger.error('Outbox conflict hook failed; rows kept', error: e, stackTrace: st);
    }
  }

  Future<void> pullDeltaAndCache({int limit = 500}) async {
    if (!await ConnectivityService.hasInternet()) return;
    await ApiService.initialize();
    final prefs = await SharedPreferences.getInstance();
    final sinceRaw = prefs.getString('sync_v2_last_delta_server_time') ??
        prefs.getString('sync_v2_last_delta_since');
    final since = sinceRaw == null ? null : DateTime.tryParse(sinceRaw)?.toUtc();
    final uri = Uri.parse(ApiContract.url(ApiContract.syncV2.delta)).replace(
      queryParameters: {
        if (since != null) 'since': since.toIso8601String(),
        'limit': '$limit',
      },
    );
    final res = await ApiService.get(uri.toString());
    if (res.statusCode != 200 || res.data is! Map) return;
    final delta = (res.data as Map).cast<String, dynamic>();
    final serverTime = delta['serverTime']?.toString();
    final sinceEcho = delta['since']?.toString();
    if (serverTime != null && serverTime.isNotEmpty) {
      await prefs.setString('sync_v2_last_delta_server_time', serverTime);
    }
    if (sinceEcho != null && sinceEcho.isNotEmpty) {
      await prefs.setString('sync_v2_last_delta_since', sinceEcho);
    }
    if (delta['preferences'] is Map) {
      await prefs.setString('sync_v2_cached_preferences_json', jsonEncode(delta['preferences']));
    }
  }

  Future<Map<String, dynamic>> getCachedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sync_v2_cached_preferences_json');
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return const {};
  }

  Future<void> putPreferences(Map<String, dynamic> preferences) async {
    await ApiService.initialize();
    final res = await ApiService.put(
      ApiContract.url(ApiContract.syncV2.preferences),
      data: {'preferences': preferences},
    );
    if (res.statusCode != 200) {
      throw Exception('Preferences update failed (${res.statusCode})');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    var total = 0;
    for (final key in keys) {
      final value = prefs.get(key);
      total += key.length * 2;
      if (value is String) total += value.length * 2;
    }
    return {
      'totalKeys': keys.length,
      'fileCount': keys.length,
      'cacheSizeBytes': total,
      'formattedSize': '$total B',
      'queueSize': pendingCount,
      'lastSync': prefs.getString('last_sync') ?? 'Never',
    };
  }

  Future<void> clearCache(String? cacheType) async {
    if (cacheType != null) {
      logger.info('Clearing cache type', context: {'cacheType': cacheType});
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  int get pendingCount => _store.pendingCount;

  int get retryingCount => _store.retryingCount;

  int get deadLetterCount => _store.deadLetterCount;

  List<OutboxRecord> get deadLetters => _store.deadLetters;
}

class _ApiOutboxTransport implements OutboxTransport {
  @override
  Future<OutboxBatchResponse> push(List<OutboxRecord> batch) async {
    final legacy = batch.where((row) => _legacyOutboxTypes.contains(row.type)).toList();
    final v2 = batch.where((row) => !_legacyOutboxTypes.contains(row.type)).toList();
    final results = <OutboxItemResult>[];
    for (final row in legacy) {
      results.add(await _postLegacy(row));
    }
    if (v2.isEmpty) {
      final failedOpen = results.isNotEmpty && results.every((item) => item.error == 'transport_error');
      return OutboxBatchResponse(
        statusCode: failedOpen ? null : 200,
        results: results,
        transportFailed: failedOpen,
      );
    }
    final pushed = await _postV2(v2);
    if (pushed.transportFailed) {
      return OutboxBatchResponse(
        statusCode: pushed.statusCode,
        results: results,
        transportFailed: legacy.isEmpty,
      );
    }
    return OutboxBatchResponse(
      statusCode: pushed.statusCode ?? 200,
      results: [...results, ...pushed.results],
    );
  }

  Future<OutboxBatchResponse> _postV2(List<OutboxRecord> batch) async {
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

  Future<OutboxItemResult> _postLegacy(OutboxRecord row) async {
    try {
      final response = await _legacyRequest(row);
      final code = response.statusCode ?? 0;
      final ok = code == 200 || code == 201;
      final permanent = code >= 400 && code < 500 && code != 408 && code != 429;
      return OutboxItemResult(
        clientOperationId: row.id,
        ok: ok,
        error: ok ? null : (permanent ? 'invalid_operation' : 'http_$code'),
      );
    } catch (error) {
      logger.error('Legacy outbox post failed', error: error, context: {'type': row.type});
      return OutboxItemResult(clientOperationId: row.id, ok: false, error: 'transport_error');
    }
  }

  Future<Response> _legacyRequest(OutboxRecord row) {
    final data = row.payload;
    switch (row.type) {
      case 'gamification_sync':
        return ApiService.post(ApiContract.url(ApiContract.gamification.sync), data: data);
      case 'game_session_sync':
        return ApiService.post(
          ApiContract.url(ApiContract.games.sessionStart),
          data: {
            'session': data['session'],
            if (data['timestamp'] != null) 'timestamp': data['timestamp'],
          },
        );
      case 'game_srs_sync':
        final userId = data['user_id']?.toString() ?? '';
        return ApiService.put(
          ApiContract.url(ApiContract.games.srsUser(userId)),
          data: {
            'srs': data['srs'],
            if (data['timestamp'] != null) 'timestamp': data['timestamp'],
          },
        );
      case 'ai_chat_history_sync':
        return ApiService.post(ApiContract.url(ApiContract.ai.chatHistorySync), data: data);
      case 'ai_chat_srs_sync':
        return ApiService.post(ApiContract.url(ApiContract.ai.chatSrsSync), data: data);
      case 'progress_sync':
        return ApiService.post(ApiContract.url(ApiContract.gamification.progressSync), data: data);
      case 'onboarding_sync':
        return ApiService.post(
          ApiContract.url(ApiContract.onboarding.save),
          data: {
            'onboarding_data': data,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        );
      case 'telemetry_sync':
        return ApiService.post(ApiContract.url(ApiContract.games.telemetry), data: data);
      case 'learning_event':
        return ApiService.post(ApiContract.url(learningEventPath), data: data);
      default:
        throw StateError('not a legacy outbox type ${row.type}');
    }
  }
}

const Set<String> _legacyOutboxTypes = {
  'gamification_sync',
  'game_session_sync',
  'game_srs_sync',
  'ai_chat_history_sync',
  'ai_chat_srs_sync',
  'progress_sync',
  'onboarding_sync',
  'telemetry_sync',
  'learning_event',
};

enum SyncCategory {
  lessons,
  quizzes,
  progress,
  media,
  cultureMagazine,
  games,
  profile,
  chat,
  achievements,
  content,
  settings,
}

class SyncPreference {
  SyncPreference({
    required this.category,
    required this.enabled,
    this.lastSynced,
    this.syncOnWifiOnly = false,
    this.maxSize,
  });

  final SyncCategory category;
  final bool enabled;
  final DateTime? lastSynced;
  final bool syncOnWifiOnly;
  final int? maxSize;
}

class SelectiveSync {
  static const _prefKey = 'selective_sync_settings';
  static const serverPreferencesKey = 'selectiveSync';

  static Future<Map<String, bool>> getSyncPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.trim().isEmpty) {
      return {
        'lessons': true,
        'quizzes': true,
        'progress': true,
        'media': false,
        'culture_magazine': true,
        'games': true,
      };
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is bool) entry.key.toString(): entry.value as bool,
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> setSyncPreferences(Map<String, bool> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(preferences));
  }

  static Future<bool> shouldSync(String contentType) async {
    final preferences = await getSyncPreferences();
    return preferences[contentType] ?? true;
  }
}

class SelectiveSyncService {
  static final SelectiveSyncService _instance = SelectiveSyncService._();
  factory SelectiveSyncService() => _instance;
  SelectiveSyncService._();

  Future<void> initialize() async {
    final cached = await PersistedOutboxService.instance.getCachedPreferences();
    final fromServer = cached[SelectiveSync.serverPreferencesKey];
    if (fromServer is! Map) return;
    final merged = <String, bool>{
      for (final entry in fromServer.entries)
        if (entry.value is bool) entry.key.toString(): entry.value as bool,
    };
    if (merged.isNotEmpty) await SelectiveSync.setSyncPreferences(merged);
  }

  Future<Map<SyncCategory, SyncPreference>> getAllPreferences() async {
    final prefs = await SelectiveSync.getSyncPreferences();
    final result = <SyncCategory, SyncPreference>{};
    for (final category in SyncCategory.values) {
      result[category] = SyncPreference(
        category: category,
        enabled: prefs[category.name] ?? prefs[_legacyName(category.name)] ?? true,
      );
    }
    return result;
  }

  Future<void> setPreference(SyncPreference preference) async {
    final all = await getAllPreferences();
    all[preference.category] = preference;
    await SelectiveSync.setSyncPreferences({
      for (final entry in all.entries) entry.key.name: entry.value.enabled,
    });
    try {
      final current = await PersistedOutboxService.instance.getCachedPreferences();
      final next = <String, dynamic>{...current};
      next[SelectiveSync.serverPreferencesKey] = {
        for (final entry in all.entries) entry.key.name: entry.value.enabled,
      };
      await PersistedOutboxService.instance.putPreferences(next);
    } catch (_) {}
  }

  String _legacyName(String name) => name == 'cultureMagazine' ? 'culture_magazine' : name;
}

@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (!await ConnectivityService.hasInternet()) return false;
      await PersistedOutboxService.instance.ensureOpen();
      await PersistedOutboxService.instance.flushPending();
      return true;
    } catch (error, stack) {
      logger.error('Periodic background sync task failed', error: error, stackTrace: stack);
      return false;
    }
  });
}
