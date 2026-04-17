// Counts string-literal `Text(` usages under lib/ to prevent unbounded growth of
// non-localized UI copy. Full ARB migration is incremental; this gate blocks
// regressions. Bump `tool/i18n_gate_baseline.txt` only with deliberate review.
//
// Usage:
//   dart run tool/i18n_gate.dart              — fail if count > baseline
//   dart run tool/i18n_gate.dart --write-baseline — set baseline to current count

import 'dart:io';

int countTextLiterals() {
  // Match `Text('...` or `Text("...` (common non-localized pattern).
  final pattern = RegExp(r'\bText\s*\(\s*[\u0027\u0022]');
  var count = 0;
  void walk(Directory dir) {
    for (final e in dir.listSync(recursive: false)) {
      if (e is Directory) {
        final name = e.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
        if (name == 'generated') continue;
        walk(e);
      } else if (e is File && e.path.endsWith('.dart')) {
        final rel = e.path.replaceAll('\\', '/');
        if (rel.contains('/generated/') || rel.endsWith('.g.dart')) {
          continue;
        }
        final content = e.readAsStringSync();
        count += pattern.allMatches(content).length;
      }
    }
  }

  walk(Directory('lib'));
  return count;
}

extension _LastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}

void main(List<String> args) {
  final write = args.contains('--write-baseline');
  final baselineFile = File('tool/i18n_gate_baseline.txt');
  final count = countTextLiterals();

  if (write) {
    baselineFile.writeAsStringSync('$count\n');
    stdout.writeln('i18n gate: wrote baseline $count to ${baselineFile.path}');
    return;
  }

  if (!baselineFile.existsSync()) {
    stderr.writeln(
      'Missing ${baselineFile.path}. Run: dart run tool/i18n_gate.dart --write-baseline',
    );
    exit(1);
  }
  final baseline = int.parse(baselineFile.readAsStringSync().trim());
  stdout.writeln('i18n gate: $count Text("…") / Text(\'…\') literals (baseline $baseline)');

  if (count > baseline) {
    stderr.writeln(
      'FAIL: literal Text() count $count exceeds baseline $baseline. '
      'Add strings to ARB and use AppLocalizations, or raise the baseline with review.',
    );
    exit(1);
  }
}
