import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/loading_screen_content.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        // Try to load from backend
        final contentData = await ref.read(apiProvider.notifier).getLoadingScreenContent();
        var content = LoadingScreenContent.fromJson(contentData);
        state = content;

        // Ask Polie for an additional micro-tip if possible
        content = await _attachAiTip(content);
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
    
    // Update state and enrich with AI tip
    state = selected;
    _attachAiTip(selected).then((enhanced) {
      state = enhanced;
    });
    
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
    // Best-effort: use backend curated images for the given country/language.
    // (True AI image generation would require a dedicated service + storage).
    try {
      final byCountry =
          await ref.read(apiProvider.notifier).getLoadingScreenContentByCountry(country);
      if (byCountry.isNotEmpty) {
        final imageUrl = byCountry.first['imageUrl']?.toString() ?? '';
        if (imageUrl.isNotEmpty) return imageUrl;
      }

      final byLanguage =
          await ref.read(apiProvider.notifier).getLoadingScreenContentByLanguage(language);
      if (byLanguage.isNotEmpty) {
        final imageUrl = byLanguage.first['imageUrl']?.toString() ?? '';
        if (imageUrl.isNotEmpty) return imageUrl;
      }
    } catch (_) {}

    // Fallback: empty string means “no remote image available”.
    return '';
  }

  /// Ask Polie for an additional loading-screen micro-tip and attach it
  /// to the LoadingScreenContent instance.
  Future<LoadingScreenContent> _attachAiTip(LoadingScreenContent base) async {
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final tip = await polieGenerator.generateLoadingScreenTip(
        language: base.language,
        greeting: base.greeting,
        fact: base.fact,
      );
      return LoadingScreenContent(
        id: base.id,
        imageUrl: base.imageUrl,
        country: base.country,
        countryFlag: base.countryFlag,
        greeting: base.greeting,
        greetingTranslation: base.greetingTranslation,
        language: base.language,
        fact: base.fact,
        personName: base.personName,
        aiTip: tip,
      );
    } catch (_) {
      return base;
    }
  }
}
