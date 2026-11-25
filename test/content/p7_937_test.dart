import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _asset = 'assets/tutorials/p7_937.json';
const _clicksVowels = 'assets/data/sound/clicks_vowels.json';
const _zuLexicon = 'assets/data/lexicon/a1/zu.json';
const _xhLexicon = 'assets/data/lexicon/a1/xh.json';

const _stepOrder = ['learn', 'see', 'try'];
const _clickLetters = ['c', 'q', 'x'];

int _runtimeSeconds(List<dynamic> steps) {
  var total = 0;
  for (final s in steps) {
    total += (s as Map)['duration_seconds'] as int;
  }
  return total;
}

bool _hasLanguageSignOff(
  List<dynamic> signOffs,
  String languageCode,
  String tutorialId,
) {
  for (final raw in signOffs) {
    final row = raw as Map<String, dynamic>;
    final lang = row['language_code']?.toString();
    final scope = row['scope']?.toString() ?? '';
    if (lang == languageCode && scope.contains(tutorialId)) {
      return true;
    }
  }
  return false;
}

bool _canPublish(Map<String, dynamic> pack) {
  final signOffs = pack['native_reviewer_sign_offs'] as List;
  final reqs = pack['sign_off_requirements'] as List;
  for (final reqRaw in reqs) {
    final req = reqRaw as Map<String, dynamic>;
    final lang = req['language_code'] as String;
    final tid = req['tutorial_id'] as String;
    if (!_hasLanguageSignOff(signOffs, lang, tid)) return false;
  }
  for (final t in pack['tutorials'] as List) {
    final see = (t['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    if (see['slow_motion_replay'] != true) return false;
    final examples =
        (see['click_examples'] as List).cast<Map<String, dynamic>>();
    for (final ex in examples) {
      final audio = ex['audio_uri']?.toString().trim();
      final video = ex['mouth_video_uri']?.toString().trim();
      if (audio == null || audio.isEmpty || video == null || video.isEmpty) {
        return false;
      }
    }
  }
  return true;
}

void main() {
  late Map<String, dynamic> pack;
  late Map<String, dynamic> clicks;
  late List<dynamic> zuLexemes;
  late List<dynamic> xhLexemes;

  setUpAll(() {
    pack = jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
    clicks =
        jsonDecode(File(_clicksVowels).readAsStringSync()) as Map<String, dynamic>;
    final zu =
        jsonDecode(File(_zuLexicon).readAsStringSync()) as Map<String, dynamic>;
    zuLexemes = zu['lexemes'] as List<dynamic>;
    final xh =
        jsonDecode(File(_xhLexicon).readAsStringSync()) as Map<String, dynamic>;
    xhLexemes = xh['lexemes'] as List<dynamic>;
  });

  test('AC1: Zulu and Xhosa click tutorials use learn → see → try (60–90 s)', () {
    final tutorials = pack['tutorials'] as List;
    expect(tutorials.length, 2);
    final ids = tutorials.map((t) => (t as Map)['id'] as String).toSet();
    expect(ids, containsAll(['zu-sound-clicks', 'xh-sound-clicks']));

    for (final raw in tutorials) {
      final t = raw as Map<String, dynamic>;
      final steps = t['steps'] as List;
      expect(steps.length, 3);
      expect(steps.map((s) => (s as Map)['kind'] as String).toList(), _stepOrder);
      expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));
    }
  });

  test('see steps teach c, q, x with slow-motion replay flag', () {
    for (final raw in pack['tutorials'] as List) {
      final t = raw as Map<String, dynamic>;
      final see = (t['steps'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['kind'] == 'see');
      expect(see['slow_motion_replay'], isTrue);
      final letters = (see['click_examples'] as List)
          .map((e) => (e as Map)['click_letter'] as String)
          .toList();
      expect(letters, _clickLetters);
    }
  });

  test('click lemmas match A1 lexicon rows (no invented Zulu/Xhosa)', () {
    final zuTutorial = (pack['tutorials'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((t) => t['id'] == 'zu-sound-clicks');
    final zuSee = (zuTutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    for (final ex in (zuSee['click_examples'] as List).cast<Map<String, dynamic>>()) {
      final lexId = ex['lexicon_id'] as String;
      final lemma = ex['lemma'] as String;
      final row = zuLexemes.cast<Map<String, dynamic>>().firstWhere(
            (e) => e['id'] == lexId,
            orElse: () => throw StateError('missing zu lexicon row $lexId'),
          );
      expect(row['lemma'], lemma);
    }

    final xhTutorial = (pack['tutorials'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((t) => t['id'] == 'xh-sound-clicks');
    final xhSee = (xhTutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    for (final ex in (xhSee['click_examples'] as List).cast<Map<String, dynamic>>()) {
      final lexId = ex['lexicon_id'] as String;
      final lemma = ex['lemma'] as String;
      final row = xhLexemes.cast<Map<String, dynamic>>().firstWhere(
            (e) => e['id'] == lexId,
            orElse: () => throw StateError('missing xh lexicon row $lexId'),
          );
      expect(row['lemma'], lemma);
    }
  });

  test('try steps reference licensed click drills', () {
    final zuTry = ((pack['tutorials'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((t) => t['id'] == 'zu-sound-clicks')['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'try');
    final zuDrills =
        ((clicks['languages'] as Map)['zu'] as Map)['drills'] as List;
    final zuDrillId = zuTry['drill_id'] as String;
    expect(zuDrills.any((d) => (d as Map)['id'] == zuDrillId), isTrue);

    final xhTry = ((pack['tutorials'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((t) => t['id'] == 'xh-sound-clicks')['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'try');
    final xhDrills =
        ((clicks['languages'] as Map)['xh'] as Map)['drills'] as List;
    final xhDrillId = xhTry['drill_id'] as String;
    expect(xhDrills.any((d) => (d as Map)['id'] == xhDrillId), isTrue);
  });

  test('AC3: publish requires per-language native sign-off and complete media', () {
    expect(pack['native_reviewer_sign_offs'], isEmpty);
    expect(_canPublish(pack), isFalse);

    final partial = Map<String, dynamic>.from(pack);
    partial['native_reviewer_sign_offs'] = [
      {
        'reviewer_id': 'native-zu-1',
        'signed_at': '2026-10-27',
        'language_code': 'zu',
        'scope': 'zu-sound-clicks',
      },
    ];
    expect(_canPublish(partial), isFalse);
  });
}
