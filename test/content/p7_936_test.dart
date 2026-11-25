import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _asset = 'assets/tutorials/p7_936.json';
const _haLexicon = 'assets/data/lexicon/a1/ha.json';
const _layouts = 'assets/data/keyboard/layouts.json';
const _ocrFixtures = 'assets/data/lens/ocr_diacritic_fixtures.json';

const _stepOrder = ['learn', 'see', 'try'];

int _runtimeSeconds(List<dynamic> steps) {
  var total = 0;
  for (final s in steps) {
    total += (s as Map)['duration_seconds'] as int;
  }
  return total;
}

bool _canPublish(Map<String, dynamic> pack) {
  final signOffs = pack['native_reviewer_sign_offs'] as List;
  if (signOffs.isEmpty) return false;
  final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
  final see = (tutorial['steps'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((s) => s['kind'] == 'see');
  final examples =
      (see['hooked_consonant_examples'] as List).cast<Map<String, dynamic>>();
  for (final ex in examples) {
    final audio = ex['audio_uri']?.toString().trim();
    final video = ex['mouth_video_uri']?.toString().trim();
    if (audio == null || audio.isEmpty || video == null || video.isEmpty) {
      return false;
    }
  }
  return true;
}

void main() {
  late Map<String, dynamic> pack;
  late List<dynamic> haLexemes;
  late Map<String, dynamic> layouts;
  late List<dynamic> ocrFixtures;

  setUpAll(() {
    pack = jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
    final lex =
        jsonDecode(File(_haLexicon).readAsStringSync()) as Map<String, dynamic>;
    haLexemes = lex['lexemes'] as List<dynamic>;
    layouts =
        jsonDecode(File(_layouts).readAsStringSync()) as Map<String, dynamic>;
    final ocr = jsonDecode(File(_ocrFixtures).readAsStringSync())
        as Map<String, dynamic>;
    ocrFixtures = ocr['fixtures'] as List<dynamic>;
  });

  test('AC1: Hausa hooked-consonant tutorial uses learn → see → try (60–90 s)', () {
    final tutorials = pack['tutorials'] as List;
    expect(tutorials.length, 1);
    final t = tutorials.first as Map<String, dynamic>;
    expect(t['id'], 'ha-sound-implosive-ejective');

    final steps = t['steps'] as List;
    expect(steps.length, 3);
    expect(steps.map((s) => (s as Map)['kind'] as String).toList(), _stepOrder);
    expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));
  });

  test('learn step cites Hausa hooked letters from keyboard layout', () {
    final haLetters =
        ((layouts['layouts'] as Map)['ha'] as Map)['letters'] as List;
    expect(haLetters, containsAll(['ɓ', 'ɗ', 'ƙ']));
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final learn = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'learn');
    final body = learn['body_en'] as String;
    expect(body.contains('ɓ'), isTrue);
    expect(body.contains('ɗ'), isTrue);
    expect(body.contains('ƙ'), isTrue);
  });

  test('see step examples match A1 lexicon (ɓ ɗ ƙ)', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final examples =
        (see['hooked_consonant_examples'] as List).cast<Map<String, dynamic>>();
    expect(examples.map((e) => e['phoneme']), ['ɓ', 'ɗ', 'ƙ']);

    for (final ex in examples) {
      final lexId = ex['lexicon_id'] as String;
      final lemma = ex['lemma'] as String;
      final row = haLexemes.cast<Map<String, dynamic>>().firstWhere(
            (e) => e['id'] == lexId,
            orElse: () => throw StateError('missing lexicon row $lexId'),
          );
      expect(row['lemma'], lemma);
    }

    final ocr = see['ocr_contrast'] as Map<String, dynamic>;
    final fixture = ocrFixtures.cast<Map<String, dynamic>>().firstWhere(
          (f) => f['id'] == ocr['fixture_id'],
        );
    expect(ocr['gold_text'], fixture['gold_text']);
    expect((ocr['gold_text'] as String).contains('ƙ'), isTrue);
  });

  test('AC2: publish requires native sign-off and complete see-step media', () {
    expect(pack['native_reviewer_sign_offs'], isEmpty);
    expect(_canPublish(pack), isFalse);

    final signed = Map<String, dynamic>.from(pack);
    signed['native_reviewer_sign_offs'] = [
      {
        'reviewer_id': 'native-ha-1',
        'signed_at': '2026-10-27',
        'scope': 'ha-sound-implosive-ejective',
      },
    ];
    expect(_canPublish(signed), isFalse);
  });
}
