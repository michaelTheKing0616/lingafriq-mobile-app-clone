import 'package:shared_preferences/shared_preferences.dart';

import '../models/language_response.dart';
import '../services/localization/dynamic_localization_service.dart';

/// Every slug produced by [_isoCodeToGamesSlug] / [_normalizeVerboseLanguage],
/// in stable hub order (dropdowns, chips, lazy-load UIs).
const List<String> kGamesHubLanguageSlugs = [
  'yoruba',
  'hausa',
  'igbo',
  'swahili',
  'zulu',
  'xhosa',
  'amharic',
  'pidgin',
  'twi',
  'wolof',
  'afrikaans',
];

/// [AppLanguage] entries aligned with [kGamesHubLanguageSlugs] (same order).
/// Slugs for APIs are derived via [gamesBackendSlugFromAppLanguage] using ISO
/// [AppLanguage.code], not enum member names (the enum exposes a custom `name`
/// field for display strings).
const List<AppLanguage> kAppLanguagesForGamesHub = [
  AppLanguage.yoruba,
  AppLanguage.hausa,
  AppLanguage.igbo,
  AppLanguage.swahili,
  AppLanguage.zulu,
  AppLanguage.xhosa,
  AppLanguage.amharic,
  AppLanguage.pidgin,
  AppLanguage.twi,
  AppLanguage.wolof,
  AppLanguage.afrikaans,
];

/// Maps onboarding / profile ISO codes to the lowercase language slug used by
/// `GET /api/games/cards` and the games hub (`yoruba`, `swahili`, …).
const Map<String, String> _isoCodeToGamesSlug = {
  'yo': 'yoruba',
  'ha': 'hausa',
  'ig': 'igbo',
  'sw': 'swahili',
  'zu': 'zulu',
  'xh': 'xhosa',
  'am': 'amharic',
  'pcm': 'pidgin',
  'wo': 'wolof',
  'tw': 'twi',
  'af': 'afrikaans',
};

String _normalizeVerboseLanguage(String s) {
  if (s == 'nigerian pidgin' || s == 'pidgin english') return 'pidgin';
  if (s.startsWith('yor')) return 'yoruba';
  if (s == 'kiswahili') return 'swahili';
  return s;
}

/// Resolves which language string to use for game card prefetch at startup.
///
/// Priority: saved `learning_language` (ISO or slug) → UI [AppLanguage] code if
/// it maps to a game language → [fallback] (default `yoruba`).
String resolveGamesPrefetchLanguageSync(
  SharedPreferences prefs, {
  String fallback = 'yoruba',
}) {
  final raw = prefs.getString('learning_language')?.trim();
  if (raw != null && raw.isNotEmpty) {
    final lower = raw.toLowerCase();
    final fromIso = _isoCodeToGamesSlug[lower];
    if (fromIso != null) return fromIso;
    if (lower.length > 2) {
      return _normalizeVerboseLanguage(lower);
    }
  }

  final uiCode = DynamicLocalizationService.currentLanguage.code.toLowerCase();
  final fromUi = _isoCodeToGamesSlug[uiCode];
  if (fromUi != null) return fromUi;

  return fallback;
}

/// Same as [resolveGamesPrefetchLanguageSync], but only returns slugs that exist
/// in [kGamesHubLanguageSlugs] so dropdowns / [DropdownButtonFormField] stay valid.
String resolveGamesHubLanguageSync(
  SharedPreferences prefs, {
  String fallback = 'yoruba',
}) {
  final resolved = resolveGamesPrefetchLanguageSync(prefs, fallback: fallback);
  if (kGamesHubLanguageSlugs.contains(resolved)) return resolved;
  return fallback;
}

/// Backend/query slug for [AppLanguage] (e.g. `pcm` → `pidgin`).
String gamesBackendSlugFromAppLanguage(AppLanguage lang) {
  final fromIso = _isoCodeToGamesSlug[lang.code.toLowerCase()];
  if (fromIso != null && kGamesHubLanguageSlugs.contains(fromIso)) {
    return fromIso;
  }
  return 'yoruba';
}

AppLanguage appLanguageForGamesHubSlug(String slug) {
  final lower = slug.trim().toLowerCase();
  for (final lang in kAppLanguagesForGamesHub) {
    if (gamesBackendSlugFromAppLanguage(lang) == lower) return lang;
  }
  return AppLanguage.yoruba;
}

AppLanguage resolveGamesHubAppLanguageSync(SharedPreferences prefs) {
  return appLanguageForGamesHubSlug(resolveGamesHubLanguageSync(prefs));
}

String displayTitleForGamesHubSlug(String slug) {
  if (slug.isEmpty) return slug;
  return slug[0].toUpperCase() + slug.substring(1);
}

/// Maps a legacy API [Language] row to a hub slug, or `null` if unsupported.
String? gamesHubSlugFromApiLanguage(Language api) {
  final level = api.level_language.trim().toLowerCase();
  if (level.isNotEmpty) {
    final fromIso = _isoCodeToGamesSlug[level];
    if (fromIso != null && kGamesHubLanguageSlugs.contains(fromIso)) {
      return fromIso;
    }
    if (kGamesHubLanguageSlugs.contains(level)) return level;
  }
  final rawName = api.name.trim().toLowerCase();
  if (rawName.isNotEmpty) {
    final normalized = _normalizeVerboseLanguage(rawName);
    if (kGamesHubLanguageSlugs.contains(normalized)) return normalized;
    for (final slug in kGamesHubLanguageSlugs) {
      if (rawName.contains(slug)) return slug;
    }
  }
  return null;
}

/// Ensures [Language.name] / [Language.level_language] match games-hub slugs for legacy game UIs.
Language languageNormalizedForGamesHub(
  Language api, {
  String fallbackSlug = 'yoruba',
}) {
  final slug = gamesHubSlugFromApiLanguage(api) ?? fallbackSlug;
  return api.copyWith(
    name: displayTitleForGamesHubSlug(slug),
    level_language: slug,
  );
}
