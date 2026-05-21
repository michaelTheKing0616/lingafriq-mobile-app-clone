import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persona_missions.json covers 14 curriculum languages', () {
    final path = File('assets/data/persona_missions.json');
    expect(path.existsSync(), isTrue);
    final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    final missions = json['missions'] as List;
    final langs = missions.map((m) => (m as Map)['language'] as String).toSet();
    for (final lang in [
      'yoruba',
      'hausa',
      'igbo',
      'swahili',
      'zulu',
      'xhosa',
      'wolof',
      'pidgin',
      'afrikaans',
      'amharic',
      'twi',
      'somali',
      'lingala',
      'shona',
    ]) {
      expect(langs, contains(lang), reason: 'persona mission for $lang');
    }
  });
}
