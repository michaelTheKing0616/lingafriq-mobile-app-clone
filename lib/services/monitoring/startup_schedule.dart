/// Cold start to the first meaningful frame. Ten profile runs must each be under this.
const Duration coldStartBudget = Duration(milliseconds: 2000);

bool coldStartMeetsBudget(List<Duration> samples) {
  if (samples.length != 10) return false;
  return samples.every((sample) => sample < coldStartBudget);
}

class StartupTrace {
  final List<String> events = [];

  void start(String name) => events.add('start:$name');

  void end(String name) => events.add('end:$name');
}

/// Sentry finishes before the parallel tasks start.
/// Deferred tasks run only when [onFirstFrame] invokes its callback.
Future<void> runStartup({
  required Future<void> Function() sentry,
  required Map<String, Future<void> Function()> parallel,
  required Map<String, Future<void> Function()> deferred,
  required void Function(Future<void> Function() task) onFirstFrame,
  StartupTrace? trace,
}) async {
  final log = trace ?? StartupTrace();
  log.start('sentry');
  await sentry();
  log.end('sentry');
  await Future.wait(parallel.entries.map((entry) async {
    log.start(entry.key);
    await entry.value();
    log.end(entry.key);
  }));
  onFirstFrame(() async {
    for (final entry in deferred.entries) {
      log.start(entry.key);
      await entry.value();
      log.end(entry.key);
    }
  });
}
