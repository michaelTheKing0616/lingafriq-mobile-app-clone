// African TTS Service — Gold → Silver → Bronze resolver
//
// Plays authentic African-accented audio for every supported language by
// resolving the best available source in order:
//
//   Gold   — Pre-recorded native speaker MP3 hosted on CDN (assets/data/
//            audio_manifest.json contains the SHA256 + CDN URL).
//   Silver — Meta MMS-TTS via backend proxy /api/tts. Free, self-hosted,
//            supports 40+ African languages.
//   Bronze — Coqui XTTS-v2 via /api/voice/tts/synthesize (premium voice
//            cloning where available; preserves authentic prosody for
//            English variants and high-resource African langs).
//   Fallback — On-device flutter_tts ONLY when network is unavailable. We
//            return early so no English ljspeech voice ever speaks an
//            African phrase by accident.
//
// All successful syntheses are sha256-keyed and cached on disk via
// TtsAudioCache so subsequent plays are zero-latency and offline-safe.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/services/audio/tts_audio_cache.dart';

enum TtsEngineTier { gold, silver, bronze, deviceFallback, unavailable }

class TtsResolution {
  final TtsEngineTier tier;
  final File? localFile;
  final String? cdnUrl;
  final String? engineLabel;
  final String? errorReason;
  const TtsResolution({
    required this.tier,
    this.localFile,
    this.cdnUrl,
    this.engineLabel,
    this.errorReason,
  });
}

class AfricanTtsService {
  AfricanTtsService._();
  static final AfricanTtsService _i = AfricanTtsService._();
  factory AfricanTtsService() => _i;

  final TtsAudioCache _cache = TtsAudioCache();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _fallbackTts = FlutterTts();
  bool _fallbackInitialized = false;

  /// In-memory lookup populated by [setManifest] to enable Gold tier resolution.
  Map<String, Map<String, dynamic>> _manifestByKey = {};

  /// Optional hook set at app startup to forward tier metrics to [TelemetryService].
  static void Function({
    required String language,
    required TtsEngineTier tier,
    required bool playbackOk,
    String? engineLabel,
    required int textLength,
  })? onResolution;

  /// Stats counters used by [telemetrySnapshot]; instrumentation only.
  int _goldHits = 0;
  int _silverHits = 0;
  int _bronzeHits = 0;
  int _deviceFallbackHits = 0;
  int _failures = 0;

  /// Call once at app start with the parsed audio_manifest.json so the Gold
  /// tier resolver can find pre-recorded native speaker audio.
  void setManifest(Map<String, dynamic> manifest) {
    final entries = (manifest['entries'] as List?) ?? const [];
    final out = <String, Map<String, dynamic>>{};
    for (final e in entries) {
      if (e is! Map) continue;
      final lang = (e['language'] ?? '').toString().toLowerCase();
      final text = (e['text'] ?? '').toString();
      if (lang.isEmpty || text.isEmpty) continue;
      out['$lang|$text'] = e.cast<String, dynamic>();
    }
    _manifestByKey = out;
  }

  Map<String, int> telemetrySnapshot() => {
        'goldHits': _goldHits,
        'silverHits': _silverHits,
        'bronzeHits': _bronzeHits,
        'deviceFallbackHits': _deviceFallbackHits,
        'failures': _failures,
      };

