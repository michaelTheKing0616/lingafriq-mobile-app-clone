/// Translation History Service
/// Manages translation history with alternatives, grammar breakdown, and cultural context
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_history_model.dart';
import '../providers/user_provider.dart';
import '../providers/backend_sync_provider.dart';

final translationHistoryServiceProvider = Provider<TranslationHistoryService>((ref) {
  return TranslationHistoryService(ref);
});

class TranslationHistoryService {
  final Ref _ref;
  TranslationHistory? _cachedHistory;

  TranslationHistoryService(this._ref);

  /// Load translation history from local storage
  Future<TranslationHistory> loadHistory() async {
    if (_cachedHistory != null) return _cachedHistory!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('translation_history');
      
      if (historyJson != null && historyJson.isNotEmpty) {
        _cachedHistory = TranslationHistory.fromJsonString(historyJson);
        return _cachedHistory!;
      }
    } catch (e) {
      debugPrint('Error loading translation history: $e');
    }

    _cachedHistory = TranslationHistory();
    return _cachedHistory!;
  }

  /// Save translation history to local storage
  Future<void> saveHistory(TranslationHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedHistory = history.copyWith(lastUpdated: DateTime.now());
      await prefs.setString('translation_history', updatedHistory.toJsonString());
      _cachedHistory = updatedHistory;
      
      // Sync to backend
      await _syncToBackend(updatedHistory);
    } catch (e) {
      debugPrint('Error saving translation history: $e');
    }
  }

  /// Add a translation entry
  Future<void> addTranslation(TranslationEntry entry) async {
    final history = await loadHistory();
    final entries = [entry, ...history.entries];
    
    // Update language pair counts
    final pairKey = '${entry.sourceLanguage}-${entry.targetLanguage}';
    final pairCounts = Map<String, int>.from(history.languagePairCounts);
    pairCounts[pairKey] = (pairCounts[pairKey] ?? 0) + 1;
    
    final updatedHistory = history.copyWith(
      entries: entries,
      languagePairCounts: pairCounts,
    );
    
    await saveHistory(updatedHistory);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String entryId) async {
    final history = await loadHistory();
    final entries = history.entries.map((e) {
      if (e.id == entryId) {
        return e.copyWith(isFavorite: !e.isFavorite);
      }
      return e;
    }).toList();
    
    final updatedHistory = history.copyWith(entries: entries);
    await saveHistory(updatedHistory);
  }

  /// Delete a translation entry
  Future<void> deleteTranslation(String entryId) async {
    final history = await loadHistory();
    final entries = history.entries.where((e) => e.id != entryId).toList();
    
    final updatedHistory = history.copyWith(entries: entries);
    await saveHistory(updatedHistory);
  }

  /// Get favorites
  Future<List<TranslationEntry>> getFavorites() async {
    final history = await loadHistory();
    return history.getFavorites();
  }

  /// Search translations
  Future<List<TranslationEntry>> search(String query) async {
    final history = await loadHistory();
    return history.search(query);
  }

  /// Get by language pair
  Future<List<TranslationEntry>> getByLanguagePair(
      String sourceLang, String targetLang) async {
    final history = await loadHistory();
    return history.getByLanguagePair(sourceLang, targetLang);
  }

  /// Clear cached history
  void clearCache() {
    _cachedHistory = null;
  }

  /// Sync to backend
  Future<void> _syncToBackend(TranslationHistory history) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      final syncProvider = _ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.progress, // SyncType.progress exists in backend_sync_provider
        data: {
          'user_id': user.id.toString(),
          'type': 'translation_history',
          'history': history.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error syncing translation history: $e');
    }
  }
}

