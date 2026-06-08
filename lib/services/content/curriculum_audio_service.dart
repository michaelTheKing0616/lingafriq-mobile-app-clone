import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingafriq/services/audio/african_tts_service.dart';

/// Resolves slow/native audio for curriculum and game vocabulary.
///
/// In v4 this service no longer talks to on-device flutter_tts directly. All
/// playback goes through [AfricanTtsService] (Gold → Silver → Bronze) so we
/// guarantee authentic African-accented audio across all 14 languages.
class CurriculumAudioService {
  static const _manifestPath = 'assets/data/audio_manifest.json';

  Map<String, dynamic>? _manifest;
  bool _manifestRegisteredWithTts = false;

  Future<Map<String, dynamic>> _loadManifest() async {
    if (_manifest != null) return _manifest!;
    final raw = await rootBundle.loadString(_manifestPath);
    _manifest = jsonDecode(raw) as Map<String, dynamic>;
    if (!_manifestRegisteredWithTts) {
      AfricanTtsService().setManifest(_manifest!);
      _manifestRegisteredWithTts = true;
    }
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

  /// Speaks [text] in [language] using the Gold → Silver → Bronze resolver.
  /// [slow] selects the slow variant from the audio manifest (Gold) or scales
  /// the synthesis speed for Silver/Bronze.
  Future<void> speakPhrase({
    required String language,
    required String text,
    required bool slow,
  }) async {
    await _loadManifest();
    await AfricanTtsService().speak(
      language: language,
      text: text,
      slow: slow,
      speed: slow ? 0.7 : 1.0,
    );
  }

  String? nativeCdnUrl(String language, String text) {
    final entries = _manifest?['entries'] as List<dynamic>?;
    if (entries == null) return null;
    for (final e in entries) {
      if (e is Map && e['language'] == language && e['text'] == text) {
        return (e['native'] as Map?)?['cdn_url']?.toString();
      }
    }
    return null;
  }
}

final curriculumAudioServiceProvider = Provider<CurriculumAudioService>((ref) {
  return CurriculumAudioService();
});
