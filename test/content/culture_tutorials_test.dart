import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _greetings = 'assets/tutorials/culture_greetings.json';
const _naming = 'assets/tutorials/culture_naming.json';
const _taboo = 'assets/tutorials/culture_taboo.json';
const _stage1 = ['yo', 'ig', 'ha', 'pcm', 'sw', 'zu', 'xh'];
const _stepOrder = ['learn', 'see', 'try'];

int _runtimeSeconds(List<dynamic> steps) {
  var total = 0;
  for (final s in steps) {
    total += (s as Map)['duration_seconds'] as int;
  }
  return total;
}

Map<String, dynamic> _loadPack(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, dynamic>? _cultureCard(String lang, String cardId) {
  final data = jsonDecode(
    File('assets/data/culture/$lang.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final raw in data['cards'] as List) {
    final c = raw as Map<String, dynamic>;
    if (c['id'] == cardId) return c;
  }
  return null;
}

bool _hasSignOff(
  List<dynamic> consultant,
  List<dynamic> native,
  String lang,
  String tutorialId,
  String role,
) {
  final list = role == 'cultural_consultant' ? consultant : native;
  for (final raw in list) {
    final row = raw as Map<String, dynamic>;
    if (row['language_code'] == lang &&
        (row['tutorial_id'] == tutorialId ||
            (row['scope']?.toString().contains(tutorialId) ?? false))) {
      return true;
    }
  }
  return false;
}

bool _canPublish(Map<String, dynamic> pack) {
  final reqs = pack['sign_off_requirements'] as List;
  final consultant = pack['cultural_consultant_sign_offs'] as List;
  final native = pack['native_reviewer_sign_offs'] as List;
  for (final reqRaw in reqs) {
    final req = reqRaw as Map<String, dynamic>;
    final lang = req['language_code'] as String;
    final tid = req['tutorial_id'] as String;
    final roles = (req['roles'] as List).cast<String>();
    for (final role in roles) {
      if (!_hasSignOff(consultant, native, lang, tid, role)) return false;
    }
  }
  if (pack['pack'] == 'culture_taboo') {
    for (final tRaw in pack['tutorials'] as List) {
      final t = tRaw as Map<String, dynamic>;
      final see = (t['steps'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['kind'] == 'see');
      final topics = see['taboo_topics'] as List;
      if (topics.isEmpty) return false;
      for (final topicRaw in topics) {
        final topic = topicRaw as Map<String, dynamic>;
        final src = topic['source_ref']?.toString().trim();
        if (src == null || src.isEmpty) return false;
      }
    }
  }
  return true;
}

void _assertPackBasics(Map<String, dynamic> pack) {
  expect(pack['card'], 'P7-942');
  expect(pack['publish_status'], 'draft');
  expect((pack['external_blockers'] as List), contains('EXT-14'));
  final tutorials = pack['tutorials'] as List;
  expect(tutorials.length, _stage1.length);
  final langs =
      tutorials.map((t) => (t as Map)['language_code'] as String).toSet();
  expect(langs, _stage1.toSet());
}

void main() {
  late Map<String, dynamic> greetings;
  late Map<String, dynamic> naming;
  late Map<String, dynamic> taboo;

  setUpAll(() {
    greetings = _loadPack(_greetings);
    naming = _loadPack(_naming);
    taboo = _loadPack(_taboo);
  });

  test('pack metadata and EXT-14 gate on all three tutorial bundles', () {
    _assertPackBasics(greetings);
    _assertPackBasics(naming);
    _assertPackBasics(taboo);
    expect(_canPublish(greetings), isFalse);
    expect(_canPublish(naming), isFalse);
    expect(_canPublish(taboo), isFalse);
  });

  test('AC1: greeting tutorials show who greets first and cited choreography', () {
    for (final tRaw in greetings['tutorials'] as List) {
      final t = tRaw as Map<String, dynamic>;
      final lang = t['language_code'] as String;
      final steps = t['steps'] as List;
      expect(steps.map((s) => (s as Map)['kind'] as String).toList(),
          _stepOrder);
      expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));

      final see = steps
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['kind'] == 'see');
      expect(see['presentation'], 'greeting_choreography');
      final choreo = see['greeting_choreography'] as Map<String, dynamic>;
      expect(choreo['who_greets_first'], isNotEmpty);
      expect(choreo['sequence'], isNotEmpty);
      expect(choreo['physical_gestures_gate'], 'EXT-14_cultural_consultant');

      final card = _cultureCard(lang, '${lang}.culture.greetings');
      expect(card, isNotNull);
      expect(t['culture_card_id'], card!['id']);

      final tryStep = steps
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['kind'] == 'try');
      expect(tryStep['drill_kind'], 'choose_register');
      expect(tryStep['options'], isNotEmpty);
    }
  });

  test('AC2: naming tutorials explain kinship naming customs from culture cards',
      () {
    for (final tRaw in naming['tutorials'] as List) {
      final t = tRaw as Map<String, dynamic>;
      final lang = t['language_code'] as String;
      final steps = t['steps'] as List;
      expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));
      final see = steps
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['kind'] == 'see');
      expect(see['presentation'], 'naming_customs');
      final customs = see['naming_customs'] as Map<String, dynamic>;
      expect(customs['kinship_introduction_claim'], isNotEmpty);

      final card = _cultureCard(lang, '${lang}.culture.kinship');
      expect(card, isNotNull);
      expect(customs['culture_card_id'], card!['id']);
      expect(
        (card!['claims'] as List).first as Map<String, dynamic>,
        containsPair('text', customs['kinship_introduction_claim']),
      );
    }
  });

  test('AC3: taboo tutorials expose list slot; topics require citations to publish',
      () {
    for (final tRaw in taboo['tutorials'] as List) {
      final t = tRaw as Map<String, dynamic>;
      final steps = t['steps'] as List;
      expect(_runtimeSeconds(steps), inInclusiveRange(60, 90));
      final see = steps
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['kind'] == 'see');
      expect(see['presentation'], 'taboo_topic_list');
      expect(see['taboo_topics_gate'], 'EXT-14_cultural_consultant');
      expect(see['taboo_topics'], isA<List>());
    }
    expect(_canPublish(taboo), isFalse);
  });

  test('AC4: sign-off requirements list cultural consultant and native per tutorial',
      () {
    for (final pack in [greetings, naming, taboo]) {
      final reqs = pack['sign_off_requirements'] as List;
      expect(reqs.length, _stage1.length);
      for (final reqRaw in reqs) {
        final req = reqRaw as Map<String, dynamic>;
        final roles = (req['roles'] as List).cast<String>();
        expect(roles, contains('cultural_consultant'));
        expect(roles, contains('native'));
      }
    }
  });
}
