import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/onboarding_provider.dart';
import 'hybrid_polie/translation_service.dart';

/// Lightweight localization service that uses the existing Hybrid Polie
/// TranslationService to translate UI copy into the learner's interface
/// language. English remains the default/fallback.
final localizationProvider = Provider<LocalizationService>((ref) {
  final onboarding = ref.watch(onboardingProvider);
  final selectedLang = (onboarding.selectedLanguage ?? 'english').toLowerCase();
  return LocalizationService(interfaceLanguage: selectedLang);
});

class LocalizationService {
  final String interfaceLanguage;
  final TranslationService _translationService = TranslationService();
  final Map<String, String> _cache = {};

  LocalizationService({required this.interfaceLanguage});

  /// Translate an English string into the interface language.
  /// If the interface language is English (or unknown), returns the English
  /// text directly. Results are cached in-memory for the session.
  Future<String> t({
    required String key,
    required String english,
  }) async {
    final target = interfaceLanguage;

    // If interface language is English (or not set), just return the base text.
    if (target.isEmpty ||
        target == 'english' ||
        target == 'en' ||
        target == 'eng') {
      return english;
    }

    final cacheKey = '$target::$key';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final result = await _translationService.translate(
        text: english,
        sourceLang: 'english',
        targetLang: target,
      );
      final value =
          (result.translation.isNotEmpty ? result.translation : english);
      _cache[cacheKey] = value;
      return value;
    } catch (_) {
      // Fail open to English on any error.
      return english;
    }
  }
}


