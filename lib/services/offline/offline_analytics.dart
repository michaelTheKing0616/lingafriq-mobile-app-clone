// Offline Analytics - Tracks offline usage and sync metrics
// Provides insights into offline behavior and sync performance

import 'package:shared_preferences/shared_preferences.dart';

class OfflineAnalytics {
  static const String _prefKeyPrefix = 'offline_analytics_';

  /// Track offline session start
  static Future<void> trackOfflineSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    await prefs.setString('${_prefKeyPrefix}last_offline_start', timestamp);
    
    // Increment offline session count
    final count = prefs.getInt('${_prefKeyPrefix}offline_sessions') ?? 0;
    await prefs.setInt('${_prefKeyPrefix}offline_sessions', count + 1);
  }

  /// Track offline session end
  static Future<void> trackOfflineSessionEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final startTime = prefs.getString('${_prefKeyPrefix}last_offline_start');
    if (startTime != null) {
      final start = DateTime.parse(startTime);
      final duration = DateTime.now().difference(start);
      
      // Track total offline time
      final totalSeconds = prefs.getInt('${_prefKeyPrefix}total_offline_seconds') ?? 0;
      await prefs.setInt(
        '${_prefKeyPrefix}total_offline_seconds',
        totalSeconds + duration.inSeconds,
      );
    }
  }

  /// Track sync operation
  static Future<void> trackSync({
    required String operation,
    required bool success,
    int? itemsSynced,
    Duration? duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Track sync count
    final syncCount = prefs.getInt('${_prefKeyPrefix}sync_count') ?? 0;
    await prefs.setInt('${_prefKeyPrefix}sync_count', syncCount + 1);
    
    // Track success/failure
    final successCount = prefs.getInt('${_prefKeyPrefix}sync_success') ?? 0;
    final failureCount = prefs.getInt('${_prefKeyPrefix}sync_failure') ?? 0;
    
    if (success) {
      await prefs.setInt('${_prefKeyPrefix}sync_success', successCount + 1);
    } else {
      await prefs.setInt('${_prefKeyPrefix}sync_failure', failureCount + 1);
    }
    
    // Store last sync info
    await prefs.setString('${_prefKeyPrefix}last_sync_operation', operation);
    await prefs.setString('${_prefKeyPrefix}last_sync_time', DateTime.now().toIso8601String());
    if (itemsSynced != null) {
      await prefs.setInt('${_prefKeyPrefix}last_sync_items', itemsSynced);
    }
  }

  /// Get analytics summary
  static Future<Map<String, dynamic>> getAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'offline_sessions': prefs.getInt('${_prefKeyPrefix}offline_sessions') ?? 0,
      'total_offline_seconds': prefs.getInt('${_prefKeyPrefix}total_offline_seconds') ?? 0,
      'sync_count': prefs.getInt('${_prefKeyPrefix}sync_count') ?? 0,
      'sync_success': prefs.getInt('${_prefKeyPrefix}sync_success') ?? 0,
      'sync_failure': prefs.getInt('${_prefKeyPrefix}sync_failure') ?? 0,
      'last_sync_operation': prefs.getString('${_prefKeyPrefix}last_sync_operation'),
      'last_sync_time': prefs.getString('${_prefKeyPrefix}last_sync_time'),
      'last_sync_items': prefs.getInt('${_prefKeyPrefix}last_sync_items'),
    };
  }

  /// Clear analytics
  static Future<void> clearAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

/// Service wrapper for OfflineAnalytics
class OfflineAnalyticsService {
  static final OfflineAnalyticsService _instance = OfflineAnalyticsService._internal();
  factory OfflineAnalyticsService() => _instance;
  OfflineAnalyticsService._internal();

  Future<void> initialize() async {
    // OfflineAnalytics uses static methods, no initialization needed
  }
}

