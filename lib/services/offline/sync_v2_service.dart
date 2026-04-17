import 'dart:convert';

import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mobile client for sync v2 auxiliary endpoints:
/// - `GET /api/v2/sync/delta`
/// - `GET|PUT /api/v2/sync/preferences`
///
/// This does not attempt to apply deltas to all local stores yet; it
/// **fetches + caches** so we can evolve toward full multi-device consistency
/// without breaking offline-first writes (outbox remains source of truth).
class SyncV2Service {
  SyncV2Service._();
  static final SyncV2Service instance = SyncV2Service._();

  static const _prefsKeyLastDeltaServerTime = 'sync_v2_last_delta_server_time';
  static const _prefsKeyLastDeltaSince = 'sync_v2_last_delta_since';
  static const _prefsKeyCachedPreferencesJson = 'sync_v2_cached_preferences_json';

  Future<Map<String, dynamic>> fetchDelta({
    DateTime? since,
    int limit = 500,
  }) async {
    await ApiService.initialize();

    final uri = Uri.parse(ApiContract.url(ApiContract.syncV2.delta)).replace(
      queryParameters: {
        if (since != null) 'since': since.toUtc().toIso8601String(),
        'limit': '$limit',
      },
    );

    final res = await ApiService.get(uri.toString());
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Delta fetch failed (${res.statusCode})');
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getPreferences() async {
    await ApiService.initialize();
    final res = await ApiService.get(ApiContract.url(ApiContract.syncV2.preferences));
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Preferences fetch failed (${res.statusCode})');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    final prefs = data['preferences'];
    if (prefs is Map) return prefs.cast<String, dynamic>();
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

  /// Best-effort pull:
  /// - skips if offline
  /// - fetches delta using last known `serverTime` as the next `since`
  /// - caches delta timing + preferences snapshot
  Future<void> pullDeltaAndCache({int limit = 500}) async {
    if (!await ConnectivityService.hasInternet()) return;

    final prefs = await SharedPreferences.getInstance();
    final sinceRaw = prefs.getString(_prefsKeyLastDeltaServerTime) ?? prefs.getString(_prefsKeyLastDeltaSince);
    DateTime? since;
    if (sinceRaw != null && sinceRaw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(sinceRaw);
      if (parsed != null) since = parsed.toUtc();
    }

    final delta = await fetchDelta(since: since, limit: limit);

    final serverTime = delta['serverTime']?.toString();
    final sinceEcho = delta['since']?.toString();
    final prefsFromDelta = delta['preferences'];

    if (serverTime != null && serverTime.isNotEmpty) {
      await prefs.setString(_prefsKeyLastDeltaServerTime, serverTime);
    }
    if (sinceEcho != null && sinceEcho.isNotEmpty) {
      await prefs.setString(_prefsKeyLastDeltaSince, sinceEcho);
    }
    if (prefsFromDelta is Map) {
      await prefs.setString(_prefsKeyCachedPreferencesJson, jsonEncode(prefsFromDelta));
    }

    logger.debug('Sync v2 delta cached', context: {
      'serverTime': serverTime,
      'since': sinceEcho,
      'pendingConflicts': delta['pendingConflicts'],
    });
  }

  Future<Map<String, dynamic>> getCachedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyCachedPreferencesJson);
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return const {};
  }
}

