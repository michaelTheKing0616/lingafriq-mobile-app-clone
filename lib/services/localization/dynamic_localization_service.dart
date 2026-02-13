// Dynamic Localization Service - Manages app language and localization
// Supports runtime language switching and RTL languages

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:ui' as ui show TextDirection;

enum AppLanguage {
  english('en', 'English'),
  french('fr', 'Français'),
  portuguese('pt', 'Português'),
  spanish('es', 'Español'),
  arabic('ar', 'العربية'),
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
  somali('so', 'Soomaali'),
  tigrinya('ti', 'ትግርኛ'),
  shona('sn', 'ChiShona'),
  lingala('ln', 'Lingála'),
  kinyarwanda('rw', 'Ikinyarwanda'),
  malagasy('mg', 'Malagasy'),
  sesotho('st', 'Sesotho'),
  setswana('tn', 'Setswana');

  final String code;
  final String name;
  const AppLanguage(this.code, this.name);
  
  /// Display name for the language (alias for name)
  String get displayName => name;
}

class DynamicLocalizationService {
  static const String _prefKey = 'app_language';
  static AppLanguage _currentLanguage = AppLanguage.english;
  static Locale _currentLocale = const Locale('en');
  
  // Notifier to trigger UI rebuilds when language changes
  static final ValueNotifier<Locale> _localeNotifier = ValueNotifier<Locale>(const Locale('en'));
  static ValueNotifier<Locale> get localeNotifier => _localeNotifier;

  /// Initialize localization service (static)
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey) ?? 'en';
    await setLanguage(languageCode);
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
    
    // Notify listeners to trigger UI rebuild
    _localeNotifier.value = _currentLocale;
  }

  /// Get all supported languages
  static List<AppLanguage> getSupportedLanguages() {
    return AppLanguage.values;
  }

  /// Check if language is RTL
  static bool isRTL(String? languageCode) {
    // Arabic and Hebrew are RTL languages
    if (languageCode == null) return false;
    final rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(languageCode.toLowerCase());
  }

  /// Get text direction for current language  
  static ui.TextDirection getTextDirection() {
    final bool isRightToLeft = isRTL(_currentLanguage.code);
    // Use dart:ui TextDirection to avoid conflict with intl package
    return isRightToLeft ? ui.TextDirection.rtl : ui.TextDirection.ltr;
  }
}

