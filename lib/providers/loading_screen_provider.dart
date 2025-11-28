import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/loading_screen_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing loading screen content
final loadingScreenProvider =
    StateNotifierProvider<LoadingScreenNotifier, LoadingScreenContent>((ref) {
  return LoadingScreenNotifier();
});

class LoadingScreenNotifier extends StateNotifier<LoadingScreenContent> {
  final SharedPreferences? _prefs;
  static const String _lastContentKey = 'last_loading_content_id';
  static const String _viewedContentKey = 'viewed_loading_content_ids';

  LoadingScreenNotifier([this._prefs]) : super(LoadingScreenContentData.defaultContent.first) {
    _loadContent();
  }

  /// Load content, ensuring variety by avoiding recently shown content
  void _loadContent() {
    final lastId = _prefs?.getString(_lastContentKey);
    final viewedIds = _prefs?.getStringList(_viewedContentKey) ?? [];
    
    // Get all content except recently viewed ones
    var availableContent = LoadingScreenContentData.defaultContent
        .where((c) => c.id != lastId && !viewedIds.contains(c.id))
        .toList();
    
    // If we've seen all content, reset and start fresh
    if (availableContent.isEmpty) {
      availableContent = LoadingScreenContentData.defaultContent;
      _prefs?.remove(_viewedContentKey);
    }
    
    // Select random content
    final random = Random();
    final selected = availableContent[random.nextInt(availableContent.length)];
    
    // Update state
    state = selected;
    
    // Save to preferences
    _prefs?.setString(_lastContentKey, selected.id);
    final updatedViewed = [...viewedIds, selected.id];
    // Keep only last 5 viewed to allow rotation
    if (updatedViewed.length > 5) {
      updatedViewed.removeAt(0);
    }
    _prefs?.setStringList(_viewedContentKey, updatedViewed);
  }

  /// Refresh content (get a new one)
  void refreshContent() {
    _loadContent();
  }

  /// Get content for a specific country
  void setContentByCountry(String country) {
    final countryContent = LoadingScreenContentData.getByCountry(country);
    if (countryContent.isNotEmpty) {
      final random = Random();
      state = countryContent[random.nextInt(countryContent.length)];
      _prefs?.setString(_lastContentKey, state.id);
    }
  }

  /// Get content for a specific language
  void setContentByLanguage(String language) {
    final languageContent = LoadingScreenContentData.getByLanguage(language);
    if (languageContent.isNotEmpty) {
      final random = Random();
      state = languageContent[random.nextInt(languageContent.length)];
      _prefs?.setString(_lastContentKey, state.id);
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

