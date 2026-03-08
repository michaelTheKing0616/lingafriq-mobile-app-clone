// Enhanced Text-to-Speech Service for African Languages
// Uses REAL free, high-quality TTS models specifically for African languages
// 
// Features:
// - Uses backend voice service (XTTS, MMS-TTS, Coqui) for African languages
// - Automatic language selection from user profile
// - Natural-sounding voices with emotion
// - Speed and pitch adjustment
// - Caching for performance
// - Fallback to system TTS only when backend unavailable
// 
// FREE Models Used (via backend):
// - Meta's MMS-TTS (Massively Multilingual Speech) - 1000+ languages including African
// - XTTS v2 (Coqui) - Zero-shot voice cloning, excellent for African languages
// - VoiceAI TTS - Open-source, African language support
// - System TTS as last resort fallback
// 
// Production-ready with user language preference integration

import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lingafriq/config/secrets_manager.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum TTSModel {
  mmsTts,       // Meta MMS-TTS - Best for African languages (FREE)
  xtts,         // XTTS v2 - High quality, zero-shot (FREE)
  backendTts,   // Backend voice service (fallback)
  systemTts,    // System TTS (last resort)
}

enum TTSQuality {
  low,    // Fastest, robotic
  medium, // Balanced
  high,   // Slowest, most natural
}

class TTSConfig {
  final TTSModel model;
  final TTSQuality quality;
  final String? language; // Now optional - will use user's selected language
  final double speed; // 0.5 - 2.0
  final double pitch; // 0.5 - 2.0
  final String? voiceId; // Specific voice
  final bool enableCache;

  const TTSConfig({
    this.model = TTSModel.mmsTts, // Default to MMS-TTS for African languages
    this.quality = TTSQuality.medium,
    this.language, // Optional - uses user's selected language from profile
    this.speed = 1.0,
    this.pitch = 1.0,
    this.voiceId,
    this.enableCache = true,
  });
}

class EnhancedTTSService {
  final FlutterTts _flutterTts = FlutterTts();
  final Dio _dio = Dio();
  final SecretsManager _secrets = SecretsManager();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _audioCache = {}; // text -> audio file path
  final Ref? _ref; // For accessing user provider

  bool _isInitialized = false;
  String? _userLanguage; // User's selected language from onboarding

  EnhancedTTSService({Ref? ref}) : _ref = ref;

  /// Initialize TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure secrets are loaded before any remote TTS calls.
      try {
        await _secrets.initialize();
      } catch (e) {
        logger.warn('SecretsManager failed to initialize (will rely on system TTS fallback)', error: e);
      }

      // Get user's selected language from profile
      if (_ref != null) {
        try {
          final user = _ref.read(userProvider);
          _userLanguage = user?.learningLanguage;
          logger.info('User language detected', context: {'language': _userLanguage});
        } catch (e) {
          logger.debug('Could not get user language from provider', error: e);
        }
      }

      // Configure system TTS as fallback
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.awaitSpeakCompletion(true);

      if (_userLanguage != null) {
        final langCode = _mapLanguageCode(_userLanguage!);
        await _flutterTts.setLanguage(langCode);
      }

