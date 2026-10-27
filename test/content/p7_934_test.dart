import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _asset = 'assets/tutorials/p7_934.json';
const _minimalPairs = 'assets/data/tone/minimal_pairs.json';
const _yoLexicon = 'assets/data/lexicon/a1/yo.json';

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
  for (final t in pack['tutorials'] as List) {
    final steps = t['steps'] as List;
    for (final raw in steps) {
      final step = raw as Map<String, dynamic>;
      if (step['kind'] != 'see') continue;
      final examples = step['labiovelar_examples'] as List?;
      if (examples == null) continue;
      for (final exRaw in examples) {
        final ex = exRaw as Map<String, dynamic>;
        if (ex['gate'] == 'KP_LEXICON_ANCHOR_PENDING') return false;
        final audio = ex['audio_uri']?.toString().trim();
        final video = ex['mouth_video_uri']?.toString().trim();
        if (audio == null || audio.isEmpty || video == null || video.isEmpty) {
          return false;
        }
      }
    }
  }
  return true;
}

void main() {
  late Map<String, dynamic> pack;
  late Map<String, dynamic> minimalPairs;
  late List<dynamic> yoLexemes;

  setUpAll(() {
    pack = jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
    minimalPairs =
        jsonDecode(File(_minimalPairs).readAsStringSync()) as Map<String, dynamic>;
    final lex = jsonDecode(File(_yoLexicon).readAsStringSync()) as Map<String, dynamic>;
    yoLexemes = lex['lexemes'] as List<dynamic>;
  });

  test('AC1: both Yoruba sound tutorials use learn → see → try (60–90 s each)', () {
    final tutorials = pack['tutorials'] as List;
    expect(tutorials.length, 2);
    final ids = tutorials.map((t) => (t as Map)['id'] as String).toSet();
    expect(ids, containsAll(['yo-sound-tones-subdot', 'yo-sound-gb-kp']));

    for (final raw in tutorials) {
      final t = raw as Map<String, dynamic>;
      final steps = t['steps'] as List;
      expect(steps.length, 3);
      expect(steps.map((s) => (s as Map)['kind'] as String).toList(), _stepOrder);
      final runtime = _runtimeSeconds(steps);
      expect(runtime, inInclusiveRange(60, 90));
    }
  });

  test('tones tutorial cites FSI minimal pair forms (no invented Yoruba)', () {
    final tones = (pack['tutorials'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((t) => t['id'] == 'yo-sound-tones-subdot');
    final see = (tones['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final forms = (see['contrast_forms'] as List).cast<Map<String, dynamic>>();
    final yoDrills =
        ((minimalPairs['languages'] as Map)['yo'] as Map)['drills'] as List;
    final drill = yoDrills.first as Map<String, dynamic>;
    final options = (drill['options'] as List).cast<Map<String, dynamic>>();
    final citedForms = options.map((o) => o['form'] as String).toSet();
    for (final f in forms) {
      expect(citedForms, contains(f['form']));
    }
  });

  test('AC2: gb/kp see step defines both phonemes; gb example matches A1 lexicon', () {
    final gbKp = (pack['tutorials'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((t) => t['id'] == 'yo-sound-gb-kp');
    final see = (gbKp['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final examples =
        (see['labiovelar_examples'] as List).cast<Map<String, dynamic>>();
    expect(examples.map((e) => e['phoneme']), ['gb', 'kp']);

    final gb = examples.first;
    final lexId = gb['lexicon_id'] as String;
    final lemma = gb['lemma'] as String;
    final row = yoLexemes.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == lexId,
          orElse: () => throw StateError('missing lexicon row $lexId'),
        );
    expect(row['lemma'], lemma);

    final kp = examples[1];
    expect(kp['gate'], 'KP_LEXICON_ANCHOR_PENDING');
    expect(kp['lemma'], isNull);
  });

  test('AC3: publish requires native sign-off and complete gb/kp media', () {
    expect(pack['native_reviewer_sign_offs'], isEmpty);
    expect(_canPublish(pack), isFalse);

    final signed = Map<String, dynamic>.from(pack);
    signed['native_reviewer_sign_offs'] = [
      {
        'reviewer_id': 'native-yo-1',
        'signed_at': '2026-10-27',
        'scope': 'yo-sound-tones-subdot,yo-sound-gb-kp',
      },
    ];
    expect(_canPublish(signed), isFalse);
  });
}
