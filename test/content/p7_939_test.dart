import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _asset = 'assets/tutorials/p7_939.json';
const _swLexicon = 'assets/data/lexicon/a1/sw.json';
const _patterns = 'assets/data/patterns/sw.json';
const _gameContent = 'assets/data/game_content.json';
const _manifest = 'assets/data/audio_manifest.json';

const _stepOrder = ['learn', 'see', 'try'];
const _legalPairs = {'m/wa', 'ki/vi'};

int _runtimeSeconds(List<dynamic> steps) {
  var total = 0;
  for (final s in steps) {
    total += (s as Map)['duration_seconds'] as int;
  }
  return total;
}

Map<String, dynamic>? _lexemeById(List<dynamic> lexemes, String id) {
  for (final raw in lexemes) {
    final lx = raw as Map<String, dynamic>;
    if (lx['id'] == id) return lx;
  }
  return null;
}

Map<String, dynamic>? _wordById(List<dynamic> words, int id) {
  for (final raw in words) {
    final w = raw as Map<String, dynamic>;
    if (w['id'] == id) return w;
  }
  return null;
}

Map<String, dynamic>? _manifestById(List<dynamic> entries, String id) {
  for (final raw in entries) {
    final e = raw as Map<String, dynamic>;
    if (e['id'] == id) return e;
  }
  return null;
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
  final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
  final see = (tutorial['steps'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((s) => s['kind'] == 'see');
  final wheel = see['class_wheel'] as Map<String, dynamic>;
  for (final segRaw in wheel['segments'] as List) {
    final seg = segRaw as Map<String, dynamic>;
    for (final exRaw in seg['example_nouns'] as List) {
      final ex = exRaw as Map<String, dynamic>;
      final mid = ex['manifest_id']?.toString().trim();
      if (mid == null || mid.isEmpty) continue;
      final audio = ex['audio_uri']?.toString().trim();
      if (audio == null || audio.isEmpty) return false;
    }
  }
  return true;
}

void main() {
  late Map<String, dynamic> pack;
  late List<dynamic> swLexemes;
  late Map<String, dynamic> patterns;
  late List<dynamic> words;
  late List<dynamic> manifestEntries;

  setUpAll(() {
    pack = jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
    final lex =
        jsonDecode(File(_swLexicon).readAsStringSync()) as Map<String, dynamic>;
    swLexemes = lex['lexemes'] as List<dynamic>;
    patterns =
        jsonDecode(File(_patterns).readAsStringSync()) as Map<String, dynamic>;
    final game =
        jsonDecode(File(_gameContent).readAsStringSync()) as Map<String, dynamic>;
    words = game['words'] as List<dynamic>;
    final man =
        jsonDecode(File(_manifest).readAsStringSync()) as Map<String, dynamic>;
    manifestEntries = man['entries'] as List<dynamic>;
  });

  test('AC1: Swahili noun-class tutorial uses learn → see class wheel → try (60–90 s)',
      () {
    final tutorials = pack['tutorials'] as List;
    expect(tutorials.length, 1);
    final t = tutorials.first as Map<String, dynamic>;
    expect(t['id'], 'sw-sound-noun-classes');
    expect(t['language_code'], 'sw');

    final steps = t['steps'] as List;
    expect(steps.length, 3);
    expect(steps.map((s) => (s as Map)['kind'] as String).toList(), _stepOrder);
    expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));

    final see = steps
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    expect(see['presentation'], 'class_wheel');
    final wheel = see['class_wheel'] as Map<String, dynamic>;
    expect((wheel['segments'] as List).length, greaterThanOrEqualTo(2));
  });

  test('AC3: reduced motion disables wheel rotation; selection is tap_segment', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final wheel = see['class_wheel'] as Map<String, dynamic>;
    expect(wheel['rotate_when_motion_allowed'], isTrue);
    final rm = wheel['reduced_motion'] as Map<String, dynamic>;
    expect(rm['rotate_wheel'], isFalse);
    expect(rm['selection_mode'], 'tap_segment');
  });

  test('AC2: wheel segments use only legal m/wa and ki/vi pairs with prefixes and cited nouns',
      () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final wheel = see['class_wheel'] as Map<String, dynamic>;

    for (final segRaw in wheel['segments'] as List) {
      final seg = segRaw as Map<String, dynamic>;
      final pair = seg['class_pair'] as String;
      expect(_legalPairs.contains(pair), isTrue,
          reason: 'illegal class pair $pair');
      expect(seg['singular_prefix'], isNotEmpty);
      expect(seg['plural_prefix'], isNotEmpty);

      final examples =
          (seg['example_nouns'] as List).cast<Map<String, dynamic>>();
      expect(examples, isNotEmpty);
      for (final ex in examples) {
        final lxId = ex['lexicon_id'] as String;
        final lx = _lexemeById(swLexemes, lxId);
        expect(lx, isNotNull);
        expect((lx!['lemma'] as String).toLowerCase(),
            ex['lemma'].toString().toLowerCase());

        final gid = ex['game_content_id'];
        if (gid != null) {
          final row = _wordById(words, gid as int);
          expect(row, isNotNull);
          expect(row!['language'], 'swahili');
          expect(row['word'], ex['lemma']);
        }

        final mid = ex['manifest_id']?.toString();
        if (mid != null && mid.isNotEmpty) {
          final ment = _manifestById(manifestEntries, mid);
          expect(ment, isNotNull);
          expect(ment!['text'], ex['lemma']);
          expect(ment['manifest_key'], ex['manifest_key']);
        }
      }
    }
  });

  test('ki/vi segment cites present-na pattern example with kitabu', () {
    final patList = patterns['patterns'] as List;
    final pat = patList.cast<Map<String, dynamic>>().firstWhere(
          (p) => p['id'] == 'sw.pat.present-na',
        );
    expect((pat['examples'] as List).join(' '), contains('kitabu'));

    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    final kiSeg = (see['class_wheel']['segments'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['class_pair'] == 'ki/vi');
    final kitabu = (kiSeg['example_nouns'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((e) => e['lemma'] == 'kitabu');
    expect(kitabu['pattern_id'], 'sw.pat.present-na');
  });

  test('try step perception targets ki- singular on cited lexicon row', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final tryStep = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'try');
    expect(tryStep['correct_lexicon_id'], 'sw.lex.2287215c0da4');
    expect(tryStep['correct_segment_id'], 'sw.seg.ki-vi');
    final choices = (tryStep['choices'] as List).cast<Map<String, dynamic>>();
    expect(choices.length, 2);
  });

  test('publish requires native sign-off and manifest audio URIs when manifest_id set',
      () {
    expect(pack['native_reviewer_sign_offs'], isEmpty);
    expect(_canPublish(pack), isFalse);
  });
}
