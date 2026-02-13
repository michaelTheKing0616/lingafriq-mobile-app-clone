import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../providers/onboarding_provider.dart';
import 'hybrid_polie/translation_service.dart';

/// Lightweight localization service that uses the existing Hybrid Polie
/// TranslationService to translate UI copy into the learner's interface
/// language. English remains the default/fallback.
/// 
/// Translation Strategy (Priority Order):
/// 1. In-memory cache (instant, session-scoped)
/// 2. Persistent cache (SharedPreferences, survives app restart)
/// 3. AI Translation via Polie (NLLB-200, most accurate for African languages)
/// 4. Static ARB fallback (pre-translated common strings)
/// 5. English fallback (always available)
final localizationProvider = Provider<LocalizationService>((ref) {
  final onboarding = ref.watch(onboardingProvider);
  final selectedLang = (onboarding.selectedLanguage ?? 'english').toLowerCase();
  return LocalizationService(interfaceLanguage: selectedLang);
});

/// Static ARB-based translations for common UI strings
/// These serve as a reliable fallback when AI translation is unavailable
class ArbFallbackTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'sw': { // Swahili
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'Karibu LingAfriq!',
      'continueButton': 'Endelea',
      'home': 'Nyumbani',
      'learn': 'Jifunze',
      'games': 'Michezo',
      'profile': 'Wasifu',
      'settings': 'Mipangilio',
      'language': 'Lugha',
      'lessons': 'Masomo',
      'quizzes': 'Maswali',
      'login': 'Ingia',
      'signup': 'Jisajili',
      'email': 'Barua pepe',
      'password': 'Nenosiri',
      'congratulations': 'Hongera!',
      'level': 'Kiwango',
      'beginner': 'Mwanzo',
      'intermediate': 'Kati',
      'advanced': 'Juu',
      'loading': 'Inapakia...',
      'error': 'Hitilafu',
      'retry': 'Jaribu tena',
      'cancel': 'Ghairi',
      'save': 'Hifadhi',
      'next': 'Ifuatayo',
      'back': 'Nyuma',
      'skip': 'Ruka',
      'done': 'Imekamilika',
      'search': 'Tafuta',
      'notifications': 'Arifa',
      'darkMode': 'Hali ya Giza',
      'logout': 'Ondoka',
    },
    'yo': { // Yoruba
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'Ẹ káàbọ̀ sí LingAfriq!',
      'continueButton': 'Tẹ̀síwájú',
      'home': 'Ilé',
      'learn': 'Kọ́',
      'games': 'Eré',
      'profile': 'Àkọsílẹ̀',
      'settings': 'Ètò',
      'language': 'Èdè',
      'lessons': 'Ẹ̀kọ́',
      'quizzes': 'Ìdánwò',
      'login': 'Wọlé',
      'signup': 'Forúkọsílẹ̀',
      'email': 'Ímeèlì',
      'password': 'Ọ̀rọ̀ aṣínà',
      'congratulations': 'Kú oríire!',
      'level': 'Ìpele',
      'beginner': 'Àkọ́kọ́',
      'intermediate': 'Àárín',
      'advanced': 'Gíga',
      'loading': 'Ń gbé rù...',
      'error': 'Àṣìṣe',
      'retry': 'Gbìyànjú lẹ́ẹ̀kan sí',
      'cancel': 'Fagilé',
      'save': 'Pamọ́',
      'next': 'Tó kàn',
      'back': 'Padà',
      'skip': 'Fò',
      'done': 'Parí',
      'search': 'Wá',
      'notifications': 'Ìfitónilétí',
      'darkMode': 'Ọ̀nà Òkùnkùn',
      'logout': 'Jáde',
    },
    'ha': { // Hausa
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'Barka da zuwa LingAfriq!',
      'continueButton': 'Ci gaba',
      'home': 'Gida',
      'learn': 'Koyi',
      'games': 'Wasanni',
      'profile': 'Bayani',
      'settings': 'Saituna',
      'language': 'Harshe',
      'lessons': 'Darasi',
      'quizzes': 'Jarrabawa',
      'login': 'Shiga',
      'signup': 'Yi rajista',
      'email': 'Imel',
      'password': 'Kalmar sirri',
      'congratulations': 'Taya murna!',
      'level': 'Matsayi',
      'beginner': 'Farko',
      'intermediate': 'Tsakiya',
      'advanced': 'Ci gaba',
      'loading': 'Ana lodawa...',
      'error': 'Kuskure',
      'retry': 'Sake gwadawa',
      'cancel': 'Soke',
      'save': 'Ajiye',
      'next': 'Na gaba',
      'back': 'Baya',
      'skip': 'Tsallake',
      'done': 'An gama',
      'search': 'Bincika',
      'notifications': 'Sanarwa',
      'darkMode': 'Yanayin Duhu',
      'logout': 'Fita',
    },
    'am': { // Amharic
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'እንኳን ደህና መጡ!',
      'continueButton': 'ቀጥል',
      'home': 'መነሻ',
      'learn': 'ተማር',
      'games': 'ጨዋታዎች',
      'profile': 'መገለጫ',
      'settings': 'ቅንብሮች',
      'language': 'ቋንቋ',
      'lessons': 'ትምህርቶች',
      'quizzes': 'ጥያቄዎች',
      'login': 'ግባ',
      'signup': 'ተመዝገብ',
      'email': 'ኢሜይል',
      'password': 'የይለፍ ቃል',
      'congratulations': 'እንኳን ደስ አለህ!',
      'level': 'ደረጃ',
      'beginner': 'ጀማሪ',
      'intermediate': 'መካከለኛ',
      'advanced': 'የላቀ',
      'loading': 'በመጫን ላይ...',
      'error': 'ስህተት',
      'retry': 'እንደገና ሞክር',
      'cancel': 'ሰርዝ',
      'save': 'አስቀምጥ',
      'next': 'ቀጣይ',
      'back': 'ተመለስ',
      'skip': 'ዝለል',
      'done': 'ተጠናቋል',
      'search': 'ፈልግ',
      'notifications': 'ማሳወቂያዎች',
      'darkMode': 'ጨለማ ሁነታ',
      'logout': 'ውጣ',
    },
    'fr': { // French (for Francophone Africa)
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'Bienvenue sur LingAfriq!',
      'continueButton': 'Continuer',
      'home': 'Accueil',
      'learn': 'Apprendre',
      'games': 'Jeux',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'language': 'Langue',
      'lessons': 'Leçons',
      'quizzes': 'Quiz',
      'login': 'Connexion',
      'signup': 'Inscription',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'congratulations': 'Félicitations!',
      'level': 'Niveau',
      'beginner': 'Débutant',
      'intermediate': 'Intermédiaire',
      'advanced': 'Avancé',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'next': 'Suivant',
      'back': 'Retour',
      'skip': 'Passer',
      'done': 'Terminé',
      'search': 'Rechercher',
      'notifications': 'Notifications',
      'darkMode': 'Mode sombre',
      'logout': 'Déconnexion',
    },
    'zu': { // Zulu
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'Siyakwamukela ku-LingAfriq!',
      'continueButton': 'Qhubeka',
      'home': 'Ikhaya',
      'learn': 'Funda',
      'games': 'Imidlalo',
      'profile': 'Iphrofayili',
      'settings': 'Izilungiselelo',
      'language': 'Ulimi',
      'lessons': 'Izifundo',
      'quizzes': 'Imibuzo',
      'login': 'Ngena',
      'signup': 'Bhalisa',
      'email': 'I-imeyili',
      'password': 'Iphasiwedi',
      'congratulations': 'Halala!',
      'level': 'Izinga',
      'beginner': 'Oqalayo',
      'intermediate': 'Ophakathi',
      'advanced': 'Ophezulu',
      'loading': 'Iyalayisha...',
      'error': 'Iphutha',
      'retry': 'Zama futhi',
      'cancel': 'Khansela',
      'save': 'Londoloza',
      'next': 'Okulandelayo',
      'back': 'Emuva',
      'skip': 'Yeqa',
      'done': 'Kwenziwe',
      'search': 'Sesha',
      'notifications': 'Izaziso',
      'darkMode': 'Imodi emnyama',
      'logout': 'Phuma',
    },
    'ig': { // Igbo
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'Nnọọ na LingAfriq!',
      'continueButton': 'Gaa n\'ihu',
      'home': 'Ụlọ',
      'learn': 'Mụta',
      'games': 'Egwuregwu',
      'profile': 'Profaịlụ',
      'settings': 'Ntọala',
      'language': 'Asụsụ',
      'lessons': 'Ihe ọmụmụ',
      'quizzes': 'Ajụjụ',
      'login': 'Banye',
      'signup': 'Debanye aha',
      'email': 'Email',
      'password': 'Okwuntụghe',
      'congratulations': 'Ekele!',
      'level': 'Ọkwa',
      'beginner': 'Mbido',
      'intermediate': 'Etiti',
      'advanced': 'Nke ukwuu',
      'loading': 'Na-ebugo...',
      'error': 'Njehie',
      'retry': 'Nwaa ọzọ',
      'cancel': 'Kagbuo',
      'save': 'Chekwaa',
      'next': 'Ọzọ',
      'back': 'Azụ',
      'skip': 'Wụfee',
      'done': 'Emechara',
      'search': 'Chọọ',
      'notifications': 'Ọkwa',
      'darkMode': 'Ọnọdụ gbara ọchịchịrị',
      'logout': 'Pụọ',
    },
    'pcm': { // Nigerian Pidgin English
      'appTitle': 'LingAfriq',
      'welcomeMessage': 'You don land for LingAfriq!',
      'continueButton': 'Continue',
      'home': 'Home',
      'learn': 'Learn',
      'games': 'Games',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'lessons': 'Lessons',
      'quizzes': 'Quiz',
      'login': 'Enter',
      'signup': 'Register',
      'email': 'Email',
      'password': 'Password',
      'congratulations': 'Well done!',
      'level': 'Level',
      'beginner': 'JJC',
      'intermediate': 'Middle',
      'advanced': 'Boss Level',
      'loading': 'E dey load...',
      'error': 'Wahala',
      'retry': 'Try again',
      'cancel': 'Cancel',
      'save': 'Save am',
      'next': 'Next one',
      'back': 'Go back',
      'skip': 'Skip am',
      'done': 'Done',
      'search': 'Search',
      'notifications': 'Notifications',
      'darkMode': 'Dark Mode',
      'logout': 'Comot',
    },
  };

  /// Get ARB fallback translation for a key
  static String? get(String languageCode, String key) {
    final langTranslations = _translations[languageCode];
    return langTranslations?[key];
  }

  /// Check if a language has ARB fallback support
  static bool hasLanguage(String languageCode) {
    return _translations.containsKey(languageCode);
  }

  /// Get all supported ARB fallback languages
  static List<String> get supportedLanguages => _translations.keys.toList();
}