  /// Synthesizes + plays [text] in [language]. Returns the resolution tier
  /// the audio was sourced from so callers can surface diagnostics.
  Future<TtsResolution> speak({
    required String language,
    required String text,
    bool slow = false,
    double speed = 1.0,
    String? voice,
  }) async {
    final resolution = await resolve(
      language: language,
      text: text,
      slow: slow,
      speed: speed,
      voice: voice,
    );
    var playbackOk = false;
    try {
      await _player.stop();
      if (resolution.localFile != null) {
        await _player.play(DeviceFileSource(resolution.localFile!.path));
        playbackOk = true;
      } else if (resolution.cdnUrl != null) {
        await _player.play(UrlSource(resolution.cdnUrl!));
        playbackOk = true;
      } else if (resolution.tier == TtsEngineTier.deviceFallback) {
        await _playDeviceFallback(language: language, text: text, speed: speed);
        playbackOk = true;
      }
    } catch (e) {
      debugPrint('[AfricanTts] playback failed: $e');
    }
    onResolution?.call(
      language: language,
      tier: resolution.tier,
      playbackOk: playbackOk,
      engineLabel: resolution.engineLabel,
      textLength: text.length,
    );
    return resolution;
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _fallbackTts.stop();
    } catch (_) {}
  }

  /// Resolves audio without playing. Useful for prefetch.
  Future<TtsResolution> resolve({
    required String language,
    required String text,
    bool slow = false,
    double speed = 1.0,
    String? voice,
  }) async {
    final lang = language.trim();
    final body = text.trim();
    if (body.isEmpty) {
      return const TtsResolution(
        tier: TtsEngineTier.unavailable,
        errorReason: 'empty_text',
      );
    }

    // -------- GOLD: pre-recorded native CDN audio --------
    final gold = await _resolveGold(language: lang, text: body, slow: slow);
    if (gold != null) {
      _goldHits++;
      return gold;
    }

    // -------- SILVER: MMS-TTS via backend proxy --------
    try {
      final silver = await _resolveSilverMms(
        language: lang,
        text: body,
        speed: speed,
      );
      if (silver != null) {
        _silverHits++;
        return silver;
      }
    } catch (e) {
      debugPrint('[AfricanTts] silver(mms) failed: $e');
    }

    // -------- BRONZE: XTTS-v2 voice synthesis --------
    try {
      final bronze = await _resolveBronzeXtts(
        language: lang,
        text: body,
        speed: speed,
        voice: voice,
      );
      if (bronze != null) {
        _bronzeHits++;
        return bronze;
      }
    } catch (e) {
      debugPrint('[AfricanTts] bronze(xtts) failed: $e');
    }

    // -------- DEVICE FALLBACK: only when network is dead --------
    if (await _allowDeviceFallback()) {
      _deviceFallbackHits++;
      return const TtsResolution(
        tier: TtsEngineTier.deviceFallback,
        engineLabel: 'flutter_tts',
      );
    }

    _failures++;
    return const TtsResolution(
      tier: TtsEngineTier.unavailable,
      errorReason: 'no_engine_available',
    );
  }

  Future<TtsResolution?> _resolveGold({
    required String language,
    required String text,
    required bool slow,
  }) async {
    final key = '${language.toLowerCase()}|$text';
    final entry = _manifestByKey[key];
    if (entry == null) return null;
    final variant = slow ? 'slow' : 'native';
    final block = entry[variant] as Map<String, dynamic>?;
    if (block == null) return null;
    final cdnUrl = (block['cdn_url'] ?? '').toString();
    if (cdnUrl.isEmpty) return null;

    final cacheKey = _cache.makeKey(
      language: language,
      text: text,
      engine: 'gold',
      voice: variant,
    );
    final cached = await _cache.get(cacheKey, ext: 'mp3');
    if (cached != null) {
      return TtsResolution(
        tier: TtsEngineTier.gold,
        localFile: cached.file,
        engineLabel: 'cdn_native',
      );
    }

    // Download once, then cache. We don't bundle the audio inside the asset
    // path for size; bundle the manifest only.
    try {
      final resp = await http
          .get(Uri.parse(cdnUrl))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final file =
            await _cache.put(cacheKey, resp.bodyBytes, ext: 'mp3');
        return TtsResolution(
          tier: TtsEngineTier.gold,
          localFile: file,
          cdnUrl: file == null ? cdnUrl : null,
          engineLabel: 'cdn_native',
        );
      }
    } catch (e) {
      debugPrint('[AfricanTts] gold CDN fetch failed: $e');
    }
    // Couldn't fetch — let callers fall through to silver.
    return null;
  }

  Future<TtsResolution?> _resolveSilverMms({
    required String language,
    required String text,
    required double speed,
  }) async {
    final cacheKey = _cache.makeKey(
      language: language,
      text: text,
      engine: 'mms',
      speed: speed,
    );
    final cached = await _cache.get(cacheKey, ext: 'wav');
    if (cached != null) {
      return TtsResolution(
        tier: TtsEngineTier.silver,
        localFile: cached.file,
        engineLabel: 'mms_tts',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('access_token');
    final base = EnvConfig.backendBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final url = Uri.parse(
      '$base/api/tts?language=${Uri.encodeQueryComponent(language)}&text=${Uri.encodeQueryComponent(text)}',
    );
    final resp = await http.get(
      url,
      headers: {
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 12));
    if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
      final saved = await _cache.put(cacheKey, resp.bodyBytes, ext: 'wav');
      return TtsResolution(
        tier: TtsEngineTier.silver,
        localFile: saved,
        engineLabel: 'mms_tts',
      );
    }
    debugPrint('[AfricanTts] silver(mms) http ${resp.statusCode}');
    return null;
  }

  Future<TtsResolution?> _resolveBronzeXtts({
    required String language,
    required String text,
    required double speed,
    String? voice,
  }) async {
    final cacheKey = _cache.makeKey(
      language: language,
      text: text,
      engine: 'xtts',
      voice: voice ?? '',
      speed: speed,
    );
    final cached = await _cache.get(cacheKey, ext: 'mp3');
    if (cached != null) {
      return TtsResolution(
        tier: TtsEngineTier.bronze,
        localFile: cached.file,
        engineLabel: 'xtts_v2',
      );
    }

    final bytes = await _fetchBronzeAudioBytes(
      text: text,
      language: language,
      voice: voice,
      speed: speed,
    );
    if (bytes != null && bytes.isNotEmpty) {
      final saved = await _cache.put(cacheKey, bytes, ext: 'mp3');
      return TtsResolution(
        tier: TtsEngineTier.bronze,
        localFile: saved,
        engineLabel: 'xtts_v2',
      );
    }
    return null;
  }

  Future<Uint8List?> _fetchBronzeAudioBytes({
    required String text,
    required String language,
    String? voice,
    double speed = 1.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('access_token');
    final base = EnvConfig.backendBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final clipped = text.length > 500 ? text.substring(0, 500) : text;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      final synth = await http
          .post(
            Uri.parse('$base/api/voice/tts/synthesize'),
            headers: headers,
            body: jsonEncode({
              'text': clipped,
              'language': language,
              if (voice != null && voice.trim().isNotEmpty) 'voice': voice.trim(),
              'speed': speed,
            }),
          )
          .timeout(const Duration(seconds: 45));
      if (synth.statusCode == 200 && synth.bodyBytes.isNotEmpty) {
        return synth.bodyBytes;
      }
    } catch (e) {
      debugPrint('[AfricanTts] bronze synth failed: $e');
    }
    return null;
  }

  Future<bool> _allowDeviceFallback() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final offline = results.every(
        (r) => r == ConnectivityResult.none,
      );
      return offline;
    } catch (_) {
      return false;
    }
  }

  Future<void> _playDeviceFallback({
    required String language,
    required String text,
    required double speed,
  }) async {
    if (!_fallbackInitialized) {
      try {
        await _fallbackTts.setVolume(1.0);
      } catch (_) {}
      _fallbackInitialized = true;
    }
    // Try the best-available device locale for the language. If the device
    // doesn't have it installed, the TTS engine will pick its closest match.
    final locale = _bcp47ForLanguage(language);
    if (locale.isNotEmpty) {
      try {
        await _fallbackTts.setLanguage(locale);
      } catch (_) {}
    }
    try {
      await _fallbackTts.setSpeechRate(speed.clamp(0.3, 1.5));
    } catch (_) {}
    try {
      await _fallbackTts.speak(text);
    } catch (e) {
      debugPrint('[AfricanTts] device fallback speak failed: $e');
    }
  }

  /// BCP-47 locale used only as a last-resort fallback. Returns empty when no
  /// reasonable locale exists for the language to avoid speaking an African
  /// phrase with an en-US voice.
  String _bcp47ForLanguage(String language) {
    final lang = language.trim().toLowerCase();
    const map = <String, String>{
      'english': 'en-US',
      'french': 'fr-FR',
      'spanish': 'es-ES',
      'portuguese': 'pt-BR',
      'arabic': 'ar-SA',
      'german': 'de-DE',
      'yoruba': 'yo-NG',
      'hausa': 'ha-NG',
      'igbo': 'ig-NG',
      'swahili': 'sw-KE',
      'zulu': 'zu-ZA',
      'xhosa': 'xh-ZA',
      'amharic': 'am-ET',
      'afrikaans': 'af-ZA',
      'somali': 'so-SO',
      'wolof': 'wo-SN',
      'twi': 'tw-GH',
      'akan': 'ak-GH',
      'pidgin': 'en-NG',
      'nigerian pidgin': 'en-NG',
      'pidgin english': 'en-NG',
      'tigrinya': 'ti-ET',
      'shona': 'sn-ZW',
      'lingala': 'ln-CD',
      'kinyarwanda': 'rw-RW',
      'sesotho': 'st-ZA',
      'setswana': 'tn-ZA',
      'malagasy': 'mg-MG',
      'fula': 'ff-SN',
      'fulani': 'ff-SN',
      'oromo': 'om-ET',
    };
    return map[lang] ?? '';
  }

  /// Convenience: pre-fetch + cache a list of (language, text) pairs without
  /// playing anything. Used by [TtsPrefetchService] on lesson open.
  Future<void> prefetchMany(Iterable<({String language, String text})> items) async {
    for (final item in items) {
      try {
        await resolve(language: item.language, text: item.text);
      } catch (e) {
        debugPrint('[AfricanTts] prefetch item failed: $e');
      }
    }
  }
}

/// Convenience accessor for places that previously held a [FlutterTts] field.
final africanTtsService = AfricanTtsService();

// Unused import guard (audio bytes typed for clarity).
typedef _UnusedUint8List = Uint8List;
