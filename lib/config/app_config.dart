import 'package:lingafriq/services/env_config.dart';

/// Application Configuration
/// Centralized configuration for API endpoints and app settings
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Backend base URL (same as EnvConfig)
  static String get backendBaseUrl => EnvConfig.backendBaseUrl;

  /// API base URL (same as backendBaseUrl for now)
  static String get apiBaseUrl => EnvConfig.backendBaseUrl;

  // Tutor API endpoints
  static const String tutorTranslate = 'tutor/translate';
  static const String tutorGrammar = 'tutor/grammar';
  static const String tutorStory = 'tutor/story';
  static const String tutorDialogue = 'tutor/dialogue';
  static const String tutorAssess = 'tutor/assess';
  static const String tutorPronounce = 'tutor/pronounce';

  // Culture Magazine endpoints
  static const String cultureMagazine = 'culture-magazine/';

  // UGC endpoints
  static const String ugcValidate = 'ugc/validate';

  // Media endpoints
  static const String media = 'media/';
}

