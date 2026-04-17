// Selective Sync - Allows users to choose what data to sync
// Optimizes bandwidth and storage by syncing only selected content

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/offline/sync_v2_service.dart';

/// Sync category enum for type-safe sync preferences
enum SyncCategory {
  lessons,
  quizzes,
  progress,
  media,
  cultureMagazine,
  games,
  profile, // Added for settings screen compatibility
  chat, // Added for settings screen compatibility
  achievements, // Added for settings screen compatibility
  content, // Added for settings screen compatibility
  settings, // Added for settings screen compatibility
}

/// Sync preference model
class SyncPreference {
  final SyncCategory category;
  final bool enabled;
  final DateTime? lastSynced;
  final bool syncOnWifiOnly;
  final int? maxSize; // Max size in MB

  SyncPreference({
    required this.category,
    required this.enabled,
    this.lastSynced,
    this.syncOnWifiOnly = false,
    this.maxSize,
  });

  Map<String, dynamic> toMap() => {
    'category': category.name,
    'enabled': enabled,
    'lastSynced': lastSynced?.toIso8601String(),
    'syncOnWifiOnly': syncOnWifiOnly,
    'maxSize': maxSize,
  };

  factory SyncPreference.fromMap(Map<String, dynamic> map) => SyncPreference(
    category: SyncCategory.values.firstWhere(
      (e) => e.name == map['category'],
      orElse: () => SyncCategory.lessons,
    ),
    enabled: map['enabled'] as bool? ?? true,
    lastSynced: map['lastSynced'] != null 
        ? DateTime.parse(map['lastSynced'])
        : null,
    syncOnWifiOnly: map['syncOnWifiOnly'] as bool? ?? false,
    maxSize: map['maxSize'] as int?,
  );

  SyncPreference copyWith({
    SyncCategory? category,
    bool? enabled,
    DateTime? lastSynced,
    bool? syncOnWifiOnly,
    int? maxSize,
  }) {
    return SyncPreference(
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      lastSynced: lastSynced ?? this.lastSynced,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      maxSize: maxSize ?? this.maxSize,
    );
  }
}

class SelectiveSync {
  static const String _prefKey = 'selective_sync_settings';
  static const String _serverPreferencesKey = 'selectiveSync';

  /// Get sync preferences
  static Future<Map<String, bool>> getSyncPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.trim().isEmpty) {
      // Default: sync everything
      return {
        'lessons': true,
        'quizzes': true,
        'progress': true,
        'media': false, // Media is large, default to false
        'culture_magazine': true,
        'games': true,
      };
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, bool>{};
      for (final entry in decoded.entries) {
        final k = entry.key?.toString();
        if (k == null || k.isEmpty) continue;
        final v = entry.value;
        if (v is bool) {
          out[k] = v;
        } else if (v is num) {
          out[k] = v != 0;
        } else if (v is String) {
          out[k] = v.toLowerCase() == 'true';
        }
      }
      return out;
    } catch (_) {
      // Corrupt/legacy value; fall back to defaults.
      return {};
    }
  }

  /// Set sync preferences
  static Future<void> setSyncPreferences(Map<String, bool> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(preferences));
  }

  /// Check if a content type should be synced
  static Future<bool> shouldSync(String contentType) async {
    final preferences = await getSyncPreferences();
    return preferences[contentType] ?? true;
  }

  /// Enable sync for content type
  static Future<void> enableSync(String contentType) async {
    final preferences = await getSyncPreferences();
    preferences[contentType] = true;
    await setSyncPreferences(preferences);
  }

  /// Disable sync for content type
  static Future<void> disableSync(String contentType) async {
    final preferences = await getSyncPreferences();
    preferences[contentType] = false;
    await setSyncPreferences(preferences);
  }
}

/// Service wrapper for SelectiveSync
class SelectiveSyncService {
  static final SelectiveSyncService _instance = SelectiveSyncService._internal();
  factory SelectiveSyncService() => _instance;
  SelectiveSyncService._internal();

  Future<void> initialize() async {
    // Best-effort: apply cached server preferences to local store.
    // We keep local as the immediate UX source of truth; server acts as roaming backup.
    final cached = await SyncV2Service.instance.getCachedPreferences();
    final fromServer = cached[SelectiveSync._serverPreferencesKey];
    if (fromServer is Map) {
      final merged = <String, bool>{};
      for (final e in fromServer.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is bool) merged[k] = v;
      }
      if (merged.isNotEmpty) {
        await SelectiveSync.setSyncPreferences(merged);
      }
    }
  }

  /// Set sync preference
  Future<void> setPreference(SyncPreference preference) async {
    final allPrefs = await getAllPreferences();
    allPrefs[preference.category] = preference;
    await _saveAllPreferences(allPrefs);
    await _pushToServer(allPrefs);
  }

  /// Get all sync preferences as Map<SyncCategory, SyncPreference>
  Future<Map<SyncCategory, SyncPreference>> getAllPreferences() async {
    final prefs = await SelectiveSync.getSyncPreferences();
    final Map<SyncCategory, SyncPreference> result = {};
    
    for (final entry in prefs.entries) {
      final category = SyncCategory.values.firstWhere(
        (c) => c.name == entry.key || _mapCategoryName(c.name) == entry.key,
        orElse: () => SyncCategory.lessons,
      );
      result[category] = SyncPreference(
        category: category,
        enabled: entry.value,
      );
    }
    
    // Ensure all categories are present
    for (final category in SyncCategory.values) {
      if (!result.containsKey(category)) {
        result[category] = SyncPreference(
          category: category,
          enabled: true, // Default to enabled
        );
      }
    }
    
    return result;
  }

  /// Save all preferences
  Future<void> _saveAllPreferences(Map<SyncCategory, SyncPreference> preferences) async {
    final Map<String, bool> prefsMap = {};
    for (final entry in preferences.entries) {
      prefsMap[entry.key.name] = entry.value.enabled;
    }
    await SelectiveSync.setSyncPreferences(prefsMap);
  }

  Future<void> _pushToServer(Map<SyncCategory, SyncPreference> preferences) async {
    try {
      final local = <String, bool>{};
      for (final entry in preferences.entries) {
        local[entry.key.name] = entry.value.enabled;
      }

      final current = await SyncV2Service.instance.getCachedPreferences();
      final next = <String, dynamic>{...current};
      next[SelectiveSync._serverPreferencesKey] = local;

      await SyncV2Service.instance.putPreferences(next);
    } catch (_) {
      // Offline-first: local write already succeeded; server roaming is best-effort.
    }
  }

  /// Map category name to legacy format if needed
  String _mapCategoryName(String name) {
    switch (name) {
      case 'cultureMagazine':
        return 'culture_magazine';
      default:
        return name;
    }
  }
}

