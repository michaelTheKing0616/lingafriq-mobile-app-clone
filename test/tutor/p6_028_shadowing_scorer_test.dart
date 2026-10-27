import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _tutorPath = 'lib/screens/tutor/tutor_pronunciation_mode_screen.dart';

String _code(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

void main() {
  test('P6-028 uses gateway scorer and pitch overlay without fake toneScore', () {
    final code = _code(_tutorPath);
    expect(code.contains('toneScore'), isFalse);
    expect(code.contains('/api/ai/score/utterance'), isTrue);
    expect(code.contains('ToneOverlayView'), isTrue);
    expect(code.contains('overall_score'), isFalse);
    expect(code.contains('selectedLanguage.value.code'), isTrue);
    expect(code.contains('shadow.unsure'), isTrue);
  });
}
