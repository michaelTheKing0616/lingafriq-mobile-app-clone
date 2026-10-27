import 'package:dio/dio.dart';

/// Native lexicon recordings (2–3 voices, P7-917).
class LexiconNativeRecordingClip {
  const LexiconNativeRecordingClip({
    required this.voiceId,
    required this.uri,
    required this.speed,
    required this.speakerAgeBand,
    required this.speakerGender,
    required this.alignedPhones,
  });

  final String voiceId;
  final String uri;
  final String speed;
  final String speakerAgeBand;
  final String speakerGender;
  final List<String> alignedPhones;

  factory LexiconNativeRecordingClip.fromJson(Map<String, dynamic> json) {
    final phones = (json['aligned_phones'] as List?) ?? const [];
    return LexiconNativeRecordingClip(
      voiceId: (json['voice_id'] ?? '').toString(),
      uri: (json['uri'] ?? '').toString(),
      speed: (json['speed'] ?? 'natural').toString(),
      speakerAgeBand: (json['speaker_age_band'] ?? '').toString(),
      speakerGender: (json['speaker_gender'] ?? '').toString(),
      alignedPhones: phones.map((e) => e.toString()).toList(),
    );
  }
}

class LexiconAudioBundle {
  const LexiconAudioBundle({
    required this.lexemeId,
    required this.language,
    required this.recordings,
    required this.needsMoreVoices,
    required this.playableCount,
  });

  final String lexemeId;
  final String language;
  final List<LexiconNativeRecordingClip> recordings;
  final bool needsMoreVoices;
  final int playableCount;

  List<String> get playableUris =>
      recordings.map((r) => r.uri).where((u) => u.isNotEmpty).toList();

  factory LexiconAudioBundle.fromApiJson(Map<String, dynamic> json) {
    final clips = (json['recordings'] as List?) ?? const [];
    final parsed = <LexiconNativeRecordingClip>[];
    for (final clip in clips) {
      if (clip is Map<String, dynamic>) {
        parsed.add(LexiconNativeRecordingClip.fromJson(clip));
      } else if (clip is Map) {
        parsed.add(
          LexiconNativeRecordingClip.fromJson(clip.cast<String, dynamic>()),
        );
      }
    }
    return LexiconAudioBundle(
      lexemeId: (json['lexeme_id'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      recordings: parsed,
      needsMoreVoices: json['needs_more_voices'] == true,
      playableCount: (json['playable_count'] is int)
          ? json['playable_count'] as int
          : parsed.length,
    );
  }
}

class LexiconAudioClient {
  LexiconAudioClient(this._dio, {String? baseUrl}) : _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static const String bundlePathPrefix = '/api/v2/lexicon-audio/entries/';

  String _entryUrl(String lexemeId) {
    final root = _baseUrl ?? _dio.options.baseUrl;
    final base = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    return '$base$bundlePathPrefix${Uri.encodeComponent(lexemeId)}';
  }

  Future<LexiconAudioBundle> fetchBundle(String lexemeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _entryUrl(lexemeId),
      options: Options(responseType: ResponseType.json),
    );
    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status == 404) {
      throw LexiconAudioException(
        code: 'LEXICON_ENTRY_NOT_FOUND',
        message: 'Lexicon entry not found',
        statusCode: status,
      );
    }
    if (status < 200 || status >= 300 || body == null) {
      throw LexiconAudioException(
        code: body?['code']?.toString() ?? 'LEXICON_AUDIO_FETCH_FAILED',
        message: body?['message']?.toString() ?? 'Failed to load lexicon audio',
        statusCode: status,
      );
    }
    return LexiconAudioBundle.fromApiJson(body);
  }

  Future<LexiconAudioBundle> attachRecordings({
    required String lexemeId,
    required List<Map<String, dynamic>> recordings,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _entryUrl(lexemeId),
      data: {'recordings': recordings},
      options: Options(responseType: ResponseType.json),
    );
    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status < 200 || status >= 300 || body == null) {
      throw LexiconAudioException(
        code: body?['code']?.toString() ?? 'LEXICON_AUDIO_ATTACH_FAILED',
        message: body?['message']?.toString() ?? 'Failed to attach recordings',
        statusCode: status,
      );
    }
    if (body['ok'] == false) {
      throw LexiconAudioException(
        code: body['code']?.toString() ?? 'LEXICON_AUDIO_ATTACH_FAILED',
        message: body['message']?.toString() ?? 'Attach rejected',
        statusCode: status,
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return LexiconAudioBundle.fromApiJson(data);
    }
    return LexiconAudioBundle.fromApiJson(body);
  }
}

class LexiconAudioException implements Exception {
  LexiconAudioException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'LexiconAudioException($code): $message';
}