class LocalizationService {
  final String interfaceLanguage;
  final TranslationService _translationService = TranslationService();
  
  // In-memory cache (session-scoped, fastest)
  final Map<String, String> _memoryCache = {};
  
  // Persistent cache key prefix
  static const String _cachePrefix = 'ai_translation_cache_';
  
  // Flag to track if common strings have been pre-translated
  static bool _hasPreTranslated = false;

  LocalizationService({required this.interfaceLanguage});

  /// Common UI strings that should be pre-translated at app startup
  static const List<Map<String, String>> _commonStrings = [
    {'key': 'appTitle', 'english': 'LingAfriq'},
    {'key': 'welcomeMessage', 'english': 'Welcome to LingAfriq!'},
    {'key': 'continueButton', 'english': 'Continue'},
    {'key': 'home', 'english': 'Home'},
    {'key': 'learn', 'english': 'Learn'},
    {'key': 'games', 'english': 'Games'},
    {'key': 'profile', 'english': 'Profile'},
    {'key': 'settings', 'english': 'Settings'},
    {'key': 'language', 'english': 'Language'},
    {'key': 'lessons', 'english': 'Lessons'},
    {'key': 'quizzes', 'english': 'Quizzes'},
    {'key': 'login', 'english': 'Login'},
    {'key': 'signup', 'english': 'Sign Up'},
    {'key': 'email', 'english': 'Email'},
    {'key': 'password', 'english': 'Password'},
    {'key': 'congratulations', 'english': 'Congratulations!'},
    {'key': 'level', 'english': 'Level'},
    {'key': 'beginner', 'english': 'Beginner'},
    {'key': 'intermediate', 'english': 'Intermediate'},
    {'key': 'advanced', 'english': 'Advanced'},
    {'key': 'loading', 'english': 'Loading...'},
    {'key': 'error', 'english': 'Error'},
    {'key': 'retry', 'english': 'Retry'},
    {'key': 'cancel', 'english': 'Cancel'},
    {'key': 'save', 'english': 'Save'},
    {'key': 'next', 'english': 'Next'},
    {'key': 'back', 'english': 'Back'},
    {'key': 'skip', 'english': 'Skip'},
    {'key': 'done', 'english': 'Done'},
    {'key': 'search', 'english': 'Search'},
    {'key': 'notifications', 'english': 'Notifications'},
    {'key': 'darkMode', 'english': 'Dark Mode'},
    {'key': 'logout', 'english': 'Logout'},
  ];

