import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:lingafriq/services/audio/african_tts_service.dart';

/// Loads the bundled [audio_manifest.json] once at app start so every TTS
/// surface (games, tutor, Polie, vocabulary) can resolve **Gold** tier audio
/// without waiting for Authentic Path to open first.
class AfricanTtsBootstrap {
  AfricanTtsBootstrap._();
  static bool _loaded = false;

  static const _manifestPath = 'assets/data/audio_manifest.json';

  static Future<void> ensureManifestLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_manifestPath);
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      AfricanTtsService().setManifest(manifest);
      _loaded = true;
      final entries = (manifest['entries'] as List?)?.length ?? 0;
      debugPrint('[AfricanTtsBootstrap] manifest loaded ($entries entries)');
    } catch (e) {
      debugPrint('[AfricanTtsBootstrap] manifest load failed: $e');
    }
  }
}
