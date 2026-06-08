import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:lingafriq/utils/supported_languages.dart';

/// Languages present in [lingafriq_authentic_curriculum_a1_c2.json] / game bundles.
class CurriculumLanguages {
  CurriculumLanguages._();

  static const bundleKeys = [
    'yoruba',
    'hausa',
    'igbo',
    'swahili',
    'zulu',
    'xhosa',
    'wolof',
    'pidgin',
    'nigerian_pidgin',
    'afrikaans',
    'amharic',
    'twi',
    'somali',
    'lingala',
    'shona',
  ];

  /// Keys for UI dropdown (deduped pidgin variants).
  static List<String> pickerKeys({List<String>? fromMeta}) {
    final meta = fromMeta ?? const [];
    final merged = <String>{...meta, ...bundleKeys};
    final list = merged.toList();
    if (list.contains('pidgin') && list.contains('nigerian_pidgin')) {
      list.remove('nigerian_pidgin');
    }
    list.sort((a, b) => displayName(a).compareTo(displayName(b)));
    return list;
  }

  static String displayName(String key) {
    final normalized = CurriculumService.normalizeLanguageKey(key);
    if (normalized == 'nigerian_pidgin' || normalized == 'pidgin') {
      return 'Nigerian Pidgin';
    }
    final info = SupportedLanguages.getLanguageInfo(normalized);
    final name = info['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return normalized
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  /// Maps API [Language] rows to bundled curriculum keys.
  static String keyForApiLanguage(Language language) {
    final byName = SupportedLanguages.getKeyFromDisplayName(language.name);
    if (byName != null) return byName;
    return CurriculumService.normalizeLanguageKey(language.name);
  }
}
