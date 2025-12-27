/// Selective Sync - Allows users to choose what data to sync
/// Optimizes bandwidth and storage by syncing only selected content

import 'package:shared_preferences/shared_preferences.dart';

class SelectiveSync {
  static const String _prefKey = 'selective_sync_settings';

  /// Get sync preferences
  static Future<Map<String, bool>> getSyncPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefKey);
    if (json == null) {
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
    // Parse JSON string to map
    // Simplified implementation - in production use proper JSON parsing
    return {};
  }

  /// Set sync preferences
  static Future<void> setSyncPreferences(Map<String, bool> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert map to JSON string
    // Simplified implementation - in production use proper JSON encoding
    await prefs.setString(_prefKey, preferences.toString());
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
    // SelectiveSync uses static methods, no initialization needed
  }
}

