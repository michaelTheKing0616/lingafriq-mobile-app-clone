// Compliance batch 1 (#1/#2): no AI keys or key material ship in the client,
// and key files stay out of git. Fails the build if either regresses.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _forbidden = <String, RegExp>{
  'AI provider endpoint': RegExp(
    r'api\.groq\.com|api\.openai\.com|router\.huggingface\.co/models|'
    r'api-inference\.huggingface\.co|generativelanguage\.googleapis\.com|'
    r'api\.stability\.ai|api\.replicate\.com|api\.anthropic\.com|api\.x\.ai',
  ),
  'AI key define': RegExp(
    r'GROQ_API_KEY|OPENAI_API_KEY|HUGGINGFACE_TOKEN|STABILITY_AI_KEY|'
    r'GOOGLE_CLOUD_API_KEY|GEMINI_API_KEY|ANTHROPIC_API_KEY|XAI_API_KEY',
  ),
  'literal key': RegExp(
    r'''['"](AIza[0-9A-Za-z_\-]{30,}|sk-[A-Za-z0-9_\-]{20,}|'''
    r'''gsk_[A-Za-z0-9]{20,}|hf_[A-Za-z0-9]{20,}|xai-[A-Za-z0-9]{20,})['"]''',
  ),
  'private key': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
};

List<String> _tracked() {
  final r = Process.runSync('git', ['ls-files']);
  expect(r.exitCode, 0, reason: 'git ls-files must run');
  return (r.stdout as String).split('\n').where((l) => l.isNotEmpty).toList();
}

void main() {
  test('lib/ has no AI provider endpoints, AI key defines or literal keys', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final e in _forbidden.entries) {
          // Report the location only, never the matched value.
          if (e.value.hasMatch(lines[i]))
            hits.add('${f.path}:${i + 1} ${e.key}');
        }
      }
    }
    expect(hits, isEmpty);
  });

  test('key material and env files are not tracked; examples are', () {
    final secretFile = RegExp(
      r'(^|/)(AuthKey_[^/]*\.p8|[^/]*\.p8|google-services\.json|'
      r'GoogleService-Info\.plist|[^/]*firebase-adminsdk[^/]*\.json|'
      r'\.env(\.[^/]*)?|dart_defines\.json|key\.properties|[^/]*\.jks|'
      r'[^/]*\.keystore)$',
    );
    final files = _tracked();
    expect(files.where(secretFile.hasMatch).toList(), isEmpty);
    expect(
      files,
      containsAll(<String>[
        'android/app/google-services.json.example',
        'GoogleService-Info.plist.example',
        'dart_defines.example.json',
      ]),
    );
  });

  test('Firebase keys are read from --dart-define, not committed', () {
    final src = File('lib/firebase_options.dart').readAsStringSync();
    expect(src, contains("String.fromEnvironment('FIREBASE_API_KEY_ANDROID')"));
    expect(src, contains("String.fromEnvironment('FIREBASE_API_KEY_IOS')"));
  });
}
