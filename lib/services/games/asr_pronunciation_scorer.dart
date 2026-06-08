import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../env_config.dart';
import '../voice/audio_recording_service.dart';

/// Qualitative bands returned by the Whisper ASR scorer.
enum AsrPronunciationBand { excellent, great, good, keepTrying }

/// Immutable result emitted by [AsrPronunciationScorer.scoreAudio].
@immutable
class AsrPronunciationResult {
  const AsrPronunciationResult({
    required this.score,
    required this.band,
    required this.transcript,
    required this.targetNormalized,
    required this.transcriptNormalized,
    required this.charSimilarity,
    required this.tokenOverlap,
    required this.asrConfidence,
    required this.durationSeconds,
    required this.language,
    required this.modelSize,
    required this.sha256,
    required this.measuredAt,
  });

  final int score;
  final AsrPronunciationBand band;
  final String transcript;
  final String targetNormalized;
  final String transcriptNormalized;
  final double charSimilarity;
  final double tokenOverlap;
  final double asrConfidence;
  final double durationSeconds;
  final String language;
  final String modelSize;
  final String sha256;
  final DateTime measuredAt;

  /// Convenience getters used by the game UI to drive XP/heart logic.
  bool get isPass => score >= 55;
  bool get isStrong => score >= 75;

  /// Convert the wire band string into the enum.
  static AsrPronunciationBand bandFromString(String? raw) {
    switch (raw) {
      case 'excellent':
        return AsrPronunciationBand.excellent;
      case 'great':
        return AsrPronunciationBand.great;
      case 'good':
        return AsrPronunciationBand.good;
      default:
        return AsrPronunciationBand.keepTrying;
    }
  }

  factory AsrPronunciationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;
    return AsrPronunciationResult(
      score: (data['score'] as num?)?.toInt() ?? 0,
      band: bandFromString(data['band'] as String?),
      transcript: (data['transcript'] as String?) ?? '',
      targetNormalized: (data['target_normalized'] as String?) ?? '',
      transcriptNormalized: (data['transcript_normalized'] as String?) ?? '',
      charSimilarity: (data['char_similarity'] as num?)?.toDouble() ?? 0.0,
      tokenOverlap: (data['token_overlap'] as num?)?.toDouble() ?? 0.0,
      asrConfidence: (data['asr_confidence'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (data['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      language: (data['language'] as String?) ?? '',
      modelSize: (data['model_size'] as String?) ?? '',
      sha256: (data['sha256'] as String?) ?? '',
      measuredAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'score': score,
        'band': band.name,
        'transcript': transcript,
        'target_normalized': targetNormalized,
        'transcript_normalized': transcriptNormalized,
        'char_similarity': charSimilarity,
        'token_overlap': tokenOverlap,
        'asr_confidence': asrConfidence,
        'duration_seconds': durationSeconds,
        'language': language,
        'model_size': modelSize,
        'sha256': sha256,
        'measured_at': measuredAt.toIso8601String(),
      };
}

/// Thrown when the backend rejects or the upstream Whisper service is down.
class AsrPronunciationException implements Exception {
  AsrPronunciationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'AsrPronunciationException(status: $statusCode, message: $message)';
}

/// Production pronunciation scorer powered by Whisper via the backend proxy.
///
/// The scorer can:
/// * Score a recorded WAV/MP3/OGG file via [scoreAudio].
/// * Run the full capture → score → return loop via [recordAndScore]
///   which delegates microphone capture to [AudioRecordingService].
class AsrPronunciationScorer {
  AsrPronunciationScorer({
    http.Client? httpClient,
    AudioRecordingService? recorder,
  })  : _http = httpClient ?? http.Client(),
        _recorder = recorder ?? AudioRecordingService();

  static final AsrPronunciationScorer instance = AsrPronunciationScorer();

  final http.Client _http;
  final AudioRecordingService _recorder;

  static const Duration _maxRecording = Duration(seconds: 25);
  static const Duration _httpTimeout = Duration(seconds: 60);

  Future<String?> _authToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('access_token');
  }

  Uri _scoreUri() {
    final base = EnvConfig.backendBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/api/v2/asr/score');
  }

  MediaType _mediaTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'wav':
      case 'wave':
        return MediaType('audio', 'wav');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'm4a':
        return MediaType('audio', 'mp4');
      case 'ogg':
        return MediaType('audio', 'ogg');
      case 'webm':
        return MediaType('audio', 'webm');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  /// Sends [audioFile] together with [targetText] and [language] to the
  /// backend ASR proxy and returns a structured pronunciation result.
  Future<AsrPronunciationResult> scoreAudio({
    required File audioFile,
    required String targetText,
    required String language,
    String modelSize = 'small',
  }) async {
    if (!audioFile.existsSync()) {
      throw AsrPronunciationException('Recording file is missing: ${audioFile.path}');
    }
    final cleanedTarget = targetText.trim();
    if (cleanedTarget.isEmpty) {
      throw AsrPronunciationException('targetText must not be empty');
    }
    final token = await _authToken();
    final request = http.MultipartRequest('POST', _scoreUri())
      ..fields['target_text'] = cleanedTarget
      ..fields['language'] = language
      ..fields['model_size'] = modelSize
      ..files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: _mediaTypeFor(audioFile.path),
      ));

    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await _http.send(request).timeout(_httpTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AsrPronunciationException(
          'Unexpected ASR response shape',
          statusCode: response.statusCode,
        );
      }
      return AsrPronunciationResult.fromJson(decoded);
    }

    String message = 'ASR scoring failed';
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      } else if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      message = response.body.isEmpty ? message : response.body;
    }
    throw AsrPronunciationException(message, statusCode: response.statusCode);
  }

  /// Records up to [duration] seconds of audio and scores it. The caller is
  /// responsible for awaiting [AudioRecordingService.requestPermission]
  /// beforehand when surfacing a UI prompt is desirable.
  Future<AsrPronunciationResult> recordAndScore({
    required String targetText,
    required String language,
    Duration duration = const Duration(seconds: 8),
    String modelSize = 'small',
  }) async {
    final clamped = duration > _maxRecording ? _maxRecording : duration;
    final path = await _recorder.startRecording();
    if (path == null) {
      throw AsrPronunciationException('Microphone permission denied');
    }
    try {
      await Future<void>.delayed(clamped);
    } finally {
      await _recorder.stopRecording();
    }
    final file = File(path);
    try {
      final result = await scoreAudio(
        audioFile: file,
        targetText: targetText,
        language: language,
        modelSize: modelSize,
      );
      return result;
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Cache hygiene best-effort: ignore deletion failure.
      }
    }
  }

  /// Stop and dispose underlying resources.
  Future<void> dispose() async {
    _recorder.dispose();
    _http.close();
  }
}
