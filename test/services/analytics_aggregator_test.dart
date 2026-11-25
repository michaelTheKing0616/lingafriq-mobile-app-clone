import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/analytics_aggregator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rollup math sums exercise and speech counters', () {
    final rollup = DailyLearningRollup(utcDayKey: '2026-10-27');
    rollup.ingestEnvelope({
      'event_name': 'exercise_answered',
      'metrics': {'correct': true, 'latency_ms': 100, 'hints': 1},
    });
    rollup.ingestEnvelope({
      'event_name': 'exercise_answered',
      'metrics': {'correct': false, 'latency_ms': 50, 'hints': 0},
    });
    rollup.ingestEnvelope({
      'event_name': 'speech_attempt_scored',
      'metrics': {'unsure': true},
    });

    final m = rollup.toRollupMetrics();
    expect(m['exercise_count'], 2);
    expect(m['exercise_correct_count'], 1);
    expect(m['exercise_latency_ms_sum'], 150);
    expect(m['speech_unsure_count'], 1);
    expect(m['daily_rollup'], isTrue);
  });

  test('day rollover returns completed rollup and starts fresh bucket', () async {
    var now = DateTime.utc(2026, 10, 27, 10);
    final agg = LearningAnalyticsAggregator(
      loadPrefs: SharedPreferences.getInstance,
      now: () => now,
    );

    await agg.record({
      'event_name': 'session_started',
      'metrics': <String, Object?>{},
    });

    now = DateTime.utc(2026, 10, 28, 9);
    final completed = await agg.record({
      'event_name': 'exercise_answered',
      'metrics': {'correct': true, 'latency_ms': 10, 'hints': 0},
    });

    expect(completed, isNotNull);
    expect(completed!.utcDayKey, '2026-10-27');
    expect(completed.sessionStartedCount, 1);
    expect(completed.exerciseCount, 0);

    final open = await agg.loadedOpenDay();
    expect(open!.utcDayKey, '2026-10-28');
    expect(open.exerciseCount, 1);
  });

  test('rollup envelope has no item text or account fields', () {
    final agg = LearningAnalyticsAggregator();
    final rollup = DailyLearningRollup(utcDayKey: '2026-10-27');
    rollup.exerciseCount = 3;
    final env = agg.rollupEnvelope(
      rollup: rollup,
      pseudonymousUserId: 'psn_${'a' * 32}',
      context: {'platform': 'ios'},
    );
    expect(env['event_name'], 'offline_operation');
    expect(env.containsKey('item_id'), isFalse);
    expect(env.containsKey('transcript'), isFalse);
    final metrics = env['metrics'] as Map<String, Object?>;
    expect(metrics['daily_rollup'], isTrue);
    expect(metrics['exercise_count'], 3);
  });
}