  /// Pre-translate common UI strings at app startup
  /// Call this once when the app initializes and language is known
  Future<void> preTranslateCommonStrings() async {
    if (_hasPreTranslated) return;
    if (_isEnglish(interfaceLanguage)) {
      _hasPreTranslated = true;
      return;
    }

    // Load persistent cache first
    await _loadPersistentCache();

    // Pre-translate any strings not in cache
    final futures = <Future>[];
    for (final item in _commonStrings) {
      final key = item['key']!;
      final english = item['english']!;
      final cacheKey = '$interfaceLanguage::$key';
      
      if (!_memoryCache.containsKey(cacheKey)) {
        futures.add(_translateAndCache(key, english));
      }
    }

    // Wait for all translations (with timeout to not block app startup)
    try {
      await Future.wait(futures).timeout(
        const Duration(seconds: 10),
        onTimeout: () => [], // Continue without waiting if it takes too long
      );
    } catch (e) {
      // Log but don't fail - app will use fallbacks
    }

    _hasPreTranslated = true;
  }

  /// Load persistent cache from SharedPreferences
  Future<void> _loadPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString('$_cachePrefix$interfaceLanguage');
      if (cacheJson != null) {
        final Map<String, dynamic> cached = json.decode(cacheJson);
        cached.forEach((key, value) {
          _memoryCache['$interfaceLanguage::$key'] = value.toString();
        });
      }
    } catch (e) {
      // Ignore cache load errors
    }
  }

  /// Save memory cache to persistent storage
  Future<void> _savePersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> toSave = {};
      _memoryCache.forEach((cacheKey, value) {
        if (cacheKey.startsWith('$interfaceLanguage::')) {
          final key = cacheKey.replaceFirst('$interfaceLanguage::', '');
          toSave[key] = value;
        }
      });
      await prefs.setString('$_cachePrefix$interfaceLanguage', json.encode(toSave));
    } catch (e) {
      // Ignore cache save errors
    }
  }

  /// Translate and cache a string
  Future<String> _translateAndCache(String key, String english) async {
    final cacheKey = '$interfaceLanguage::$key';
    
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // Try AI translation
    try {
      final result = await _translationService.translate(
        text: english,
        sourceLang: 'english',
        targetLang: interfaceLanguage,
      );
      
      if (result.translation.isNotEmpty && result.translation != english) {
        _memoryCache[cacheKey] = result.translation;
        // Save to persistent cache in background
        _savePersistentCache();
        return result.translation;
      }
    } catch (e) {
      // AI translation failed, try ARB fallback
    }

    // Try ARB fallback
    final arbTranslation = ArbFallbackTranslations.get(interfaceLanguage, key);
    if (arbTranslation != null) {
      _memoryCache[cacheKey] = arbTranslation;
      return arbTranslation;
    }

    // Final fallback: English
    return english;
  }

  bool _isEnglish(String lang) {
    final normalized = lang.toLowerCase();
    return normalized.isEmpty ||
        normalized == 'english' ||
        normalized == 'en' ||
        normalized == 'eng';
  }

  /// Translate an English string into the interface language.
  /// Uses tiered strategy: memory cache → persistent cache → AI → ARB → English
  /// 
  /// For synchronous UI rendering, use [tSync] which returns immediately with
  /// cached value or English fallback, then triggers background translation.
  Future<String> t({
    required String key,
    required String english,
  }) async {
    final target = interfaceLanguage;

    // If interface language is English (or not set), just return the base text.
    if (_isEnglish(target)) {
      return english;
    }

    return _translateAndCache(key, english);
  }

  /// Synchronous translation for immediate UI rendering.
  /// Returns cached translation instantly if available, otherwise returns English
  /// and triggers background AI translation for future use.
  /// 
  /// Use this when you need a string immediately for widget rendering.
  String tSync({
    required String key,
    required String english,
  }) {
    final target = interfaceLanguage;

    // If interface language is English (or not set), just return the base text.
    if (_isEnglish(target)) {
      return english;
    }

    final cacheKey = '$target::$key';
    
    // Check memory cache (instant)
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // Check ARB fallback (instant)
    final arbTranslation = ArbFallbackTranslations.get(target, key);
    if (arbTranslation != null) {
      _memoryCache[cacheKey] = arbTranslation;
      return arbTranslation;
    }

    // No cache hit - trigger background translation for next time
    _translateAndCache(key, english);

    // Return English for now
    return english;
  }

  /// Get translation confidence level
  /// Returns 'ai' for AI-translated, 'arb' for ARB fallback, 'english' for fallback
  String getTranslationSource(String key) {
    final cacheKey = '$interfaceLanguage::$key';
    
    if (_memoryCache.containsKey(cacheKey)) {
      // Check if it's an ARB translation
      final arbTranslation = ArbFallbackTranslations.get(interfaceLanguage, key);
      if (arbTranslation != null && _memoryCache[cacheKey] == arbTranslation) {
        return 'arb';
      }
      return 'ai';
    }
    return 'english';
  }

  /// Clear all translation caches (useful for language change)
  Future<void> clearCache() async {
    _memoryCache.clear();
    _hasPreTranslated = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$interfaceLanguage');
    } catch (e) {
      // Ignore
    }
  }

  /// Check if a language is supported for translation
  /// ARB fallback provides reliable translations for common strings
  /// AI (NLLB-200) supports 200+ languages including most African languages
  bool isLanguageSupported(String languageCode) {
    // ARB fallback has limited but reliable support for common UI strings
    if (ArbFallbackTranslations.hasLanguage(languageCode)) {
      return true;
    }
    
    // AI translation (NLLB-200) supports these African languages
    const aiSupportedLanguages = [
      'sw', 'swahili',      // Swahili
      'yo', 'yoruba',       // Yoruba
      'ha', 'hausa',        // Hausa
      'ig', 'igbo',         // Igbo
      'am', 'amharic',      // Amharic
      'zu', 'zulu',         // Zulu
      'xh', 'xhosa',        // Xhosa
      'af', 'afrikaans',    // Afrikaans
      'so', 'somali',       // Somali
      'ti', 'tigrinya',     // Tigrinya
      'om', 'oromo',        // Oromo
      'rw', 'kinyarwanda',  // Kinyarwanda
      'lg', 'luganda',      // Luganda
      'wo', 'wolof',        // Wolof
      'sn', 'shona',        // Shona
      'ny', 'chichewa',     // Chichewa
      'ln', 'lingala',      // Lingala
      'fr', 'french',       // French (Francophone Africa)
      'ar', 'arabic',       // Arabic (North Africa)
      'pt', 'portuguese',   // Portuguese (Lusophone Africa)
      'en', 'english',      // English
      'pcm', 'pidgin',      // Nigerian Pidgin
    ];
    
    return aiSupportedLanguages.contains(languageCode.toLowerCase());
  }
}

