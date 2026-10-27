import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learner/lesson_pacing.dart';

void main() {
  const fixture = <LearnerTraceDay>[
    LearnerTraceDay(completed: true, retained: true, successRate: 0.62),
    LearnerTraceDay(completed: false, retained: false, successRate: 0.55),
    LearnerTraceDay(completed: true, retained: true, successRate: 0.7),
    LearnerTraceDay(completed: true, retained: false, successRate: 0.78),
    LearnerTraceDay(completed: false, retained: false, successRate: 0.5),
    LearnerTraceDay(completed: true, retained: true, successRate: 0.88),
    LearnerTraceDay(completed: true, retained: true, successRate: 0.6),
  ];

  test('adaptive replay beats fixed on retention and completion', () {
    PacingReplayHarness.assertAdaptiveBeatsFixed(fixture);
    final fixed = PacingReplayHarness.replayFixed(fixture);
    final adaptive = PacingReplayHarness.replayAdaptive(fixture);
    expect(adaptive.completionRate, greaterThan(fixed.completionRate));
    expect(adaptive.retentionRate, greaterThan(fixed.retentionRate));
  });
}
