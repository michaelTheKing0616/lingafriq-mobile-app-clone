import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/monitoring/crash_reporter.dart';

void main() {
  test('a crash report keeps the release and device and drops the email and token', () async {
    final lines = <String>[];
    final reporter = CrashReporter(
      release: '1.6.2+330',
      device: 'android',
      log: lines.add,
    );

    final report = reporter.report(
      Exception('failed for seeded-person@example.com Bearer SeededTokenValue99'),
      context: {
        'library': 'flutter',
        'email': 'seeded-person@example.com',
        'prompt': 'secret prompt text',
      },
    );

    expect(report['release'], '1.6.2+330');
    expect(report['device'], 'android');
    expect(report['kind'], 'crash');
    final encoded = report.toString();
    expect(encoded, isNot(contains('seeded-person@example.com')));
    expect(encoded, isNot(contains('SeededTokenValue99')));
    expect(encoded, isNot(contains('secret prompt text')));

    final anr = reporter.reportAnr('input dispatch timed out');
    expect(anr['kind'], 'anr');
    expect(anr['release'], '1.6.2+330');

    final started = await reporter.initialize(start: () async {
      throw StateError('dsn refused');
    });
    expect(started, isFalse);
    expect(reporter.diagnostic, 'crash reporter failed to start');
    expect(lines.single, contains('crash reporter failed to start'));
  });
}
