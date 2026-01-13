import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/voice_service_client.dart';
import 'base_provider.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

/// TTS Provider with intelligent language-based routing
/// Uses voice service API to route to appropriate MMS-TTS models for authentic African language pronunciation
class TTSProvider extends BaseProvider {
  final VoiceServiceClient _voiceClient = VoiceServiceClient();
  String? _currentLanguage;

  /// Initialize TTS provider
  Future<void> init() async {
    // Voice service client is ready to use
    // No platform-specific setup needed
  }

  /// Speak text with intelligent language routing
  /// 
  /// Automatically routes to appropriate MMS-TTS model based on language:
  /// - Yoruba → facebook/mms-tts-yor
  /// - Igbo → facebook/mms-tts-ibo
  /// - Swahili → facebook/mms-tts-swc
  /// - And other African languages...
  /// 
  /// [word] - Text to speak
  /// [languageName] - Language name or code (e.g., "yoruba", "igbo", "swahili")
  ///                  If null, uses current language or defaults to English
  Future<void> speak(String word, {String? languageName}) async {
    if (word.isEmpty) return;
    
    try {
      // Use provided language or current language or default to English
      final language = languageName ?? _currentLanguage ?? 'english';
      _currentLanguage = language;
      
      await _voiceClient.stop();
      await _voiceClient.synthesize(
        text: word,
        language: language,
        onComplete: () {
          debugPrint('TTS playback completed for: $word ($language)');
        },
        onError: (error) {
          debugPrint('TTS error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error in TTS speak: $e');
      rethrow;
    }
  }

  /// Set default language for subsequent speak calls
  void setLanguage(String language) {
    _currentLanguage = language.toLowerCase();
  }

  /// Stop current speech playback
  Future<void> stop() async {
    try {
      await _voiceClient.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  /// Check if currently playing
  bool get isPlaying => _voiceClient.isPlaying;

  @override
  void dispose() {
    _voiceClient.dispose();
  }
}
