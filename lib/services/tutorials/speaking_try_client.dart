import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../lens/lens_scoring_client.dart';
import '../../screens/pronunciation/tone_overlay_view.dart';

/// Copy keys: tutorial.try.speak, tutorial.try.skip (P7-932).
const String kTutorialTrySpeakKey = 'tutorial.try.speak';
const String kTutorialTrySkipKey = 'tutorial.try.skip';

const String kTutorialTrySpeakLabel = 'Hold to speak this phrase';
const String kTutorialTrySkipLabel = 'Skip speaking';
const String kTutorialTryUnsureCopy =
    'We could not score this clearly. No score is shown — please try again.';
const String kTutorialTryErrorCopy =
    'Pronunciation scoring is unavailable. Try again when you are back online.';

enum SpeakingTryPhase {
  idle,
  recording,
  result,
  unsure,
  skipped,
  error,
}

enum SpeakingTryCompletion { scored, unsure, error, skipped }

/// Learner-visible result — never includes a fabricated overall numeric score.
class SpeakingTryResult {
  const SpeakingTryResult({
    required this.completion,
    this.syllables = const [],
    this.errorMessage,
    this.retryable = false,
  });

  final SpeakingTryCompletion completion;
  final List<SyllableToneOverlayRow> syllables;
  final String? errorMessage;
  final bool retryable;

  SpeakingTryPhase get phase {
    switch (completion) {
      case SpeakingTryCompletion.scored:
        return SpeakingTryPhase.result;
      case SpeakingTryCompletion.unsure:
        return SpeakingTryPhase.unsure;
      case SpeakingTryCompletion.error:
        return SpeakingTryPhase.error;
      case SpeakingTryCompletion.skipped:
        return SpeakingTryPhase.skipped;
    }
  }
}

/// Maps gateway scorer output to tutorial try semantics (AC2).
SpeakingTryResult speakingTryResultFromLens(LensScoreOutcome lens) {
  switch (lens.phase) {
    case ToneOverlayStatus.unsure:
      return SpeakingTryResult(
        completion: SpeakingTryCompletion.unsure,
        syllables: lens.syllables,
        errorMessage: kTutorialTryUnsureCopy,
      );
    case ToneOverlayStatus.error:
      return SpeakingTryResult(
        completion: SpeakingTryCompletion.error,
        errorMessage: lens.errorMessage ?? kTutorialTryErrorCopy,
        retryable: lens.retryable,
      );
    case ToneOverlayStatus.scored:
      return SpeakingTryResult(
        completion: SpeakingTryCompletion.scored,
        syllables: lens.syllables,
      );
    case ToneOverlayStatus.loading:
      return SpeakingTryResult(
        completion: SpeakingTryCompletion.error,
        errorMessage: kTutorialTryErrorCopy,
      );
  }
}

/// True when UI must not show a numeric pronunciation score (AC2).
bool speakingTryShouldHideNumericScore(SpeakingTryResult result) {
  return result.completion == SpeakingTryCompletion.unsure ||
      result.completion == SpeakingTryCompletion.error ||
      result.completion == SpeakingTryCompletion.skipped;
}

/// Records skip for analytics / lesson progress (AC3).
class SpeakingTrySkipRecord {
  const SpeakingTrySkipRecord({
    required this.stepId,
    required this.skippedAt,
  });

  final String stepId;
  final DateTime skippedAt;

  Map<String, dynamic> toJson() => {
        'step_id': stepId,
        'outcome': 'skipped',
        'skipped_at': skippedAt.toUtc().toIso8601String(),
      };
}

typedef SpeakingTryScorePost = LensScorePost;

/// Posts learner audio to the real gateway scorer for tutorial try steps.
class SpeakingTryClient {
  const SpeakingTryClient({LensScoringClient? lensClient})
      : _lens = lensClient ?? const LensScoringClient();

  final LensScoringClient _lens;

  Future<SpeakingTryResult> scoreAttempt({
    required SpeakingTryScorePost post,
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    final lens = await _lens.scoreUtterance(
      post: post,
      audioPath: audioPath,
      expectedText: expectedText,
      language: language,
    );
    return speakingTryResultFromLens(lens);
  }

  SpeakingTrySkipRecord recordSkip({required String stepId}) {
    return SpeakingTrySkipRecord(
      stepId: stepId,
      skippedAt: DateTime.now().toUtc(),
    );
  }
}

/// Pure helper for tests and UI copy.
String speakingTryAccessibilitySummary(SpeakingTryResult result) {
  if (result.completion == SpeakingTryCompletion.skipped) {
    return 'Speaking step skipped.';
  }
  if (result.completion == SpeakingTryCompletion.unsure) {
    return kTutorialTryUnsureCopy;
  }
  if (result.completion == SpeakingTryCompletion.error) {
    return result.errorMessage ?? kTutorialTryErrorCopy;
  }
  return buildToneOverlayAccessibilitySummary(result.syllables);
}

@visibleForTesting
LensScoreOutcome parseSpeakingTryScoreBody(Map<String, dynamic> body) =>
    parseScoreBody(body);
