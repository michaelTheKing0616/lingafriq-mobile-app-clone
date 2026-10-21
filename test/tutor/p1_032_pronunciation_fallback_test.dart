// P1-032 Spec-Tests (Mode A). Derived from the card ACs only.
// No network, no real model calls, no sleeps.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _unavailableKey = 'pron.unavailable';
const _tutorPath = 'lib/screens/tutor/tutor_pronunciation_mode_screen.dart';

String _code(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

bool _referencesKey(String code, String key) =>
    code.contains("'$key'") || code.contains('"$key"');

void main() {
  test('P1-032_AC2_503_whisper_fallback_or_unavailable_shows_no_score', () {
    final code = _code(_tutorPath);

    expect(_referencesKey(code, _unavailableKey), isTrue,
        reason: '$_tutorPath must show copy key $_unavailableKey');

    final handles503 = RegExp(r'\b503\b').hasMatch(code) ||
        code.contains('retryable');
    expect(handles503, isTrue,
        reason: 'client must branch on HTTP 503 or retryable');

    final whisperFallback = RegExp(r'whisper', caseSensitive: false).hasMatch(code);
    final unavailableState = _referencesKey(code, _unavailableKey);
    expect(whisperFallback || unavailableState, isTrue,
        reason: '503 must run Whisper fallback or show unavailable');

    expect(code.contains('overall_score'), isFalse, reason: 'must show no score');
    expect(code.contains('_pronunciationScore'), isFalse, reason: 'must show no score');
    expect(code.contains('GriotMasteryRing'), isFalse, reason: 'must show no score');

    final arb = File('lib/l10n/app_en.arb');
    expect(arb.existsSync(), isTrue);
    final text = arb.readAsStringSync();
    expect(
      text.contains('"$_unavailableKey"') || text.contains('"pron_unavailable"'),
      isTrue,
      reason: 'app_en.arb lacks $_unavailableKey',
    );
  });
}
