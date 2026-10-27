/// P7-930 micro-lesson content model (learn → see → try).
library;

/// L10n copy keys from card ux_spec.
abstract final class MicroLessonCopyKeys {
  static const learn = 'tutorial.learn';
  static const see = 'tutorial.see';
  static const tryStep = 'tutorial.try';
}

enum MicroLessonStepKind {
  learn,
  see,
  tryStep,
}

extension MicroLessonStepKindX on MicroLessonStepKind {
  String get copyKey {
    switch (this) {
      case MicroLessonStepKind.learn:
        return MicroLessonCopyKeys.learn;
      case MicroLessonStepKind.see:
        return MicroLessonCopyKeys.see;
      case MicroLessonStepKind.tryStep:
        return MicroLessonCopyKeys.tryStep;
    }
  }

  String get defaultTitle {
    switch (this) {
      case MicroLessonStepKind.learn:
        return 'Learn it';
      case MicroLessonStepKind.see:
        return 'See it';
      case MicroLessonStepKind.tryStep:
        return 'Try it';
    }
  }

  int get index => MicroLessonStepKind.values.indexOf(this);
}

class MicroLessonStepContent {
  const MicroLessonStepContent({
    required this.kind,
    required this.body,
    required this.durationSeconds,
    this.mediaUri,
    this.mediaKind = MicroLessonMediaKind.none,
  });

  final MicroLessonStepKind kind;
  final String body;
  final int durationSeconds;
  final String? mediaUri;
  final MicroLessonMediaKind mediaKind;

  Duration get duration => Duration(seconds: durationSeconds);
}

enum MicroLessonMediaKind { none, image, video, audio }

class MicroLesson {
  const MicroLesson({
    required this.id,
    required this.steps,
  });

  final String id;
  final List<MicroLessonStepContent> steps;

  Duration get totalRuntime {
    var total = Duration.zero;
    for (final step in steps) {
      total += step.duration;
    }
    return total;
  }
}

/// Thrown when tutorial content fails validation before playback.
class MicroLessonContentException implements Exception {
  MicroLessonContentException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => 'MicroLessonContentException($code${detail == null ? '' : ': $detail'})';
}

abstract final class MicroLessonContentCodes {
  static const invalidStepOrder = 'INVALID_STEP_ORDER';
  static const runtimeOutOfRange = 'RUNTIME_OUT_OF_RANGE';
  static const stepCount = 'STEP_COUNT';
}

const Duration kMicroLessonMinRuntime = Duration(seconds: 60);
const Duration kMicroLessonMaxRuntime = Duration(seconds: 90);

const List<MicroLessonStepKind> kMicroLessonStepOrder = [
  MicroLessonStepKind.learn,
  MicroLessonStepKind.see,
  MicroLessonStepKind.tryStep,
];

bool microLessonStepOrderIsValid(List<MicroLessonStepContent> steps) {
  if (steps.length != kMicroLessonStepOrder.length) return false;
  for (var i = 0; i < kMicroLessonStepOrder.length; i++) {
    if (steps[i].kind != kMicroLessonStepOrder[i]) return false;
  }
  return true;
}

bool microLessonRuntimeInRange(Duration total) {
  return !total.isNegative &&
      total.compareTo(kMicroLessonMinRuntime) >= 0 &&
      total.compareTo(kMicroLessonMaxRuntime) <= 0;
}

void assertMicroLessonContentValid(MicroLesson lesson) {
  if (lesson.steps.length != 3) {
    throw MicroLessonContentException(
      MicroLessonContentCodes.stepCount,
      'expected 3 steps, got ${lesson.steps.length}',
    );
  }
  if (!microLessonStepOrderIsValid(lesson.steps)) {
    throw MicroLessonContentException(MicroLessonContentCodes.invalidStepOrder);
  }
  final total = lesson.totalRuntime;
  if (!microLessonRuntimeInRange(total)) {
    throw MicroLessonContentException(
      MicroLessonContentCodes.runtimeOutOfRange,
      '${total.inSeconds}s',
    );
  }
}

/// Visible media failure for a step (AC4).
class MicroLessonMediaException implements Exception {
  MicroLessonMediaException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => 'MicroLessonMediaException($code${detail == null ? '' : ': $detail'})';
}

abstract final class MicroLessonMediaCodes {
  static const missing = 'MEDIA_MISSING';
  static const loadFailed = 'MEDIA_LOAD_FAILED';
}
