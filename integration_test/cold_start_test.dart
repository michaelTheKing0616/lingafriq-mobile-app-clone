// P12-012: cold-start gate harness (device lab + CI self-test via trace script).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingafriq/services/monitoring/startup_schedule.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final repo = Directory.current;
  final traceScript = repo.uri.resolve('scripts/perf/cold_start_trace.sh');

  group('P12-012 cold_start_trace.sh', () {
    test('self-test parses samples and median gate', () async {
      final proc = await Process.run(
        'bash',
        [traceScript.toFilePath(), '--self-test'],
        workingDirectory: repo.path,
      );
      expect(proc.exitCode, 0, reason: '${proc.stdout}\n${proc.stderr}');
      final report =
          jsonDecode(proc.stdout as String) as Map<String, dynamic>;
      expect(report['mode'], 'self-test');
      expect(report['median_meaningful_frame_ms'] as int, lessThan(2000));
    });

    test('missing reference device fails loud as Blocked', () async {
      final proc = await Process.run(
        'bash',
        [traceScript.toFilePath(), '--require-device'],
        workingDirectory: repo.path,
        environment: {
          ...Platform.environment,
          'COLD_START_FORCE_NO_DEVICE': '1',
        },
      );
      expect(proc.exitCode, 3);
      expect(proc.stderr.toString(), contains('Blocked'));
    });
  });

  test('median of ten under budget matches startup_schedule helper', () {
    final samples = List<Duration>.filled(
      10,
      const Duration(milliseconds: 1800),
    );
    expect(coldStartMeetsBudget(samples), isTrue);
    final medianMs = _medianMs(samples.map((d) => d.inMilliseconds).toList());
    expect(medianMs, lessThan(coldStartBudget.inMilliseconds));
  });
}

int _medianMs(List<int> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}
