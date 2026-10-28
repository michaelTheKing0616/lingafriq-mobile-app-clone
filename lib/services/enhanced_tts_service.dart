// Enhanced Text-to-Speech Service for African Languages
//
// P6-047: human / curriculum recordings play first; licensed gateway TTS is
// used only for dynamic AI turns. Yoruba, Igbo, Hausa, and Twi never fall
// back to on-device flutter_tts — the UI surfaces an explicit no-voice state.

import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/services/voice/tts_service.dart';
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

enum EnhancedTtsTurnKind {
  curriculumRecorded,
  dynamicAi,
}

enum EnhancedTtsPlaybackKind {
  playingHuman,
  playingLicensed,
  noVoice,
  voiceComing,
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

class EnhancedTtsPlaybackPlan {
  const EnhancedTtsPlaybackPlan({
    required this.kind,
    this.humanAudioUrl,
    this.licensedAudioBytes,
    this.unavailableCode,
    this.gatewayTtsRequested = false,
  });

  final EnhancedTtsPlaybackKind kind;
  final String? humanAudioUrl;
  final Uint8List? licensedAudioBytes;
  final String? unavailableCode;

  /// True when a licensed server route was invoked (human audio did not win).
  final bool gatewayTtsRequested;

  bool get showNoVoiceState =>
      kind == EnhancedTtsPlaybackKind.noVoice ||
      kind == EnhancedTtsPlaybackKind.voiceComing;
}

class EnhancedTtsSpeakRequest {
  const EnhancedTtsSpeakRequest({
    required this.text,
    required this.language,
    this.turnKind = EnhancedTtsTurnKind.dynamicAi,
    this.humanAudioUrl,
    this.config,
  });

  final String text;
  final String language;
  final EnhancedTtsTurnKind turnKind;
  final String? humanAudioUrl;
  final TTSConfig? config;
}

class EnhancedTTSService {
  EnhancedTTSService({
    Ref? ref,
    AfricanTtsService? africanTts,
    Future<String?> Function()? authToken,
    http.Client? httpClient,
  })  : _ref = ref,
        _africanTts = africanTts,
        _authToken = authToken,
        _http = httpClient ?? http.Client();

  final Ref? _ref;
  final AfricanTtsService? _africanTts;
  final Future<String?> Function()? _authToken;
  final http.Client _http;
  AudioPlayer? _player;

  AfricanTtsService get _african => _africanTts ?? AfricanTtsService();

  bool _isInitialized = false;
  String? _userLanguage;

  static const _strictNoDeviceLangs = {'yo', 'ig', 'ha', 'tw'};

  static String noVoiceSemanticsLabel(String language) =>
      'No licensed voice for $language. Text only.';

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

  String _hubLanguageId(String language) {
    final raw = language.trim().toLowerCase();
    const aliases = {
      'yoruba': 'yo',
      'igbo': 'ig',
      'hausa': 'ha',
      'twi': 'tw',
      'akan': 'tw',
    };
    return aliases[raw] ?? raw;
  }

  bool _requiresStrictNoDevice(String language) =>
      _strictNoDeviceLangs.contains(_hubLanguageId(language));

  Future<EnhancedTtsPlaybackPlan> resolvePlayback(
    EnhancedTtsSpeakRequest request,
  ) async {
    await initialize();
    final trimmed = request.text.trim();
    final language = request.language.trim().isNotEmpty
        ? request.language.trim()
        : (_userLanguage ?? 'English');

    final humanUrl = request.humanAudioUrl?.trim();
    final hasHuman = humanUrl != null && humanUrl.isNotEmpty;
    final isRecordedTurn =
        request.turnKind == EnhancedTtsTurnKind.curriculumRecorded || hasHuman;

    if (isRecordedTurn && hasHuman) {
      return EnhancedTtsPlaybackPlan(
        kind: EnhancedTtsPlaybackKind.playingHuman,
        humanAudioUrl: humanUrl,
      );
    }

    if (isRecordedTurn && !hasHuman) {
      return const EnhancedTtsPlaybackPlan(
        kind: EnhancedTtsPlaybackKind.noVoice,
        unavailableCode: 'recorded_audio_required',
      );
    }

    try {
      final bytes = await _synthesizeViaGateway(
        language: language,
        text: trimmed,
      );
      return EnhancedTtsPlaybackPlan(
        kind: EnhancedTtsPlaybackKind.playingLicensed,
        licensedAudioBytes: bytes,
        gatewayTtsRequested: true,
      );
    } on LicensedVoiceUnavailable catch (e) {
      if (e.code == 'voice_coming') {
        return EnhancedTtsPlaybackPlan(
          kind: EnhancedTtsPlaybackKind.voiceComing,
          unavailableCode: e.code,
          gatewayTtsRequested: true,
        );
      }
      if (_requiresStrictNoDevice(language) ||
          e.code == 'voice_not_gated' ||
          e.code == 'audio_unavailable') {
        return EnhancedTtsPlaybackPlan(
          kind: EnhancedTtsPlaybackKind.noVoice,
          unavailableCode: e.code,
          gatewayTtsRequested: true,
        );
      }
      return EnhancedTtsPlaybackPlan(
        kind: EnhancedTtsPlaybackKind.noVoice,
        unavailableCode: e.code,
        gatewayTtsRequested: true,
      );
    }
  }

