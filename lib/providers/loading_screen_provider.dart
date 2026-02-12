import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/loading_screen_content.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Provider for managing loading screen content
/// Supports both client-side (local) and backend (API) content
final loadingScreenProvider =
    NotifierProvider<LoadingScreenNotifier, LoadingScreenContent>(() {
  return LoadingScreenNotifier();
});

class LoadingScreenNotifier extends Notifier<LoadingScreenContent> {
  static const String _lastContentKey = 'last_loading_content_id';
  static const String _viewedContentKey = 'viewed_loading_content_ids';
  static const String _useBackendKey = 'use_backend_loading_content'; // Feature flag

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider).prefs;

  @override
  LoadingScreenContent build() {
    final initialState = LoadingScreenContentData.defaultContent.first;
    // Load content asynchronously after initial build
    Future.microtask(() => _loadContent());
    return initialState;
  }

  /// Load content, ensuring variety by avoiding recently shown content
  /// Tries backend first, falls back to local content if backend fails
  Future<void> _loadContent() async {
    // Check if backend should be used (feature flag)
    // Default to true since backend is running and we have fallback
    final useBackend = _prefs.getBool(_useBackendKey) ?? true;
    
    if (useBackend) {
      try {
        // Get last viewed content ID for variety
        final lastId = _prefs.getString(_lastContentKey);
        
        // Try to load from backend with parameters for variety
        final contentData = await ref.read(apiProvider.notifier).getLoadingScreenContent(
          lastContentId: lastId,
        );
        final content = LoadingScreenContent.fromJson(contentData);
        state = content;
        
        // Save to local preferences as backup
        await _prefs.setString(_lastContentKey, content.id);
        
        // Track viewed content
        final viewedIds = _prefs.getStringList(_viewedContentKey) ?? [];
        final updatedViewed = [...viewedIds, content.id];
        if (updatedViewed.length > 20) {
          updatedViewed.removeAt(0);
        }
        await _prefs.setStringList(_viewedContentKey, updatedViewed);
        return;
      } catch (e) {
        // Backend failed, fall back to local content
        logger.warn('Loading screen: Backend failed, using local content', tag: 'loading-screen', error: e);
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
    // Keep only last 20 viewed to allow more variety and avoid repetition
    // With 40+ facts, keeping 20 viewed ensures good rotation
    if (updatedViewed.length > 20) {
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

  /// Fetch AI-generated image URL from backend
  /// Uses the loading screen image generation endpoint
  Future<String> fetchAIGeneratedImage({
    required String country,
    required String language,
  }) async {
    try {
      // Use the prompt from the current content's fact
      final prompt = state.fact;
      
      if (prompt.isEmpty) {
        return 'assets/images/loading/placeholder.png';
      }

      // Call backend image generation endpoint via API client
      final response = await ref.read(client).get(
        ApiContract.url(ApiContract.ai.loadingScreenImage(prompt)),
        queryParameters: {
          'country': country,
          'language': language,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final imageUrl = data['imageUrl'] ?? data['image_url'] ?? data['url'];
        if (imageUrl != null && imageUrl is String) {
          return imageUrl;
        }
      }
    } catch (e) {
      logger.error('Failed to generate AI image', tag: 'loading-screen', error: e);
    }
    
    // Fallback to placeholder
    return 'assets/images/loading/placeholder.png';
  }
}
