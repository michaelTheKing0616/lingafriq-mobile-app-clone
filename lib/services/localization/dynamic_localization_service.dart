/// Dynamic Localization Service - Manages app language and localization
/// Supports runtime language switching and RTL languages

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum AppLanguage {
  english('en', 'English'),
  french('fr', 'Français'),
  yoruba('yo', 'Yorùbá'),
  hausa('ha', 'Hausa'),
  igbo('ig', 'Igbo'),
  swahili('sw', 'Kiswahili'),
  zulu('zu', 'isiZulu'),
  xhosa('xh', 'isiXhosa'),
  amharic('am', 'አማርኛ'),
  twi('tw', 'Twi'),
  afrikaans('af', 'Afrikaans'),
  pidgin('pcm', 'Nigerian Pidgin'),
  wolof('wo', 'Wolof'),
  somali('so', 'Soomaali');

  final String code;
  final String name;
  const AppLanguage(this.code, this.name);
}

class DynamicLocalizationService {
  static const String _prefKey = 'app_language';
  static AppLanguage _currentLanguage = AppLanguage.english;
  static Locale _currentLocale = const Locale('en');

  /// Initialize localization service (static)
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey) ?? 'en';
    await setLanguage(languageCode);
  }

  /// Initialize localization service (instance method)
  Future<void> initialize() async {
    await DynamicLocalizationService.initialize();
  }

  /// Get current language
  static AppLanguage get currentLanguage => _currentLanguage;

  /// Get current locale
  static Locale get currentLocale => _currentLocale;

  /// Set app language (static)
  static Future<void> setLanguage(String languageCode) async {
    final language = AppLanguage.values.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => AppLanguage.english,
    );

    _currentLanguage = language;
    _currentLocale = Locale(language.code);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);

    // Update Intl locale
    Intl.defaultLocale = languageCode;
  }

  /// Set app language (instance method)
  Future<void> setLanguage(dynamic language) async {
    if (language is String) {
      await DynamicLocalizationService.setLanguage(language);
    } else if (language is AppLanguage) {
      await DynamicLocalizationService.setLanguage(language.code);
    }
  }

  /// Get all supported languages
  static List<AppLanguage> getSupportedLanguages() {
    return AppLanguage.values;
  }

  /// Check if language is RTL
  static bool isRTL(String? languageCode) {
    // Arabic, Hebrew, etc. are RTL
    // For now, none of our supported languages are RTL
    return false;
  }

  /// Get text direction for current language
  static TextDirection getTextDirection() {
    return isRTL(_currentLanguage.code) ? TextDirection.rtl : TextDirection.ltr;
  }
}

