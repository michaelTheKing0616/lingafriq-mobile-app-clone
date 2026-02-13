/// Supported Languages Utility
/// Centralized management of all supported African languages

class SupportedLanguages {
  static const Map<String, Map<String, dynamic>> _languages = {
    'yoruba': {
      'name': 'Yoruba',
      'code': 'yo',
      'flag': '🇳🇬',
      'country': 'Nigeria',
      'iso639_3': 'yor',
      'requiresDiacritics': true,
      'validChars': 'abcdefghijklmnopqrstuvwxyzàáâãäèéêëìíîïòóôõöùúûüỳýŷÿ',
    },
    'hausa': {
      'name': 'Hausa',
      'code': 'ha',
      'flag': '🇳🇬',
      'country': 'Nigeria',
      'iso639_3': 'hau',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'igbo': {
      'name': 'Igbo',
      'code': 'ig',
      'flag': '🇳🇬',
      'country': 'Nigeria',
      'iso639_3': 'ibo',
      'requiresDiacritics': true,
      'validChars': 'abcdefghijklmnopqrstuvwxyzàáâãäèéêëìíîïòóôõöùúûü',
    },
    'swahili': {
      'name': 'Swahili',
      'code': 'sw',
      'flag': '🇰🇪',
      'country': 'Kenya',
      'iso639_3': 'swa',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'zulu': {
      'name': 'Zulu',
      'code': 'zu',
      'flag': '🇿🇦',
      'country': 'South Africa',
      'iso639_3': 'zul',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'xhosa': {
      'name': 'Xhosa',
      'code': 'xh',
      'flag': '🇿🇦',
      'country': 'South Africa',
      'iso639_3': 'xho',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'amharic': {
      'name': 'Amharic',
      'code': 'am',
      'flag': '🇪🇹',
      'country': 'Ethiopia',
      'iso639_3': 'amh',
      'requiresDiacritics': true,
      'validChars': 'ሀሁሂሃሄህሆሇለሉሊላሌልሎሏሐሑሒሓሔሕሖሗመሙሚማሜምሞሟሠሡሢሣሤሥሦሧረሩሪራሬርሮሯሰሱሲሳሴስሶሷሸሹሺሻሼሽሾሿቀቁቂቃቄቅቆቇቈ቉ቊቋቌቍ቎቏ቐቑቒቓቔቕቖ቗ቘ቙ቚቛቜቝ቞቟በቡቢባቤብቦቧቨቩቪቫቬቭቮቯተቱቲታቴትቶቷቸቹቺቻቼችቾቿኀኁኂኃኄኅኆኇኈ኉ኊኋኌኍ኎኏ነኑኒናኔንኖኗኘኙኚኛኜኝኞኟአኡኢኣኤእኦኧከኩኪካኬክኮኯኰ኱ኲኳኴኵ኶኷ኸኹኺኻኼኽኾ኿ዀ዁ዂዃዄዅ዆዇ወዉዊዋዌውዎዏዐዑዒዓዔዕዖ዗ዘዙዚዛዜዝዞዟዠዡዢዣዤዥዦዧየዩዪያዬይዮዯደዱዲዳዴድዶዷዸዹዺዻዼዽዾዿጀጁጂጃጄጅጆጇገጉጊጋጌግጎጏጐ጑ጒጓጔጕ጖጗ጘጙጚጛጜጝጞጟጠጡጢጣጤጥጦጧጨጩጪጫጬጭጮጯጰጱጲጳጴጵጶጷጸጹጺጻጼጽጾጿፀፁፂፃፄፅፆፇፈፉፊፋፌፍፎፏፐፑፒፓፔፕፖፗ',
    },
    'twi': {
      'name': 'Twi',
      'code': 'tw',
      'flag': '🇬🇭',
      'country': 'Ghana',
      'iso639_3': 'twi',
      'requiresDiacritics': true,
      'validChars': 'abcdefghijklmnopqrstuvwxyzàáâãäèéêëìíîïòóôõöùúûü',
    },
    'afrikaans': {
      'name': 'Afrikaans',
      'code': 'af',
      'flag': '🇿🇦',
      'country': 'South Africa',
      'iso639_3': 'afr',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'pidgin': {
      'name': 'Nigerian Pidgin',
      'code': 'pcm',
      'flag': '🇳🇬',
      'country': 'Nigeria',
      'iso639_3': 'pcm',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'wolof': {
      'name': 'Wolof',
      'code': 'wo',
      'flag': '🇸🇳',
      'country': 'Senegal',
      'iso639_3': 'wol',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
    'somali': {
      'name': 'Somali',
      'code': 'so',
      'flag': '🇸🇴',
      'country': 'Somalia',
      'iso639_3': 'som',
      'requiresDiacritics': false,
      'validChars': 'abcdefghijklmnopqrstuvwxyz',
    },
  };
  
  /// Get all supported languages
  static List<String> get allLanguages => _languages.keys.toList();
  
  /// Get language info
  static Map<String, dynamic> getLanguageInfo(String language) {
    final key = language.toLowerCase();
    return _languages[key] ?? {};
  }
  
  /// Get valid characters for a language
  static String getValidCharacters(String language) {
    final info = getLanguageInfo(language);
    return info['validChars'] ?? 'abcdefghijklmnopqrstuvwxyz';
  }
  
  /// Check if language requires diacritics
  static bool requiresDiacritics(String language) {
    final info = getLanguageInfo(language);
    return info['requiresDiacritics'] ?? false;
  }
  
  /// Get language code (ISO 639-1 or ISO 639-3 for Pidgin). Used by AI prompts so models receive unambiguous codes.
  static String getLanguageCode(String language) {
    final info = getLanguageInfo(language);
    return info['code'] ?? language.toLowerCase();
  }

  /// Canonical key from display name (e.g. "Yoruba" -> "yoruba"). Used to look up code/name consistently.
  static String? getKeyFromDisplayName(String displayName) {
    if (displayName.isEmpty) return null;
    final lower = displayName.toLowerCase();
    for (final entry in _languages.entries) {
      final name = (entry.value['name'] as String?)?.toLowerCase();
      if (name == lower || entry.key == lower) return entry.key;
    }
    return null;
  }

  /// Returns a string for AI system prompts: "Target: Yorùbá (ISO 639-1: yo)". Ensures AI models receive language codes.
  static String targetLanguagePromptLine(String targetLanguage) {
    final key = getKeyFromDisplayName(targetLanguage) ?? targetLanguage.toLowerCase();
    final info = getLanguageInfo(key);
    final name = info['name'] as String? ?? targetLanguage;
    final code = info['code'] as String? ?? key;
    return 'Target language: $name (ISO 639-1: $code)';
  }

  /// Returns a string for AI system prompts: "Source: English" or "Source: Yorùbá (ISO 639-1: yo)".
  static String sourceLanguagePromptLine(String sourceLanguage) {
    final key = getKeyFromDisplayName(sourceLanguage) ?? sourceLanguage.toLowerCase();
    final info = getLanguageInfo(key);
    if (info.isEmpty) return 'Source language: $sourceLanguage';
    final name = info['name'] as String? ?? sourceLanguage;
    final code = info['code'] as String? ?? key;
    return 'Source language: $name (ISO 639-1: $code)';
  }

  /// Get language key from ISO 639-1 code (e.g. "yo" -> "yoruba"). Returns null if not found.
  static String? getKeyFromCode(String code) {
    if (code.isEmpty) return null;
    final lower = code.toLowerCase();
    for (final entry in _languages.entries) {
      if ((entry.value['code'] as String?)?.toLowerCase() == lower) return entry.key;
    }
    return null;
  }

  /// Get country/region for UI (e.g. "Nigeria"). Returns null if not in map.
  static String? getCountry(String languageKeyOrCode) {
    final key = getKeyFromCode(languageKeyOrCode) ?? languageKeyOrCode.toLowerCase();
    final info = getLanguageInfo(key);
    return info['country'] as String?;
  }

  /// Get all language options for UI
  static List<Map<String, String>> getLanguageOptions() {
    return _languages.entries.map((entry) {
      final info = entry.value;
      return {
        'name': info['name'] as String,
        'code': info['code'] as String,
        'flag': info['flag'] as String,
      };
    }).toList();
  }
}