  Future<Uint8List> _synthesizeViaGateway({
    required String language,
    required String text,
  }) async {
    final clipped = text.length > 500 ? text.substring(0, 500) : text;
    if (clipped.isEmpty) {
      throw LicensedVoiceUnavailable('audio_unavailable');
    }

    final token = _authToken != null ? await _authToken() : null;
    final root = EnvConfig.backendBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await _http
        .post(
          Uri.parse('$root/api/ai/tts/synthesize'),
          headers: headers,
          body: jsonEncode({
            'text': clipped,
            'language': language,
            'turnKind': 'dynamic_ai',
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (resp.statusCode == 200 &&
        resp.bodyBytes.isNotEmpty &&
        !resp.headers['content-type'].toString().contains('json')) {
      return resp.bodyBytes;
    }

    if (resp.statusCode == 503 || resp.statusCode == 400) {
      final code = _readCode(resp.body) ?? 'audio_unavailable';
      throw LicensedVoiceUnavailable(code);
    }

    throw LicensedVoiceUnavailable('audio_unavailable');
  }

  String? _readCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } catch (_) {}
    return null;
  }

  Future<EnhancedTtsPlaybackPlan> speakWithPlan(
    EnhancedTtsSpeakRequest request,
  ) async {
    final plan = await resolvePlayback(request);
    if (plan.kind == EnhancedTtsPlaybackKind.playingHuman &&
        plan.humanAudioUrl != null) {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(UrlSource(plan.humanAudioUrl!));
      return plan;
    }
    if (plan.kind == EnhancedTtsPlaybackKind.playingLicensed &&
        plan.licensedAudioBytes != null) {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(BytesSource(plan.licensedAudioBytes!));
      return plan;
    }
    if (plan.showNoVoiceState) {
      return plan;
    }

    final cfg = request.config ?? const TTSConfig();
    final effectiveLanguage = cfg.language ?? request.language;
    if (_requiresStrictNoDevice(effectiveLanguage)) {
      return EnhancedTtsPlaybackPlan(
        kind: EnhancedTtsPlaybackKind.noVoice,
        unavailableCode: plan.unavailableCode ?? 'audio_unavailable',
      );
    }

    try {
      await _african.speak(
        language: effectiveLanguage,
        text: request.text.trim(),
        speed: cfg.speed.clamp(0.5, 2.0).toDouble(),
      );
    } catch (e) {
      logger.error('AfricanTtsService.speak failed', error: e, context: {
        'language': effectiveLanguage,
      });
      rethrow;
    }
    return plan;
  }

  Future<void> speak(String text, [TTSConfig? config]) async {
    await initialize();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final effectiveLanguage = config?.language ?? _userLanguage ?? 'English';
    await speakWithPlan(
      EnhancedTtsSpeakRequest(
        text: trimmed,
        language: effectiveLanguage,
        turnKind: EnhancedTtsTurnKind.dynamicAi,
        config: config,
      ),
    );
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      await _african.stop();
    } catch (e) {
      logger.error('Failed to stop TTS', error: e);
    }
  }

  Future<void> pause() async {}

  Future<void> resume() async {}

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

  Future<void> clearCache() async {}

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
