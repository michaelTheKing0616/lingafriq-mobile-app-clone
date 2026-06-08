// Enhanced Text-to-Speech Service for African Languages
//
// Thin facade that preserves the historical public API surface used by
// persona-aware controllers, while delegating all synthesis and playback to
// the unified [AfricanTtsService] (gold/silver/bronze resolver: CDN → MMS-TTS
// → XTTS-v2 → on-device fallback inside AfricanTtsService).
//
// This file intentionally does **not** import flutter_tts. The on-device
// fallback path is owned exclusively by AfricanTtsService and is enforced by
// tool/tts_purity_gate.dart in CI.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

enum TTSModel {
  mmsTts,
  xtts,
  backendTts,
  systemTts,
}

enum TTSQuality {
  low,
  medium,
  high,
}

class TTSConfig {
  final TTSModel model;
  final TTSQuality quality;
  final String? language;
  final double speed;
  final double pitch;
  final String? voiceId;
  final bool enableCache;

  const TTSConfig({
    this.model = TTSModel.mmsTts,
    this.quality = TTSQuality.medium,
    this.language,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.voiceId,
    this.enableCache = true,
  });
}

class EnhancedTTSService {
  EnhancedTTSService({Ref? ref}) : _ref = ref;

  final Ref? _ref;
  final AfricanTtsService _african = AfricanTtsService();

  bool _isInitialized = false;
  String? _userLanguage;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_ref != null) {
      try {
        final user = _ref.read(userProvider);
        _userLanguage = user?.learningLanguage;
      } catch (e) {
        logger.debug('Could not get user language from provider', error: e);
      }
    }
    _isInitialized = true;
    logger.info('Enhanced TTS facade initialized', context: {
      'userLanguage': _userLanguage,
      'backend': 'AfricanTtsService',
    });
  }

  Future<void> speak(String text, [TTSConfig? config]) async {
    await initialize();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final effectiveLanguage = config?.language ?? _userLanguage ?? 'English';
    final cfg = config ?? const TTSConfig();

    try {
      await _african.speak(
        language: effectiveLanguage,
        text: trimmed,
        speed: cfg.speed.clamp(0.5, 2.0).toDouble(),
      );
    } catch (e) {
      logger.error('AfricanTtsService.speak failed', error: e, context: {
        'language': effectiveLanguage,
        'textLength': trimmed.length,
      });
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _african.stop();
    } catch (e) {
      logger.error('Failed to stop TTS', error: e);
    }
  }

  Future<void> pause() async {
    // AudioPlayer.pause is intentionally not exposed; stop is the supported
    // interrupt primitive. Surface as no-op to preserve callers.
  }

  Future<void> resume() async {
    // No-op: pause is not implemented in the underlying pipeline.
  }

  /// Returns the curated set of accent-aware language ids supported by the
  /// African TTS resolver. The historical `Map<String, String>` voice shape
  /// is preserved (name + locale).
  Future<List<Map<String, String>>> getAvailableVoices(String language) async {
    final mapping = _bcp47Map();
    final code = mapping[language.toLowerCase()];
    if (code == null) return const [];
    return [
      {
        'name': 'African Accent · $language',
        'locale': code,
      },
    ];
  }

  Future<void> clearCache() async {
    // Cache eviction is governed by AfricanTtsService telemetry/runbook; the
    // facade does not expose a destructive clear to callers to prevent
    // accidental cache wipes during a learning session.
  }

  List<String> getSupportedLanguages() => _bcp47Map().keys.toList()..sort();

  Map<String, String> _bcp47Map() => const {
        'yoruba': 'yo-NG',
        'hausa': 'ha-NG',
        'igbo': 'ig-NG',
        'pidgin': 'pcm-NG',
        'swahili': 'sw-KE',
        'zulu': 'zu-ZA',
        'xhosa': 'xh-ZA',
        'amharic': 'am-ET',
        'somali': 'so-SO',
        'afrikaans': 'af-ZA',
        'wolof': 'wo-SN',
        'twi': 'tw-GH',
        'lingala': 'ln-CD',
        'shona': 'sn-ZW',
        'kikuyu': 'ki-KE',
        'luganda': 'lg-UG',
        'kinyarwanda': 'rw-RW',
        'fula': 'ff-SN',
        'oromo': 'om-ET',
        'english': 'en-NG',
        'french': 'fr-FR',
        'arabic': 'ar-SA',
        'portuguese': 'pt-PT',
      };
}

final enhancedTTSServiceProvider = Provider<EnhancedTTSService>((ref) {
  return EnhancedTTSService(ref: ref);
});

final enhancedTTSService = EnhancedTTSService();
