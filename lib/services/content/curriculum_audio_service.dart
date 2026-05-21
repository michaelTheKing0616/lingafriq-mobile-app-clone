import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Resolves slow/native audio for curriculum and game vocabulary.
class CurriculumAudioService {
  static const _manifestPath = 'assets/data/audio_manifest.json';

  Map<String, dynamic>? _manifest;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.setVolume(1.0);
    _ttsReady = true;
  }

  Future<Map<String, dynamic>> _loadManifest() async {
    if (_manifest != null) return _manifest!;
    final raw = await rootBundle.loadString(_manifestPath);
    _manifest = jsonDecode(raw) as Map<String, dynamic>;
    return _manifest!;
  }

  Future<Map<String, dynamic>?> entryFor(String language, String text) async {
    final manifest = await _loadManifest();
    final entries = manifest['entries'] as List<dynamic>? ?? [];
    final lang = language.toLowerCase();
    for (final e in entries) {
      if (e is! Map) continue;
      if (e['language']?.toString().toLowerCase() == lang &&
          e['text']?.toString() == text) {
        return e.cast<String, dynamic>();
      }
    }
    return null;
  }

  /// Speaks [text] using bundled CDN path when recorded audio exists on device,
  /// otherwise TTS at slow or native rate from manifest.
  Future<void> speakPhrase({
    required String language,
    required String text,
    required bool slow,
  }) async {
    await _ensureTts();
    final entry = await entryFor(language, text);
    final variant = slow ? 'slow' : 'native';
    final block = entry?[variant] as Map<String, dynamic>?;
    final rate = (block?['tts_rate'] as num?)?.toDouble() ?? (slow ? 0.52 : 0.95);
    await _tts.setSpeechRate(rate);
    await _tts.setLanguage(_ttsLanguageCode(language));
    await _tts.speak(text);
  }

  String? nativeCdnUrl(String language, String text) {
    final entries = _manifest?['entries'] as List<dynamic>?;
    if (entries == null) return null;
    for (final e in entries) {
      if (e is Map &&
          e['language'] == language &&
          e['text'] == text) {
        return (e['native'] as Map?)?['cdn_url']?.toString();
      }
    }
    return null;
  }

  String _ttsLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case 'yoruba':
        return 'yo-NG';
      case 'hausa':
        return 'ha-NG';
      case 'igbo':
        return 'ig';
      case 'swahili':
        return 'sw-KE';
      case 'zulu':
        return 'zu-ZA';
      case 'xhosa':
        return 'xh-ZA';
      case 'wolof':
        return 'fr-FR'; // Wolof TTS fallback
      case 'pidgin':
      case 'nigerian_pidgin':
        return 'en-NG';
      default:
        return 'en-US';
    }
  }
}

final curriculumAudioServiceProvider = Provider<CurriculumAudioService>((ref) {
  return CurriculumAudioService();
});
