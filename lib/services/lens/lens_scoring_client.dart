import 'package:dio/dio.dart';

import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';

/// Copy keys: lens.say.unsure, lens.say.error (P7-908).
const String lensSayUnsureCopy =
    'We could not score this clearly. No score is shown — please try again.';
const String lensSayErrorCopy =
    'Pronunciation scoring is unavailable. Your attempt was saved to retry when you are back online.';

const String kLensScoreUtterancePath = '/api/ai/score/utterance';

/// Parsed gateway scorer response — no fabricated numeric overall score (AC3).
class LensScoreOutcome {
  const LensScoreOutcome({
    required this.phase,
    this.syllables = const [],
    this.errorMessage,
    this.retryable = false,
    this.celebrate = false,
  });

  final ToneOverlayStatus phase;
  final List<SyllableToneOverlayRow> syllables;
  final String? errorMessage;
  final bool retryable;
  final bool celebrate;
}

typedef LensScorePost = Future<Response<dynamic>> Function(
  String path,
  FormData data,
);

/// Posts learner audio to the real GOP + tone scorer (not the legacy tone-trainer stub).
class LensScoringClient {
  const LensScoringClient({this.scorePath = kLensScoreUtterancePath});

  final String scorePath;

  Future<LensScoreOutcome> scoreUtterance({
    required LensScorePost post,
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    try {
      final response = await post(
        scorePath,
        FormData.fromMap({
          'audio': await MultipartFile.fromFile(
            audioPath,
            filename: 'lens_speak.wav',
          ),
          'expected_text': expectedText.trim(),
          'language': language.trim().toLowerCase(),
        }),
      );
      final statusCode = response.statusCode ?? 0;
      final raw = response.data;
      final body = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (statusCode == 503 || body['code'] == 'scorer_unavailable' || body['retryable'] == true) {
        return const LensScoreOutcome(
          phase: ToneOverlayStatus.error,
          errorMessage: lensSayErrorCopy,
          retryable: true,
        );
      }
      if (statusCode != 200) {
        return const LensScoreOutcome(
          phase: ToneOverlayStatus.error,
          errorMessage: lensSayErrorCopy,
          retryable: false,
        );
      }
      return parseScoreBody(body);
    } catch (_) {
      return const LensScoreOutcome(
        phase: ToneOverlayStatus.error,
        errorMessage: lensSayErrorCopy,
        retryable: true,
      );
    }
  }
}

LensScoreOutcome parseScoreBody(Map<String, dynamic> body) {
  final rawList = body['syllables'];
  final rows = <SyllableToneOverlayRow>[];
  if (rawList is List) {
    for (final item in rawList) {
      if (item is Map) {
        rows.add(SyllableToneOverlayRow.fromJson(Map<String, dynamic>.from(item)));
      }
    }
  }
  final status = (body['status'] as String?)?.toLowerCase() ?? '';
  final retryRequested = body['retry_requested'] == true || status == 'unsure';
  final allUnsure = rows.isNotEmpty && rows.every((r) => r.isUnsure);
  if (retryRequested || allUnsure) {
    return LensScoreOutcome(
      phase: ToneOverlayStatus.unsure,
      syllables: rows,
      errorMessage: lensSayUnsureCopy,
    );
  }
  if (rows.isEmpty) {
    return const LensScoreOutcome(
      phase: ToneOverlayStatus.error,
      errorMessage: lensSayErrorCopy,
    );
  }
  final allCorrect = rows.every((r) => r.correct == true && !r.isUnsure);
  return LensScoreOutcome(
    phase: ToneOverlayStatus.scored,
    syllables: rows,
    celebrate: allCorrect,
  );
}
