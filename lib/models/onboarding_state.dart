import 'dart:convert';

/// One saved onboarding position and the answers the learner actually gave.
///
/// Steps are 1-based. [resumeStep] is the last step whose answer was saved.
/// A later read resumes at that step. Missing keys are not filled in.
class OnboardingState {
  OnboardingState({
    required this.resumeStep,
    required Map<int, Map<String, Object?>> answersByStep,
  }) : answersByStep = Map.unmodifiable({
         for (final entry in answersByStep.entries)
           entry.key: Map<String, Object?>.unmodifiable(
             Map<String, Object?>.from(entry.value),
           ),
       });

  /// Last completed step, starting at 1.
  final int resumeStep;

  /// Answers keyed by the step that saved them. Only steps 1 through
  /// [resumeStep] are present.
  final Map<int, Map<String, Object?>> answersByStep;

  /// Answers in step order. A later step replaces the same key. Keys the
  /// learner never saved are absent.
  Map<String, Object?> mergedAnswers() {
    final merged = <String, Object?>{};
    for (var step = 1; step <= resumeStep; step += 1) {
      final saved = answersByStep[step];
      if (saved == null) {
        throw OnboardingStateException.unreadable();
      }
      merged.addAll(saved);
    }
    return merged;
  }

  Map<String, Object?> toJson() {
    final steps = <String, Map<String, Object?>>{};
    for (var step = 1; step <= resumeStep; step += 1) {
      final saved = answersByStep[step];
      if (saved == null) {
        throw OnboardingStateException.unreadable();
      }
      steps['$step'] = saved;
    }
    return {'resume_step': resumeStep, 'steps': steps};
  }

  String encode() => jsonEncode(toJson());
}

/// Saved onboarding answers could not be read. The flow restarts at step 1.
class OnboardingStateException implements Exception {
  const OnboardingStateException._({this.cause});

  factory OnboardingStateException.unreadable({Object? cause}) {
    return OnboardingStateException._(cause: cause);
  }

  static const String code = 'onboarding_state_unreadable';

  /// Same sentence as `onboardingTheSavedAnswersCouldNotBeRead` in app_en.arb.
  static const String explanation = 'The saved answers could not be read.';

  final Object? cause;

  @override
  String toString() {
    if (cause == null) return '$code: $explanation';
    return '$code: $explanation ($cause)';
  }
}

/// Result of reading onboarding state. Exactly one of [state] or [error] is
/// set, unless nothing has been saved yet.
class OnboardingStateRead {
  const OnboardingStateRead._({this.state, this.error});

  const OnboardingStateRead.fresh() : this._();

  const OnboardingStateRead.saved(OnboardingState state) : this._(state: state);

  const OnboardingStateRead.failed(OnboardingStateException error)
    : this._(error: error);

  final OnboardingState? state;
  final OnboardingStateException? error;
}

/// Where the onboarding flow should open.
class OnboardingResume {
  const OnboardingResume({
    required this.step,
    required this.pageIndex,
    required this.answers,
    this.error,
  });

  /// 1-based step to show.
  final int step;

  /// Page index for that step. Step 1 is page 0.
  final int pageIndex;

  /// Saved answers only. Empty when the flow restarts or nothing was saved.
  final Map<String, Object?> answers;

  /// Set when a saved payload cannot be used. Null on a fresh start.
  final OnboardingStateException? error;
}
