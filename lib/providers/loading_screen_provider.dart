import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/models/loading_screen_content.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing loading screen content
/// Supports both client-side (local) and backend (API) content
final loadingScreenProvider =
    StateNotifierProvider<LoadingScreenNotifier, LoadingScreenContent>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LoadingScreenNotifier(ref, prefs.prefs);
});

class LoadingScreenNotifier extends StateNotifier<LoadingScreenContent> {
  final Ref _ref;
  final SharedPreferences _prefs;
  static const String _lastContentKey = 'last_loading_content_id';
  static const String _viewedContentKey = 'viewed_loading_content_ids';
  static const String _useBackendKey = 'use_backend_loading_content'; // Feature flag

  LoadingScreenNotifier(this._ref, this._prefs) 
      : super(LoadingScreenContentData.defaultContent.first) {
    _loadContent();
  }

  /// Load content, ensuring variety by avoiding recently shown content
  /// Tries backend first, falls back to local content if backend fails
  Future<void> _loadContent() async {
    // Check if backend should be used (feature flag)
    // Default to true since backend is running and we have fallback
    final useBackend = _prefs.getBool(_useBackendKey) ?? true;
    
    if (useBackend) {
      try {
        // Try to load from backend
        final contentData = await _ref.read(apiProvider.notifier).getLoadingScreenContent();
        final content = LoadingScreenContent.fromJson(contentData);
        state = content;
        
        // Save to local preferences as backup
        await _prefs.setString(_lastContentKey, content.id);
        return;
      } catch (e) {
        // Backend failed, fall back to local content
        print('Loading screen: Backend failed, using local content: $e');
        _loadLocalContent();
        return;
      }
    }
    
    // Use local content (default)
    _loadLocalContent();
  }

  /// Load content from local static data
  void _loadLocalContent() {
    final lastId = _prefs.getString(_lastContentKey);
    final viewedIds = _prefs.getStringList(_viewedContentKey) ?? [];
    
    // Get all content except recently viewed ones
    var availableContent = LoadingScreenContentData.defaultContent
        .where((c) => c.id != lastId && !viewedIds.contains(c.id))
        .toList();
    
    // If we've seen all content, reset and start fresh
    if (availableContent.isEmpty) {
      availableContent = LoadingScreenContentData.defaultContent;
      _prefs.remove(_viewedContentKey);
    }
    
    // Select random content
    final random = Random();
    final selected = availableContent[random.nextInt(availableContent.length)];
    
    // Update state
    state = selected;
    
    // Save to preferences
    _prefs.setString(_lastContentKey, selected.id);
    final updatedViewed = [...viewedIds, selected.id];
    // Keep only last 5 viewed to allow rotation
    if (updatedViewed.length > 5) {
      updatedViewed.removeAt(0);
    }
    _prefs.setStringList(_viewedContentKey, updatedViewed);
  }

  /// Refresh content (get a new one)
  void refreshContent() {
    _loadContent();
  }

  /// Enable/disable backend integration
  Future<void> setUseBackend(bool useBackend) async {
    await _prefs.setBool(_useBackendKey, useBackend);
    _loadContent(); // Reload with new setting
  }

  /// Check if backend is enabled
  bool get useBackend => _prefs.getBool(_useBackendKey) ?? false;

  /// Get content for a specific country
  void setContentByCountry(String country) {
    final countryContent = LoadingScreenContentData.getByCountry(country);
    if (countryContent.isNotEmpty) {
      final random = Random();
      state = countryContent[random.nextInt(countryContent.length)];
      _prefs.setString(_lastContentKey, state.id);
    }
  }

  /// Get content for a specific language
  void setContentByLanguage(String language) {
    final languageContent = LoadingScreenContentData.getByLanguage(language);
    if (languageContent.isNotEmpty) {
      final random = Random();
      state = languageContent[random.nextInt(languageContent.length)];
      _prefs.setString(_lastContentKey, state.id);
    }
  }

  /// Future: Fetch AI-generated image URL
  /// This can be integrated with an AI image generation service
  Future<String> fetchAIGeneratedImage({
    required String country,
    required String language,
  }) async {
    // TODO: Implement AI image generation API call
    // Example: Use DALL-E, Midjourney API, or custom AI service
    // For now, return placeholder
    return 'assets/images/loading/placeholder.png';
  }
}

