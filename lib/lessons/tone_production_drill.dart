/// Tone production drills with real scorer feedback (P5-029, ELEVATION §6.2).
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';
import 'package:lingafriq/services/quiz/speaking_grader.dart';

/// copy_keys: tone.feedback, tone.unsure
abstract final class ToneProductionCopyKeys {
  static const feedback = 'tone.feedback';
  static const unsure = 'tone.unsure';
  static const record = 'tone.record';
  static const retry = 'tone.retry';

  static const defaultFeedback = 'Listen to the coaching hint, then try again.';
  static const defaultUnsure =
      'We are not sure enough to score that take. Try again.';
  static const defaultRecord = 'Record your pronunciation';
  static const defaultRetry = 'Record again';
}

abstract final class ToneProductionCodes {
  static const randomScoreForbidden = 'RandomScoreForbidden';
}

class ToneProductionSpec {
  const ToneProductionSpec({
    required this.id,
    required this.languageCode,
    required this.targetForm,
    required this.promptGlossEn,
    this.sourceId = '',
  });

  final String id;
  final String languageCode;
  final String targetForm;
  final String promptGlossEn;
  final String sourceId;
}

class ToneProductionError {
  const ToneProductionError({
    required this.syllable,
    required this.position,
    required this.expected,
    required this.actual,
    required this.issue,
  });

  final String syllable;
  final int position;
  final String expected;
  final String actual;
  final String issue;

  factory ToneProductionError.fromJson(Map<String, dynamic> json) {
    return ToneProductionError(
      syllable: json['syllable'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      expected: json['expected'] as String? ?? '',
      actual: json['actual'] as String? ?? '',
      issue: json['issue'] as String? ?? '',
    );
  }
}

/// Raw tone-scorer payload. Never fabricate [accuracy] or [confidence].
class ToneScorerPayload {
  const ToneScorerPayload({
    required this.available,
    required this.accuracy,
    required this.confidence,
    required this.errors,
    required this.summaryFeedback,
  });

  final bool available;
  final double? accuracy;
  final double? confidence;
  final List<ToneProductionError> errors;
  final String? summaryFeedback;
}

const ToneScorerPayload _unscoredTone = ToneScorerPayload(
  available: false,
  accuracy: null,
  confidence: null,
  errors: const [],
  summaryFeedback: null,
);

enum ToneProductionPhase { recording, scoring, feedback, unsure }

class ToneProductionGrade {
  const ToneProductionGrade({
    required this.phase,
    required this.actionableFeedback,
    required this.accuracy,
    required this.confidence,
  });

  final ToneProductionPhase phase;
  final String actionableFeedback;
  final double? accuracy;
  final double? confidence;
}

bool _unitInterval(double? value) {
  if (value == null || !value.isFinite) return false;
  return value >= 0 && value <= 1;
}

double? _finiteNumber(Object? value) {
  if (value is! num) return null;
  final number = value.toDouble();
  if (!number.isFinite) return null;
  return number;
}

String _ordinal(int n) {
  if (n <= 0) return '$n';
  const ones = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth'];
  if (n <= ones.length) return ones[n - 1];
  return '${n}th';
}

/// Turns scorer syllable errors into short coaching copy (AC1).
String buildActionableFeedback({
  required List<ToneProductionError> errors,
  String? summaryFeedback,
}) {
  if (errors.isEmpty) {
    final trimmed = summaryFeedback?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return ToneProductionCopyKeys.defaultFeedback;
  }
  final first = errors.first;
  final syllableLabel =
      first.syllable.isNotEmpty ? "'${first.syllable}'" : 'that syllable';
  final ordinal = _ordinal(first.position + 1);
  final issue = first.issue.trim();
  if (issue.isEmpty) {
    return 'Adjust the $ordinal syllable ($syllableLabel).';
  }
  final lower = issue.toLowerCase();
  if (lower.startsWith('pitch') ||
      lower.startsWith('raise') ||
      lower.startsWith('drop') ||
      lower.startsWith('don')) {
    return 'On the $ordinal syllable ($syllableLabel): $issue.';
  }
  return 'On the $ordinal syllable ($syllableLabel): $issue.';
}

ToneScorerPayload parseToneAnalyzeBody(Map<String, dynamic> body) {
  if (body['code'] == 'pronunciation_unavailable' ||
      body['model'] == 'fallback') {
    return _unscoredTone;
  }

  final errorsRaw = body['errors'];
  final errors = <ToneProductionError>[];
  if (errorsRaw is List) {
    for (final item in errorsRaw) {
      if (item is Map<String, dynamic>) {
        errors.add(ToneProductionError.fromJson(item));
      } else if (item is Map) {
        errors.add(
          ToneProductionError.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
  }

  final accuracy = _finiteNumber(body['accuracy']) ?? _finiteNumber(body['score']);
  final actual = body['actual_pattern'];
  double? confidence;
  if (actual is Map<String, dynamic>) {
    confidence = _finiteNumber(actual['confidence']);
  } else if (actual is Map) {
    confidence = _finiteNumber(actual['confidence']);
  }
  confidence ??= _finiteNumber(body['confidence']);

  final summary = body['feedback'] as String? ?? body['tone_feedback'] as String?;

  if (accuracy == null && confidence == null && errors.isEmpty && summary == null) {
    return _unscoredTone;
  }

  if (accuracy == null || confidence == null) {
    return ToneScorerPayload(
      available: false,
      accuracy: accuracy,
      confidence: confidence,
      errors: errors,
      summaryFeedback: summary,
    );
  }

  return ToneScorerPayload(
    available: true,
    accuracy: accuracy,
    confidence: confidence,
    errors: errors,
    summaryFeedback: summary,
  );
}

/// Grades a tone production attempt (AC2: low confidence → unsure, no number).
ToneProductionGrade gradeToneProduction(ToneScorerPayload payload) {
  if (!payload.available ||
      !_unitInterval(payload.accuracy) ||
      !_unitInterval(payload.confidence)) {
    return ToneProductionGrade(
      phase: ToneProductionPhase.unsure,
      actionableFeedback: ToneProductionCopyKeys.defaultUnsure,
      accuracy: null,
      confidence: payload.confidence,
    );
  }
  if (payload.confidence! < speakingLowConfidence) {
    return ToneProductionGrade(
      phase: ToneProductionPhase.unsure,
      actionableFeedback: ToneProductionCopyKeys.defaultUnsure,
      accuracy: null,
      confidence: payload.confidence,
    );
  }
  return ToneProductionGrade(
    phase: ToneProductionPhase.feedback,
    actionableFeedback: buildActionableFeedback(
      errors: payload.errors,
      summaryFeedback: payload.summaryFeedback,
    ),
    accuracy: payload.accuracy,
    confidence: payload.confidence,
  );
}

abstract class ToneProductionScorer {
  Future<ToneScorerPayload> score({
    required String audioPath,
    required String expectedText,
    required String languageCode,
  });
}

/// Posts learner audio to `/api/voice/pronunciation/tone` (real scorer contract).
class HttpToneProductionScorer implements ToneProductionScorer {
  HttpToneProductionScorer(this._dio);

  final Dio _dio;

  static final String _tonePath = ApiContract.pronunciation.tone;

  @override
  Future<ToneScorerPayload> score({
    required String audioPath,
    required String expectedText,
    required String languageCode,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath),
        'expected_text': expectedText,
        'language': languageCode,
      });
      final response = await _dio.post<Object>(
        _tonePath,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
          receiveTimeout: speakingScorerTimeout,
          sendTimeout: speakingScorerTimeout,
          validateStatus: (status) => status != null,
        ),
      );
      if (response.statusCode != 200) return _unscoredTone;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return parseToneAnalyzeBody(data);
      }
      if (data is Map) {
        return parseToneAnalyzeBody(Map<String, dynamic>.from(data));
      }
      if (data is String && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return parseToneAnalyzeBody(decoded);
        }
      }
      return _unscoredTone;
    } catch (_) {
      return _unscoredTone;
    }
  }
}

