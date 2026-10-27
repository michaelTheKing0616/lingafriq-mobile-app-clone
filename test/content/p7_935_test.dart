import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _asset = 'assets/tutorials/p7_935.json';
const _igLexicon = 'assets/data/lexicon/a1/ig.json';
const _patterns = 'assets/data/patterns/ig.json';
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
      (see['dotted_vowel_examples'] as List).cast<Map<String, dynamic>>();
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
  late List<dynamic> igLexemes;
  late Map<String, dynamic> patterns;
  late List<dynamic> ocrFixtures;

  setUpAll(() {
    pack = jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
    final lex =
        jsonDecode(File(_igLexicon).readAsStringSync()) as Map<String, dynamic>;
    igLexemes = lex['lexemes'] as List<dynamic>;
    patterns =
        jsonDecode(File(_patterns).readAsStringSync()) as Map<String, dynamic>;
    final ocr = jsonDecode(File(_ocrFixtures).readAsStringSync())
        as Map<String, dynamic>;
    ocrFixtures = ocr['fixtures'] as List<dynamic>;
  });

  test('AC1: Igbo vowel harmony tutorial uses learn → see → try (60–90 s)', () {
    final tutorials = pack['tutorials'] as List;
    expect(tutorials.length, 1);
    final t = tutorials.first as Map<String, dynamic>;
    expect(t['id'], 'ig-sound-vowel-harmony');

    final steps = t['steps'] as List;
    expect(steps.length, 3);
    expect(steps.map((s) => (s as Map)['kind'] as String).toList(), _stepOrder);
    expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));
  });

  test('see step dotted vowels match A1 lexicon and OCR gold text', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final examples =
        (see['dotted_vowel_examples'] as List).cast<Map<String, dynamic>>();
    expect(examples.length, 2);

    final ahiaFixture = ocrFixtures.cast<Map<String, dynamic>>().firstWhere(
          (f) => f['id'] == 'ig.ahia',
        );
    final ahiaEx = examples.firstWhere((e) => e['lemma'] == 'ahịa');
    expect(ahiaEx['display_form'], ahiaFixture['gold_text']);
    final ahiaRow = igLexemes.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == ahiaEx['lexicon_id'],
        );
    expect(ahiaRow['lemma'], 'ahịa');

    final uloEx = examples.firstWhere((e) => e['lemma'] == 'ụlọ');
    final uloRow = igLexemes.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == uloEx['lexicon_id'],
        );
    expect(uloRow['lemma'], 'ụlọ');
  });

  test('harmony example cites progressive pattern contrast (no invented Igbo)', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final harmony = see['harmony_example'] as Map<String, dynamic>;
    final patternList = patterns['patterns'] as List;
    final progressive = patternList.cast<Map<String, dynamic>>().firstWhere(
          (p) => p['id'] == harmony['pattern_id'],
        );
    final contrasts = (progressive['contrasts'] as List).cast<String>();
    expect(contrasts, contains(harmony['form']));

    final stemId = harmony['stem_lexicon_id'] as String;
    final stemRow = igLexemes.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == stemId,
        );
    expect(stemRow['lemma'], 'akwụkwọ');
    final form = harmony['form'] as String;
    expect(form.contains(stemRow['lemma'] as String), isTrue);
    expect(form.startsWith('O gụrụ'), isTrue);
  });

  test('AC2: publish requires native sign-off and complete see-step media', () {
    expect(pack['native_reviewer_sign_offs'], isEmpty);
    expect(_canPublish(pack), isFalse);

    final signed = Map<String, dynamic>.from(pack);
    signed['native_reviewer_sign_offs'] = [
      {
        'reviewer_id': 'native-ig-1',
        'signed_at': '2026-10-27',
        'scope': 'ig-sound-vowel-harmony',
      },
    ];
    expect(_canPublish(signed), isFalse);
  });
}
