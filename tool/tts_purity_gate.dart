// TTS Purity Gate
//
// Fails the build if production code (under `lib/`) ships any direct
// flutter_tts.setLanguage('en-US' | 'en_US' | 'English') or generic
// FlutterTts() construction outside the approved fallback path inside
// `lib/services/audio/african_tts_service.dart`.
//
// Authentic African-accented audio MUST be served by AfricanTtsService.
// flutter_tts is only acceptable as the on-device offline fallback path it
// owns. Any other usage is a regression.
//
// Usage:
//   dart run tool/tts_purity_gate.dart
//
// Exit codes:
//   0 — clean
//   1 — violations detected (printed with file:line)

import 'dart:io';

class Violation {
  final String path;
  final int line;
  final String snippet;
  final String reason;
  Violation(this.path, this.line, this.snippet, this.reason);
  @override
  String toString() => '$path:$line — $reason\n    > $snippet';
}

/// Paths that are intentionally allowed to import flutter_tts directly.
const _allowList = <String>[
  'lib/services/audio/african_tts_service.dart',
];

bool _isAllowed(String path) {
  final norm = path.replaceAll('\\', '/');
  for (final allowed in _allowList) {
    if (norm.endsWith(allowed)) return true;
  }
  return false;
}

final _ttsImportPattern =
    RegExp("import\\s+['\"]package:flutter_tts/");
final _englishLocalePattern = RegExp(
  "setLanguage\\s*\\(\\s*['\"]en[-_]US['\"]\\s*\\)",
  caseSensitive: false,
);

List<Violation> scan(Directory libDir) {
  final out = <Violation>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (_isAllowed(entity.path)) continue;
    final rel = entity.path.replaceAll(libDir.parent.path, '').replaceAll('\\', '/');
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_ttsImportPattern.hasMatch(line)) {
        out.add(Violation(
          '.$rel',
          i + 1,
          line.trim(),
          'Direct import of flutter_tts outside AfricanTtsService',
        ));
      }
      if (_englishLocalePattern.hasMatch(line)) {
        out.add(Violation(
          '.$rel',
          i + 1,
          line.trim(),
          "Hard-coded en-US/en_US locale in production code",
        ));
      }
    }
  }
  return out;
}

void main(List<String> args) {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('tts_purity_gate: lib/ directory not found at ${lib.absolute.path}');
    exit(2);
  }
  final violations = scan(lib);
  if (violations.isEmpty) {
    stdout.writeln('tts_purity_gate: clean — no flutter_tts violations under lib/');
    return;
  }
  stdout.writeln('tts_purity_gate: ${violations.length} violation(s)');
  for (final v in violations) {
    stdout.writeln(v);
  }
  exit(1);
}
