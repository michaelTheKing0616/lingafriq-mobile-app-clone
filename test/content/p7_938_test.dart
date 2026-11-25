import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _asset = 'assets/tutorials/p7_938.json';
const _gameContent = 'assets/data/game_content.json';
const _manifest = 'assets/data/audio_manifest.json';
const _tracks = 'assets/data/scripts/tracks_catalog.json';

const _stepOrder = ['learn', 'see', 'try'];

int _runtimeSeconds(List<dynamic> steps) {
  var total = 0;
  for (final s in steps) {
    total += (s as Map)['duration_seconds'] as int;
  }
  return total;
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
  if (see['slow_motion_replay'] != true) return false;
  for (final ex in (see['ejective_syllable_examples'] as List)
      .cast<Map<String, dynamic>>()) {
    final audio = ex['audio_uri']?.toString().trim();
    final video = ex['mouth_video_uri']?.toString().trim();
    if (audio == null || audio.isEmpty || video == null || video.isEmpty) {
      return false;
    }
  }
  for (final ex in (see['gemination_examples'] as List)
      .cast<Map<String, dynamic>>()) {
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
  late List<dynamic> words;
  late List<dynamic> manifestEntries;
  late Map<String, dynamic> tracks;

  setUpAll(() {
    pack = jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
    final game =
        jsonDecode(File(_gameContent).readAsStringSync()) as Map<String, dynamic>;
    words = game['words'] as List<dynamic>;
    final man =
        jsonDecode(File(_manifest).readAsStringSync()) as Map<String, dynamic>;
    manifestEntries = man['entries'] as List<dynamic>;
    tracks =
        jsonDecode(File(_tracks).readAsStringSync()) as Map<String, dynamic>;
  });

  test('AC1: Amharic tutorial uses learn → see → try (60–90 s)', () {
    final tutorials = pack['tutorials'] as List;
    expect(tutorials.length, 1);
    final t = tutorials.first as Map<String, dynamic>;
    expect(t['id'], 'am-sound-ejective-gemination');
    expect(t['language_code'], 'am');

    final steps = t['steps'] as List;
    expect(steps.length, 3);
    expect(steps.map((s) => (s as Map)['kind'] as String).toList(), _stepOrder);
    expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));
  });

  test('learn step cites Ge\'ez Fidel track for Amharic', () {
    expect(tracks['language_to_track']['am'], 'geez_fidel');
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final learn = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'learn');
    final body = learn['body_en'] as String;
    expect(body.toLowerCase(), contains('fidel'));
    expect(body.toLowerCase(), contains('ejective'));
    expect(body.toLowerCase(), contains('geminat'));
  });

  test('see examples match game_content and audio manifest (no invented Amharic)', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final see = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'see');
    expect(see['slow_motion_replay'], isTrue);

    for (final ex in (see['ejective_syllable_examples'] as List)
        .cast<Map<String, dynamic>>()) {
      final gid = ex['game_content_id'] as int;
      final row = _wordById(words, gid);
      expect(row, isNotNull);
      expect(row!['language'], 'amharic');
      expect(row['word'], ex['phrase']);
      expect((ex['phrase'] as String).contains(ex['syllable_fidel'] as String),
          isTrue);

      final mid = ex['manifest_id'] as String;
      final ment = _manifestById(manifestEntries, mid);
      expect(ment, isNotNull);
      expect(ment!['text'], ex['phrase']);
      expect(ment['manifest_key'], ex['manifest_key']);
    }

    for (final ex in (see['gemination_examples'] as List)
        .cast<Map<String, dynamic>>()) {
      final gid = ex['game_content_id'] as int;
      final row = _wordById(words, gid);
      expect(row!['word'], ex['phrase']);
      expect((ex['phrase'] as String).contains(ex['geminate_spelling'] as String),
          isTrue);

      final contrastId = ex['contrast_game_content_id'] as int;
      final contrast = _wordById(words, contrastId);
      expect(contrast!['word'], ex['contrast_phrase']);
      expect((contrast['word'] as String).contains('በጣም'), isFalse);
    }
  });

  test('try step gemination perception uses cited game_content ids', () {
    final tutorial = (pack['tutorials'] as List).first as Map<String, dynamic>;
    final tryStep = (tutorial['steps'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['kind'] == 'try');
    expect(tryStep['correct_game_content_id'], 1045);
    final choices = (tryStep['choices'] as List).cast<Map<String, dynamic>>();
    expect(choices.length, 2);
    for (final c in choices) {
      final gid = c['game_content_id'] as int;
      final row = _wordById(words, gid);
      expect(row!['word'], c['form']);
    }
  });

  test('AC2: publish requires native sign-off and complete see-step media', () {
    expect(pack['native_reviewer_sign_offs'], isEmpty);
    expect(_canPublish(pack), isFalse);

    final signed = Map<String, dynamic>.from(pack);
    signed['native_reviewer_sign_offs'] = [
      {
        'reviewer_id': 'native-am-1',
        'signed_at': '2026-10-27',
        'language_code': 'am',
        'scope': 'am-sound-ejective-gemination',
      },
    ];
    expect(_canPublish(signed), isFalse);
  });
}
