// P1-029 Spec-Tests (Mode A): AC1, AC2, AC3. Derived from acceptance criteria only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _linter = 'scripts/ci/placeholder_linter.py';
const _fixtures = 'test/content/fixtures/p1_029';

ProcessResult _lint(String path) =>
    Process.runSync('python3', [_linter, path]);

/// Directories declared under `flutter: assets:` in pubspec.yaml.
List<String> _pubspecAssetDirs() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final start = lines.indexWhere((l) => l.trim() == 'assets:');
  final dirs = <String>[];
  for (var i = start + 1; i < lines.length; i++) {
    final m = RegExp(r'^\s+-\s+(\S+)\s*$').firstMatch(lines[i]);
    if (m == null) break;
    dirs.add(m.group(1)!);
  }
  return dirs;
}

void main() {
  test('P1-029_AC1_release_bundle_excludes_linter_flagged_bundles', () {
    expect(File(_linter).existsSync(), isTrue,
        reason: '$_linter must exist to identify placeholder bundles');
    final jsonDirs = _pubspecAssetDirs().where((d) {
      final dir = Directory(d);
      return dir.existsSync() &&
          dir
              .listSync(recursive: true)
              .any((e) => e is File && e.path.endsWith('.json'));
    }).toList();
    expect(jsonDirs, isNotEmpty);
    final flagged = <String>[];
    for (final d in jsonDirs) {
      final r = _lint(d);
      if (r.exitCode != 0) flagged.add(d);
    }
    expect(flagged, isEmpty,
        reason: 'pubspec bundles the linter flags as placeholder/template');
  });

  test('P1-029_AC1_linter_flags_legacy_template_bundles', () {
    for (final legacy in const [
      'curriculum_bundle',
      'lingafriq_FINAL_curriculum',
      'lingafriq_full_curriculum_bundle',
    ]) {
      final r = _lint(legacy);
      expect(r.exitCode, isNot(0),
          reason: '$legacy must be flagged: ${r.stdout}\n${r.stderr}');
    }
    for (final shipped in const ['assets/data', 'schemas/v2']) {
      final r = _lint(shipped);
      expect(r.exitCode, 0,
          reason: '$shipped must be clean: ${r.stdout}\n${r.stderr}');
    }
  });

  test('P1-029_AC2_linter_fails_and_lists_placeholder_files', () {
    final r = _lint('$_fixtures/placeholder');
    final out = '${r.stdout}\n${r.stderr}';
    expect(r.exitCode, isNot(0), reason: out);
    expect(out, contains('lesson_placeholder.json'));
  });

  test('P1-029_AC2_linter_passes_and_omits_clean_files', () {
    final r = _lint('$_fixtures/clean');
    final out = '${r.stdout}\n${r.stderr}';
    expect(r.exitCode, 0, reason: out);
    expect(out, isNot(contains('lesson_clean.json')));
  });

  group('P1-029_AC2_linter_cli_paths', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('p1_029_lint_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('P1-029_AC2_no_args_prints_usage_and_exits_2', () {
      final r = Process.runSync('python3', [_linter]);
      expect(r.exitCode, 2);
      expect('${r.stderr}', contains('usage'));
    });

    test('P1-029_AC2_missing_path_exits_2_and_names_path', () {
      final missing = '${tmp.path}/does_not_exist';
      final r = _lint(missing);
      expect(r.exitCode, 2);
      expect('${r.stderr}', contains('path not found'));
      expect('${r.stderr}', contains(missing));
    });

    test('P1-029_AC2_non_utf8_content_file_exits_2_as_unreadable', () {
      final f = File('${tmp.path}/bad.json')
        ..writeAsBytesSync([0xff, 0xfe, 0xfa, 0x80]);
      final r = _lint(tmp.path);
      expect(r.exitCode, 2);
      expect('${r.stderr}', contains('cannot read'));
      expect('${r.stderr}', contains(f.path));
    });

    test('P1-029_AC2_single_clean_content_file_exits_0', () {
      final f = File('${tmp.path}/ok.json')
        ..writeAsStringSync('{"word":"ẹ kú àárọ̀","meaning":"good morning"}');
      expect(_lint(f.path).exitCode, 0);
    });

    test('P1-029_AC2_single_placeholder_file_exits_1_and_is_listed', () {
      final f = File('${tmp.path}/bad.md')..writeAsStringSync('Lorem ipsum dolor');
      final r = _lint(f.path);
      expect(r.exitCode, 1);
      expect('${r.stderr}', contains(f.path));
      expect('${r.stderr}', contains('lorem ipsum'));
    });

    test('P1-029_AC2_single_non_content_file_is_ignored', () {
      final f = File('${tmp.path}/notes.bin')..writeAsStringSync('TODO lorem ipsum');
      expect(_lint(f.path).exitCode, 0);
    });
  });

  test('P1-029_AC2_build_workflow_runs_placeholder_linter', () {
    for (final path in const [
      '.github/workflows/build-and-release.yml',
      '.github/workflows/build-sideload-apk.yml',
    ]) {
      final wf = File(path).readAsStringSync();
      expect(wf, contains('placeholder_linter.py'), reason: path);
    }

    const assetsCmd = 'python3 scripts/ci/placeholder_linter.py assets/data';
    const schemasCmd = 'python3 scripts/ci/placeholder_linter.py schemas/v2';
    const expectedCounts = {
      '.github/workflows/build-and-release.yml': 2,
      '.github/workflows/build-sideload-apk.yml': 1,
    };
    for (final entry in expectedCounts.entries) {
      final wf = File(entry.key).readAsStringSync();
      expect(assetsCmd.allMatches(wf).length, entry.value,
          reason: '${entry.key}: $assetsCmd');
      expect(schemasCmd.allMatches(wf).length, entry.value,
          reason: '${entry.key}: $schemasCmd');
    }
  });

  test('P1-029_AC3_marketing_claims_freeze_lists_frozen_claims', () {
    final f = File('docs/build/MARKETING_CLAIMS_FREEZE.md');
    expect(f.existsSync(), isTrue);
    final text = f.readAsStringSync();
    final lower = text.toLowerCase();
    expect(text, startsWith('charter: v2'));
    expect(lower, contains('frozen until content is verified'));
    final claimRows = text.split('\n').where((l) {
      final t = l.toLowerCase();
      return RegExp(r'^\s*(\||-|\*)').hasMatch(l) &&
          RegExp(r'\d').hasMatch(l) &&
          (t.contains('lesson') || t.contains('language'));
    }).toList();
    expect(claimRows.any((l) => l.toLowerCase().contains('lesson')), isTrue,
        reason: 'needs a frozen lesson-count claim');
    expect(claimRows.any((l) => l.toLowerCase().contains('language')), isTrue,
        reason: 'needs a frozen language-count claim');
    for (final required in const [
      'authentic_curriculum_entry_screen.dart',
      'onboarding_screen.dart',
      'modern_onboarding_screen.dart',
      '2000',
    ]) {
      expect(text, contains(required), reason: 'freeze doc must list $required');
    }
    expect(
        claimRows.any((l) =>
            RegExp(r'(?<![\d,])14(?![\d,])').hasMatch(l) &&
            l.toLowerCase().contains('language')),
        isTrue,
        reason: 'needs a claim row with both 14 and language');
  });
}
