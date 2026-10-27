import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';

void main() {
  test('parses verification_status and human audio uris from API payload', () {
    final fixturePath = File(
      'test/content/fixtures/lexeme_yo_oko.json',
    ).absolute.path;
    final fixture =
        jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
    final api = {
      'lexeme_id': fixture['id'],
      'language': 'yo',
      'verification_status': 'expert_reviewed',
      'entry': fixture,
    };
    final row = VerifiedLexeme.fromApiJson(api);
    expect(row.lexemeId, 'yo.lex.ọkọ.vehicle');
    expect(row.verificationStatus, 'expert_reviewed');
    expect(row.lemma, 'ọkọ̀');
    expect(row.standardOrthography, 'ọkọ̀');
    expect(row.audioUris.length, greaterThanOrEqualTo(2));
    expect(row.audioUris.first, startsWith('audio/yo/'));
  });
}
