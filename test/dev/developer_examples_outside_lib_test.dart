import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/app_repo_root.dart';

/// P3-071: developer artefacts stay under dev/ so a release compile of lib/
/// cannot include them.
const _exampleNames = <String>[
  'errorhandler_integration_example.dart',
  'performance_utilities_example.dart',
  'polie_tsx_flutter_mapping.dart',
];

final _devExamplesImport = RegExp(
  r'''^\s*(?:import|export|part)\s+['"][^'"]*dev/examples''',
  multiLine: true,
);

void main() {
  final repoRoot = appRepoRoot();

  test('the three developer examples live under dev/examples and not under lib/', () {
    final missing = <String>[];
    for (final name in _exampleNames) {
      final path = p.join(repoRoot, 'dev', 'examples', name);
      if (!File(path).existsSync()) missing.add('dev/examples/$name');
    }
    expect(missing, isEmpty, reason: 'examples must live under dev/examples');

    final stillInLib = <String>[];
    final libDir = Directory(p.join(repoRoot, 'lib'));
    expect(libDir.existsSync(), isTrue);
    for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (_exampleNames.contains(p.basename(entity.path))) {
        stillInLib.add(p.relative(entity.path, from: repoRoot));
      }
    }
    expect(stillInLib, isEmpty, reason: 'release lib/ must not contain the example files');
  });

  test('lib/ does not import dev/examples', () {
    final hits = <String>[];
    final libDir = Directory(p.join(repoRoot, 'lib'));
    for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (_devExamplesImport.hasMatch(text)) {
        hits.add(p.relative(entity.path, from: repoRoot));
      }
    }
    expect(hits, isEmpty, reason: 'a release compile follows lib/ imports only');
  });
}