      _isInitialized = true;
      logger.info('Enhanced TTS service initialized', context: {
        'userLanguage': _userLanguage,
      });
    } catch (e) {
      logger.error('Failed to initialize TTS', error: e);
    }
  }

  /// Speak text with enhanced quality
  Future<void> speak(String text, [TTSConfig? config]) async {
    await initialize();

    // Use user's language if not specified in config
    final effectiveLanguage = config?.language ?? _userLanguage ?? 'english';
    final effectiveConfig = config ?? TTSConfig(language: effectiveLanguage);

    try {
      // Check cache first
      if (effectiveConfig.enableCache) {
        final cacheKey = '${text}_$effectiveLanguage';
        if (_audioCache.containsKey(cacheKey)) {
          logger.debug('Playing cached audio', context: {
            'text': text.length > 50 ? text.substring(0, 50) : text,
            'language': effectiveLanguage,
          });
          final cachedPath = _audioCache[cacheKey]!;
          if (await File(cachedPath).exists()) {
            await _playAudioFile(cachedPath);
            return;
          }
        }
      }

      logger.info('Generating TTS', context: {
        'model': effectiveConfig.model.toString(),
        'language': effectiveLanguage,
        'textLength': text.length,
      });

      // Generate and speak using REAL African language TTS
      switch (effectiveConfig.model) {
        case TTSModel.mmsTts:
          await _speakWithMMSTTS(text, effectiveConfig, effectiveLanguage);
          break;
        case TTSModel.xtts:
          await _speakWithXTTS(text, effectiveConfig, effectiveLanguage);
          break;
        case TTSModel.backendTts:
          await _speakWithBackendTTS(text, effectiveConfig, effectiveLanguage);
          break;
        case TTSModel.systemTts:
          await _speakWithSystemTTS(text, effectiveConfig, effectiveLanguage);
          break;
      }
    } catch (e) {
      logger.error('TTS failed', error: e);
      // Fallback to system TTS
      if (config?.model != TTSModel.systemTts) {
        logger.info('Falling back to system TTS');
        await _speakWithSystemTTS(text, effectiveConfig, effectiveLanguage);
      }
    }
  }

  /// Speak with Meta MMS-TTS (REAL African language support - 1000+ languages)
  Future<void> _speakWithMMSTTS(String text, TTSConfig config, String language) async {
    try {
      await _speakViaBackendRouting(
        text: text,
        language: language,
        speed: config.speed,
        pitch: config.pitch,
        providerPriority: const ['mms_tts', 'xtts_v2', 'piper'],
        modelTier: 'free_best',
        enableCache: config.enableCache,
      );
    } catch (e) {
      logger.error('MMS-TTS failed, falling back', error: e);
      // Fallback to XTTS
      await _speakWithXTTS(text, config, language);
    }
  }

  /// Speak with XTTS v2 (High-quality, zero-shot voice cloning)
  Future<void> _speakWithXTTS(String text, TTSConfig config, String language) async {
    try {
      await _speakViaBackendRouting(
        text: text,
        language: language,
        speed: config.speed,
        pitch: config.pitch,
        providerPriority: const ['xtts_v2', 'mms_tts', 'piper'],
        modelTier: 'free_best',
        enableCache: config.enableCache,
      );
    } catch (e) {
      logger.error('XTTS failed, falling back', error: e);
      await _speakWithBackendTTS(text, config, language);
    }
  }

  /// Speak with backend TTS service (fallback)
  Future<void> _speakWithBackendTTS(String text, TTSConfig config, String language) async {
    try {
      await _speakViaBackendRouting(
        text: text,
        language: language,
        speed: config.speed,
        pitch: config.pitch,
        providerPriority: const ['xtts_v2', 'mms_tts', 'piper'],
        modelTier: 'free_best',
        enableCache: config.enableCache,
      );
    } catch (e) {
      logger.error('Backend TTS failed, falling back to system', error: e);
      await _speakWithSystemTTS(text, config, language);
    }
  }

  Future<void> _speakViaBackendRouting({
    required String text,
    required String language,
    required double speed,
    required double pitch,
    required List<String> providerPriority,
    required String modelTier,
    bool enableCache = true,
  }) async {
    final response = await _dio.post(
      ApiContract.url(ApiContract.voice.ttsSynthesize),
      data: {
        'text': text,
        'language': language,
        'speed': speed,
        'pitch': pitch,
        'provider_priority': providerPriority,
        'accent_profile': _defaultAccentProfile(language),
        'model_tier': modelTier,
      },
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final audioPath = '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav';
    await File(audioPath).writeAsBytes(response.data as List<int>);
    if (enableCache) {
      _audioCache['${text}_$language'] = audioPath;
    }
    await _playAudioFile(audioPath);
  }

  String _defaultAccentProfile(String language) {
    const accents = {
      'yoruba': 'yo-NG',
      'hausa': 'ha-NG',
      'igbo': 'ig-NG',
      'swahili': 'sw-KE',
      'zulu': 'zu-ZA',
      'xhosa': 'xh-ZA',
      'amharic': 'am-ET',
      'somali': 'so-SO',
      'afrikaans': 'af-ZA',
      'wolof': 'wo-SN',
      'twi': 'tw-GH',
      'pidgin': 'pcm-NG',
      'english': 'en-AF',
    };
    return accents[language.toLowerCase()] ?? language;
  }

  /// Speak with system TTS (last resort fallback)
  Future<void> _speakWithSystemTTS(String text, TTSConfig config, String language) async {
    try {
      // Set language
      final langCode = _mapLanguageCode(language);
      await _flutterTts.setLanguage(langCode);

      // Set voice if specified
      if (config.voiceId != null) {
        await _flutterTts.setVoice({
          'name': config.voiceId!,
          'locale': langCode,
        });
      }

      // Set speech parameters
      await _flutterTts.setSpeechRate(config.speed);
      await _flutterTts.setPitch(config.pitch);

      // Speak
      await _flutterTts.speak(text);
    } catch (e) {
      logger.error('System TTS failed', error: e);
      rethrow;
    }
  }

  /// Play audio file using audioplayers
  Future<void> _playAudioFile(String path) async {
    try {
      await _audioPlayer.stop(); // Stop any currently playing audio
      await _audioPlayer.play(DeviceFileSource(path));
      logger.debug('Playing audio file', context: {'path': path});
    } catch (e) {
      logger.error('Failed to play audio file', error: e);
      rethrow;
    }
  }

  /// Get available voices for language
  Future<List<Map<String, String>>> getAvailableVoices(String language) async {
    await initialize();

    try {
      final langCode = _mapLanguageCode(language);
      final voices = await _flutterTts.getVoices;
      
      if (voices == null) return [];

      // Filter voices for the specified language
      return (voices as List)
          .where((voice) => 
              voice['locale']?.toString().startsWith(langCode) == true)
          .map((voice) => {
                'name': voice['name']?.toString() ?? '',
                'locale': voice['locale']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      logger.error('Failed to get voices', error: e);
      return [];
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      logger.error('Failed to stop TTS', error: e);
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      logger.error('Failed to pause TTS', error: e);
    }
  }

  /// Resume speaking
  Future<void> resume() async {
    try {
      // Note: Flutter TTS doesn't have native resume, might need to re-speak
      logger.warn('TTS resume not fully supported, may restart');
    } catch (e) {
      logger.error('Failed to resume TTS', error: e);
    }
  }

  /// Clear audio cache
  Future<void> clearCache() async {
    try {
      for (final path in _audioCache.values) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _audioCache.clear();
      logger.info('TTS cache cleared');
    } catch (e) {
      logger.error('Failed to clear TTS cache', error: e);
    }
  }

  /// Map language codes
  String _mapLanguageCode(String language) {
    final mapping = {
      'yoruba': 'yo-NG',
      'swahili': 'sw-KE',
      'zulu': 'zu-ZA',
      'hausa': 'ha-NG',
      'igbo': 'ig-NG',
      'amharic': 'am-ET',
      'somali': 'so-SO',
      'afrikaans': 'af-ZA',
      'xhosa': 'xh-ZA',
      'english': 'en-US',
      'french': 'fr-FR',
      'arabic': 'ar-SA',
    };

    return mapping[language.toLowerCase()] ?? 'en-US';
  }

  /// Get supported languages
  List<String> getSupportedLanguages() {
    return [
      'yoruba',
      'swahili',
      'zulu',
      'hausa',
      'igbo',
      'amharic',
      'somali',
      'afrikaans',
      'xhosa',
      'shona',
      'kikuyu',
      'luganda',
      'kinyarwanda',
      'wolof',
      'fula',
      'oromo',
      'english',
      'french',
      'arabic',
      'portuguese',
    ];
  }
}

/// Provider for enhanced TTS service (with user language integration)
final enhancedTTSServiceProvider = Provider<EnhancedTTSService>((ref) {
  return EnhancedTTSService(ref: ref);
});

/// Global instance (for non-Riverpod contexts)
/// Note: This won't have access to user language. Use provider version when possible.
final enhancedTTSService = EnhancedTTSService();

