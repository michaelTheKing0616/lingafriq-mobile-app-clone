/// Centralized list of all supported languages in the app
/// Ensures consistency across AI chat, games, diacritics, and all features
class SupportedLanguages {
  /// All supported languages with their codes and display names
  static const List<LanguageInfo> all = [
    LanguageInfo(name: 'Yoruba', code: 'yoruba', flag: '🇳🇬', isoCode: 'yo'),
    LanguageInfo(name: 'Hausa', code: 'hausa', flag: '🇳🇬', isoCode: 'ha'),
    LanguageInfo(name: 'Igbo', code: 'igbo', flag: '🇳🇬', isoCode: 'ig'),
    LanguageInfo(name: 'Swahili', code: 'swahili', flag: '🇰🇪', isoCode: 'sw'),
    LanguageInfo(name: 'Zulu', code: 'zulu', flag: '🇿🇦', isoCode: 'zu'),
    LanguageInfo(name: 'Xhosa', code: 'xhosa', flag: '🇿🇦', isoCode: 'xh'),
    LanguageInfo(name: 'Amharic', code: 'amharic', flag: '🇪🇹', isoCode: 'am'),
    LanguageInfo(name: 'Twi', code: 'twi', flag: '🇬🇭', isoCode: 'tw'),
    LanguageInfo(name: 'Afrikaans', code: 'afrikaans', flag: '🇿🇦', isoCode: 'af'),
    LanguageInfo(name: 'Nigerian Pidgin', code: 'pidgin', flag: '🇳🇬', isoCode: 'pcm'),
    LanguageInfo(name: 'Wolof', code: 'wolof', flag: '🇸🇳', isoCode: 'wo'),
    LanguageInfo(name: 'Somali', code: 'somali', flag: '🇸🇴', isoCode: 'so'),
  ];

  /// Get language by code
  static LanguageInfo? getByCode(String code) {
    return all.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => all.first, // Default to Yoruba
    );
  }

  /// Get language by ISO code
  static LanguageInfo? getByISOCode(String isoCode) {
    return all.firstWhere(
      (lang) => lang.isoCode.toLowerCase() == isoCode.toLowerCase(),
      orElse: () => all.first,
    );
  }

  /// Get all language codes
  static List<String> get codes => all.map((lang) => lang.code).toList();

  /// Get all language names
  static List<String> get names => all.map((lang) => lang.name).toList();

  /// Get all ISO codes
  static List<String> get isoCodes => all.map((lang) => lang.isoCode).toList();

  /// Check if language is supported
  static bool isSupported(String code) {
    return all.any((lang) => lang.code.toLowerCase() == code.toLowerCase());
  }

  /// Languages that require diacritics
  static const List<String> diacriticsRequired = [
    'yoruba',
    'igbo',
    'twi',
    'wolof',
  ];

  /// Check if language requires diacritics
  static bool requiresDiacritics(String code) {
    return diacriticsRequired.contains(code.toLowerCase());
  }

  /// Tonal languages
  static const List<String> tonalLanguages = [
    'yoruba',
    'igbo',
    'twi',
    'xhosa',
    'zulu',
  ];

  /// Check if language is tonal
  static bool isTonal(String code) {
    return tonalLanguages.contains(code.toLowerCase());
  }
}

class LanguageInfo {
  final String name;
  final String code;
  final String flag;
  final String isoCode;

  const LanguageInfo({
    required this.name,
    required this.code,
    required this.flag,
    required this.isoCode,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'flag': flag,
        'isoCode': isoCode,
      };

  factory LanguageInfo.fromJson(Map<String, dynamic> json) => LanguageInfo(
        name: json['name'],
        code: json['code'],
        flag: json['flag'],
        isoCode: json['isoCode'],
      );
}

