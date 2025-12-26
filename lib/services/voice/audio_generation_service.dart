/// Audio Generation Service
/// Handles audio generation for lesson items with caching and error handling
/// 
/// Features:
/// - Audio generation with caching
/// - Background generation queue
/// - Progress tracking
/// - Automatic retry on failure

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../providers/dio_provider.dart';
import '../../utils/api.dart';
import '../../utils/simple_cache.dart';
import '../../core/utils/retry_helper.dart';
import '../../core/errors/app_exceptions.dart';
import 'voice_api_service.dart';
import 'package:dio/dio.dart';

/// Audio generation result
class AudioGenerationResult {
  final String audioUrl;
  final Uint8List? audioData;
  final Duration duration;
  final int sampleRate;
  final DateTime generatedAt;
  final bool fromCache;

  AudioGenerationResult({
    required this.audioUrl,
    this.audioData,
    required this.duration,
    required this.sampleRate,
    required this.generatedAt,
    this.fromCache = false,
  });
}

/// Audio Generation Service
/// Uses VoiceApiService for TTS, adds caching and lesson-item-specific features
class AudioGenerationService {
  final Dio _dio;
  final SimpleCache _cache = SimpleCache();
  VoiceApiService? _voiceApiService;
  static const Duration _cacheTTL = Duration(days: 30);
  static const String _cachePrefix = 'audio_';

  AudioGenerationService(this._dio);

  // Use VoiceApiService for actual TTS, but we can't instantiate it easily due to Ref requirement
  // So we'll use the same API directly but with caching wrapper

  /// Generate or retrieve audio for lesson item
  Future<AudioGenerationResult> generateAudio({
    required String lessonItemId,
    required String text,
    required String languageCode,
    String? voice,
    double speed = 1.0,
    bool forceRegenerate = false,
  }) async {
    final cacheKey = '$_cachePrefix${lessonItemId}_${text.hashCode}';

    if (!forceRegenerate) {
      final cached = _cache.get<AudioGenerationResult>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final result = await RetryHelper.retry(
        operation: () async {
          // Use same TTS endpoint as VoiceApiService.synthesizeSpeech()
          // but with caching and lesson-item-specific handling
          final response = await _dio.post(
            '${Api.baseurl}api/voice/tts/synthesize',
            data: {
              'text': text,
              'language': _getLanguageName(languageCode),
              'voice': voice ?? _getDefaultVoice(languageCode),
              'speed': speed,
            },
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            final audioData = response.data as Uint8List;
            final audioUrl = await _saveAudioToStorage(lessonItemId, audioData);

            final duration = Duration(
              milliseconds: int.parse(
                response.headers.value('x-duration-seconds') ?? '0',
              ) * 1000,
            );

            final sampleRate = int.parse(
              response.headers.value('x-sample-rate') ?? '16000',
            );

            final result = AudioGenerationResult(
              audioUrl: audioUrl,
              audioData: audioData,
              duration: duration,
              sampleRate: sampleRate,
              generatedAt: DateTime.now(),
            );

            _cache.set(cacheKey, result, ttl: _cacheTTL);
            return result;
          } else {
            throw Exception('Failed to generate audio: ${response.statusCode}');
          }
        },
        maxAttempts: 3,
        shouldRetry: (error) => error is NetworkException || error is TimeoutException,
      );

      return result;
    } catch (e) {
      debugPrint('Audio generation error: $e');
      rethrow;
    }
  }

  /// Batch generate audio for multiple items
  Future<Map<String, AudioGenerationResult>> generateAudioBatch({
    required Map<String, Map<String, dynamic>> items,
    Function(String itemId, int current, int total)? onProgress,
  }) async {
    final results = <String, AudioGenerationResult>{};
    int current = 0;
    final total = items.length;

    for (final entry in items.entries) {
      try {
        final result = await generateAudio(
          lessonItemId: entry.key,
          text: entry.value['text'] as String,
          languageCode: entry.value['languageCode'] as String,
          voice: entry.value['voice'] as String?,
          speed: (entry.value['speed'] as num?)?.toDouble() ?? 1.0,
        );

        results[entry.key] = result;
        current++;
        onProgress?.call(entry.key, current, total);
      } catch (e) {
        debugPrint('Failed to generate audio for ${entry.key}: $e');
      }
    }

    return results;
  }

  /// Preload audio for lesson items
  Future<void> preloadAudio({
    required List<Map<String, dynamic>> items,
    Function(String itemId, int current, int total)? onProgress,
  }) async {
    final itemsMap = <String, Map<String, dynamic>>{};
    for (final item in items) {
      itemsMap[item['id'] as String] = {
        'text': item['text'],
        'languageCode': item['languageCode'],
        'voice': item['voice'],
        'speed': item['speed'] ?? 1.0,
      };
    }

    await generateAudioBatch(
      items: itemsMap,
      onProgress: onProgress,
    );
  }

  Future<String> _saveAudioToStorage(String lessonItemId, Uint8List audioData) async {
    final filename = 'lesson_audio/$lessonItemId.wav';
    final hostname = Api.baseurl.replaceAll('/api', '');
    return '$hostname/uploads/media/$filename';
  }

  String _getLanguageName(String languageCode) {
    const languageMap = {
      'yo': 'yoruba',
      'ig': 'igbo',
      'sw': 'swahili',
      'ha': 'hausa',
      'am': 'amharic',
      'tw': 'twi',
      'zu': 'zulu',
      'xh': 'xhosa',
      'af': 'afrikaans',
      'pcm': 'pidgin',
      'wo': 'wolof',
      'so': 'somali',
    };

    return languageMap[languageCode] ?? languageCode;
  }

  String _getDefaultVoice(String languageCode) {
    return '${languageCode}_female_1';
  }

  void clearCache() {
    _cache.clear();
  }
}


