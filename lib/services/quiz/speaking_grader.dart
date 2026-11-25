import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Learner-facing copy for a speaking prompt. The record control's semantics
/// label is separate (`item.speak`); these strings are what is shown.
class SpeakingCopy {
  static const speak = 'Say this';
  static const unsure = 'Not sure yet. No score.';
  static const unavailable = 'Scoring is unavailable. Nothing was scored.';
  static const record = 'Record';
  static const stop = 'Stop';
}

/// Confidence under this value is withheld. The scorer is not sure enough to
/// put a number on the attempt. A value equal to the floor is still shown.
const double speakingLowConfidence = 0.6;

/// Bound used by the hybrid-polie pronounce client so a hung scorer cannot
/// hold the take open.
const Duration speakingScorerTimeout = Duration(seconds: 30);

/// Result of one pronounce call.
///
/// [available] is false when the service did not score. [score] and
/// [confidence] stay null in that case; they are never filled with a default.
class ScorerPayload {
  const ScorerPayload({
    required this.score,
    required this.confidence,
    required this.available,
  });

  final double? score;
  final double? confidence;
  final bool available;
}

/// Phase plus the numbers that are safe to show.
///
/// [score] is null for `unavailable` and `unsure`. [confidence] is kept on
/// `unsure` so the gate that hid the score is still visible to callers, and
/// null on `unavailable`.
class SpeakingGrade {
  const SpeakingGrade({
    required this.phase,
    required this.score,
    required this.confidence,
  });

  final String phase;
  final double? score;
  final double? confidence;
}

/// Scores one recording. Implementations must not invent a score.
abstract class SpeakingScorer {
  Future<ScorerPayload> score({
    required String audioPath,
    required String referenceText,
    required String language,
  });
}

/// Records one take and can delete it after scoring.
abstract class SpeakingRecorder {
  /// Starts a new take. Side effect: the device begins recording.
  Future<void> start();

  /// Stops the take and returns its file path.
  Future<String> stop();

  /// Deletes the take at [path]. Side effect: the raw audio is removed.
  Future<void> discard(String path);
}

const ScorerPayload _unscored = ScorerPayload(
  score: null,
  confidence: null,
  available: false,
);

bool _unitInterval(double? value) {
  if (value == null || !value.isFinite) return false;
  return value >= 0 && value <= 1;
}

/// Grades a pronounce payload.
///
/// A usable result is a finite score in `[0, 1]` and a finite confidence in
/// `[0, 1]` from a scorer that actually scored. Confidence below
/// [speakingLowConfidence] is `unsure` and the score is null. Anything else
/// is `unavailable` and the score is null.
SpeakingGrade gradeSpeaking(ScorerPayload payload) {
  final score = payload.score;
  final confidence = payload.confidence;
  if (!payload.available ||
      !_unitInterval(score) ||
      !_unitInterval(confidence)) {
    return const SpeakingGrade(
      phase: 'unavailable',
      score: null,
      confidence: null,
    );
  }
  if (confidence! < speakingLowConfidence) {
    return SpeakingGrade(phase: 'unsure', score: null, confidence: confidence);
  }
  return SpeakingGrade(phase: 'scored', score: score, confidence: confidence);
}

double? _finiteNumber(Object? value) {
  if (value is! num) return null;
  final number = value.toDouble();
  if (!number.isFinite) return null;
  return number;
}

Map<String, dynamic>? _jsonObject(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}

ScorerPayload _payloadFrom(int? status, Object? data) {
  if (status != 200) return _unscored;
  final body = _jsonObject(data);
  if (body == null) return _unscored;
  if (body['model'] == 'fallback' ||
      body['code'] == 'pronunciation_unavailable') {
    return _unscored;
  }
  final score = _finiteNumber(body['score']);
  final confidence = _finiteNumber(body['confidence']);
  if (score == null || confidence == null) return _unscored;
  return ScorerPayload(score: score, confidence: confidence, available: true);
}

/// Posts the take to the real hybrid-polie pronounce endpoint.
///
/// The JSON body is `audioUrl` (the recording path), `referenceText`, and
/// `language`. A 200 with a numeric score and a numeric confidence is
/// available. Status 503, `code: pronunciation_unavailable`, `model: fallback`,
/// a missing number, or any error is unavailable with both numbers null.
/// This client does not send an API key.
class HttpSpeakingScorer implements SpeakingScorer {
  HttpSpeakingScorer(this._dio);

  final Dio _dio;

  @override
  Future<ScorerPayload> score({
    required String audioPath,
    required String referenceText,
    required String language,
  }) async {
    try {
      final response = await _dio.post<Object>(
        '${ApiContract.baseUrl}/hybrid-polie/pronounce',
        data: <String, String>{
          'audioUrl': audioPath,
          'referenceText': referenceText,
          'language': language,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          receiveTimeout: speakingScorerTimeout,
          sendTimeout: speakingScorerTimeout,
          // Non-200 bodies are graded unavailable. They must not throw away
          // the status that tells us the scorer refused the take.
          validateStatus: (status) => status != null,
        ),
      );
      return _payloadFrom(response.statusCode, response.data);
    } catch (_) {
      return _unscored;
    }
  }
}
