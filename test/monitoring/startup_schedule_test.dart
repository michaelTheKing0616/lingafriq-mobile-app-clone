import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/monitoring/startup_schedule.dart';

void main() {
  test('sentry finishes before parallel work, and deferred work waits for the frame', () async {
    final trace = StartupTrace();
    Future<void> Function() deferred = () async {};
    await runStartup(
      sentry: () async {},
      parallel: {
        'database': () async {},
        'firebase': () async {},
      },
      deferred: {
        'offline': () async {},
      },
      onFirstFrame: (task) => deferred = task,
      trace: trace,
    );

    final events = trace.events;
    expect(events.indexOf('end:sentry'), lessThan(events.indexOf('start:database')));
    expect(events.indexOf('end:sentry'), lessThan(events.indexOf('start:firebase')));
    expect(events.indexOf('start:database'), lessThan(events.indexOf('end:firebase')));
    expect(events.indexOf('start:firebase'), lessThan(events.indexOf('end:database')));
    expect(events, isNot(contains('start:offline')));

    await deferred();
    expect(trace.events, contains('end:offline'));
  });

  test('ten samples under two seconds pass and a two-second sample does not', () {
    final fast = List<Duration>.filled(10, const Duration(milliseconds: 1500));
    expect(coldStartMeetsBudget(fast), isTrue);
    final slow = [...fast]..[9] = coldStartBudget;
    expect(coldStartMeetsBudget(slow), isFalse);
    expect(coldStartMeetsBudget(fast.take(9).toList()), isFalse);
  });

  test('the splash screen has no 1.2 second delay', () {
    final source = File('lib/screens/splash/splash_screen_material3.dart').readAsStringSync();
    expect(source, isNot(contains('Duration(milliseconds: 1200)')));
  });
}