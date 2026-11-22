import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/models/onboarding_state.dart';

/// Persists each completed onboarding step as typed JSON.
///
/// The payload is [jsonEncode] of [OnboardingState]. A missing field or a
/// corrupt payload is [OnboardingStateException], not a guessed step.
class OnboardingStateService {
  OnboardingStateService(this._prefs);

  /// Separate from `onboarding_data`, which startup clears before the flow
  /// is finished. This key is the step resume record.
  static const String storageKey = 'onboarding_step_state';

  final SharedPreferences _prefs;

  OnboardingStateRead read() => readPayload(_prefs.getString(storageKey));

  /// Reads a previously written payload. Null means nothing was saved.
  /// An empty or unreadable payload is an error.
  static OnboardingStateRead readPayload(String? raw) {
    if (raw == null) return const OnboardingStateRead.fresh();
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return OnboardingStateRead.failed(OnboardingStateException.unreadable());
    }
    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (error) {
      return OnboardingStateRead.failed(
        OnboardingStateException.unreadable(cause: error),
      );
    }
    if (decoded is! Map) {
      return OnboardingStateRead.failed(
        OnboardingStateException.unreadable(
          cause: 'onboarding JSON was not an object',
        ),
      );
    }
    final map = Map<Object?, Object?>.from(decoded);
    if (!map.containsKey('resume_step') || !map.containsKey('steps')) {
      return OnboardingStateRead.failed(OnboardingStateException.unreadable());
    }
    final stepValue = map['resume_step'];
    final stepsRaw = map['steps'];
    if (stepValue is! int || stepValue < 1 || stepsRaw is! Map) {
      return OnboardingStateRead.failed(OnboardingStateException.unreadable());
    }
    final steps = Map<Object?, Object?>.from(stepsRaw);
    final answersByStep = <int, Map<String, Object?>>{};
    for (final key in steps.keys) {
      final parsed = int.tryParse('$key');
      if (parsed == null ||
          '$parsed' != key ||
          parsed < 1 ||
          parsed > stepValue) {
        return OnboardingStateRead.failed(
          OnboardingStateException.unreadable(),
        );
      }
    }
    for (var step = 1; step <= stepValue; step += 1) {
      if (!steps.containsKey('$step')) {
        return OnboardingStateRead.failed(
          OnboardingStateException.unreadable(),
        );
      }
      final body = steps['$step'];
      if (body is! Map) {
        return OnboardingStateRead.failed(
          OnboardingStateException.unreadable(),
        );
      }
      final copied = _copyAnswer(Map<Object?, Object?>.from(body));
      if (copied == null) {
        return OnboardingStateRead.failed(
          OnboardingStateException.unreadable(),
        );
      }
      answersByStep[step] = copied;
    }
    return OnboardingStateRead.saved(
      OnboardingState(resumeStep: stepValue, answersByStep: answersByStep),
    );
  }

  /// Saves [answer] for [step] and moves the resume point there when [step]
  /// is the next step. Does not invent earlier answers.
  ///
  /// [replace] starts a new record at step 1. The screen sets it after an
  /// unreadable save so the next answer is not merged into a bad payload.
  Future<OnboardingStateRead> saveStep({
    required int step,
    required Map<String, dynamic> answer,
    bool replace = false,
  }) async {
    if (step < 1) {
      return OnboardingStateRead.failed(OnboardingStateException.unreadable());
    }
    final typed = _copyAnswer(Map<Object?, Object?>.from(answer));
    if (typed == null) {
      return OnboardingStateRead.failed(OnboardingStateException.unreadable());
    }
    if (replace) {
      if (step != 1) {
        return OnboardingStateRead.failed(
          OnboardingStateException.unreadable(),
        );
      }
      final fresh = OnboardingState(resumeStep: 1, answersByStep: {1: typed});
      await _write(fresh);
      return OnboardingStateRead.saved(fresh);
    }
    final current = read();
    if (current.error != null) {
      if (step != 1) return current;
      final fresh = OnboardingState(resumeStep: 1, answersByStep: {1: typed});
      await _write(fresh);
      return OnboardingStateRead.saved(fresh);
    }
    if (current.state == null) {
      if (step != 1) {
        return OnboardingStateRead.failed(
          OnboardingStateException.unreadable(),
        );
      }
      final fresh = OnboardingState(resumeStep: 1, answersByStep: {1: typed});
      await _write(fresh);
      return OnboardingStateRead.saved(fresh);
    }
    final previous = current.state!;
    if (step > previous.resumeStep + 1) {
      return OnboardingStateRead.failed(OnboardingStateException.unreadable());
    }
    final nextAnswers = <int, Map<String, Object?>>{
      for (var index = 1; index <= previous.resumeStep; index += 1)
        index: Map<String, Object?>.from(previous.answersByStep[index]!),
    };
    nextAnswers[step] = typed;
    final resume = step > previous.resumeStep ? step : previous.resumeStep;
    final next = OnboardingState(
      resumeStep: resume,
      answersByStep: nextAnswers,
    );
    await _write(next);
    return OnboardingStateRead.saved(next);
  }

  Future<void> _write(OnboardingState state) {
    return _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }
}

/// Opens [loaded] on its saved step, or restarts at step 1 when the save
/// cannot be read or does not fit [stepCount].
OnboardingResume placeOnboardingResume(
  OnboardingStateRead loaded, {
  required int stepCount,
}) {
  final error = loaded.error;
  final state = loaded.state;
  if (error != null || state == null) {
    return OnboardingResume(
      step: 1,
      pageIndex: 0,
      answers: const {},
      error: error,
    );
  }
  if (stepCount < 1 || state.resumeStep > stepCount) {
    return OnboardingResume(
      step: 1,
      pageIndex: 0,
      answers: const {},
      error: OnboardingStateException.unreadable(),
    );
  }
  return OnboardingResume(
    step: state.resumeStep,
    pageIndex: state.resumeStep - 1,
    answers: state.mergedAnswers(),
  );
}

Map<String, Object?>? _copyAnswer(Map<Object?, Object?> raw) {
  final out = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String || key.isEmpty) return null;
    if (entry.value == null) continue;
    final copied = _copyJsonValue(entry.value);
    if (copied == null) return null;
    out[key] = copied;
  }
  return out;
}

Object? _copyJsonValue(Object? value) {
  if (value == null) return null;
  if (value is String || value is bool || value is int) return value;
  if (value is double) {
    if (!value.isFinite) return null;
    return value;
  }
  if (value is List) {
    final items = <Object?>[];
    for (final item in value) {
      if (item == null) return null;
      final copied = _copyJsonValue(item);
      if (copied == null) return null;
      items.add(copied);
    }
    if (items.every((item) => item is String)) {
      return List<String>.from(items);
    }
    return items;
  }
  if (value is Map) {
    return _copyAnswer(Map<Object?, Object?>.from(value));
  }
  return null;
}
