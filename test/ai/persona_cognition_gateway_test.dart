import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persona_cognition_dart_has_no_client_llm_calls', () {
    final dir = Directory('lib/ai/persona_cognition');
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      expect(source.contains('Bearer '), isFalse, reason: entity.path);
      expect(source.contains('response_format'), isFalse, reason: entity.path);
      expect(source.contains('groq.com'), isFalse, reason: entity.path);
    }
  });
}