Future<ToneProductionGrade> scoreToneProductionAttempt({
  required ToneProductionScorer scorer,
  required String audioPath,
  required ToneProductionSpec spec,
}) async {
  final payload = await scorer.score(
    audioPath: audioPath,
    expectedText: spec.targetForm,
    languageCode: spec.languageCode,
  );
  return gradeToneProduction(payload);
}

/// Production drill UI: record → score → specific feedback or unsure (retry).
class ToneProductionDrillScreen extends StatefulWidget {
  const ToneProductionDrillScreen({
    super.key,
    required this.spec,
    required this.scorer,
    required this.audioPath,
    this.onRecord,
    this.feedbackPrompt = ToneProductionCopyKeys.defaultFeedback,
    this.unsurePrompt = ToneProductionCopyKeys.defaultUnsure,
    this.onGraded,
  });

  final ToneProductionSpec spec;
  final ToneProductionScorer scorer;
  final String audioPath;
  final Future<void> Function()? onRecord;
  final String feedbackPrompt;
  final String unsurePrompt;
  final void Function(ToneProductionGrade grade)? onGraded;

  @override
  State<ToneProductionDrillScreen> createState() =>
      _ToneProductionDrillScreenState();
}

class _ToneProductionDrillScreenState extends State<ToneProductionDrillScreen> {
  ToneProductionPhase _phase = ToneProductionPhase.recording;
  ToneProductionGrade? _grade;

  Future<void> _submitTake() async {
    setState(() => _phase = ToneProductionPhase.scoring);
    final grade = await scoreToneProductionAttempt(
      scorer: widget.scorer,
      audioPath: widget.audioPath,
      spec: widget.spec,
    );
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
    widget.onGraded?.call(grade);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge;

    return Semantics(
      label: widget.spec.promptGlossEn,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.spec.promptGlossEn, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                widget.spec.targetForm,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (_phase == ToneProductionPhase.recording) ...[
                Text(
                  ToneProductionCopyKeys.defaultRecord,
                  style: body,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      await widget.onRecord?.call();
                      await _submitTake();
                    },
                    child: Text(ToneProductionCopyKeys.record),
                  ),
                ),
              ],
              if (_phase == ToneProductionPhase.scoring)
                const Center(child: CircularProgressIndicator()),
              if (_phase == ToneProductionPhase.feedback && _grade != null) ...[
                Semantics(
                  label: ToneProductionCopyKeys.feedback,
                  child: Text(
                    _grade!.actionableFeedback,
                    style: body,
                  ),
                ),
                if (_grade!.accuracy != null)
                  Text(
                    'Accuracy ${(100 * _grade!.accuracy!).round()}%',
                    style: body,
                  ),
              ],
              if (_phase == ToneProductionPhase.unsure) ...[
                Semantics(
                  label: ToneProductionCopyKeys.unsure,
                  child: Text(widget.unsurePrompt, style: body),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _phase = ToneProductionPhase.recording;
                        _grade = null;
                      });
                    },
                    child: Text(ToneProductionCopyKeys.retry),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ensures tone trainer is only offered when P5-027 model exists.
void assertToneProductionAllowed(
  ToneModelsCatalog catalog,
  String languageCode,
) {
  if (!isToneTrainerAvailable(catalog, languageCode)) {
    throw ToneModelMissing(languageCode, 'tone production gated');
  }
}
