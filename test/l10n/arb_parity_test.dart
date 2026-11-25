// P5-006: Yoruba ARB parity (103 keys) and diacritic / review gates.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _yoArb = 'lib/l10n/app_yo.arb';
const _igArb = 'lib/l10n/app_ig.arb';
const _enArb = 'lib/l10n/app_en.arb';
const _pcmArb = 'lib/l10n/app_pcm.arb';
const _legacyBaseline = 62;
const _targetKeys = 103;

const _bannedBareForms = <String>['Omo', 'Eniyan', 'Okunrin'];

const _lintYoPy = r'''
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))
from tools.content_engine.linters.yoruba import lint_yoruba

def lint_text(key: str, text: str):
    tokens = [{"surface": t, "lexicon": t, "syllabic": False} for t in text.split() if t]
    if not tokens:
        tokens = [{"surface": text, "lexicon": text, "syllabic": False}]
    item = {"id": key, "learner_facing": True, "tokens": tokens}
    return lint_yoruba(item, {"lang": "yo"})

arb = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
failures = []
for key, value in arb.items():
    if key.startswith("@") or not isinstance(value, str):
        continue
    meta = arb.get("@" + key)
    if not isinstance(meta, dict) or meta.get("lexiconAnchored") is not True:
        continue
    result = lint_text(key, value)
    if result.status != "pass":
        failures.append({"key": key, "rule": result.rule_id, "text": value})
print(json.dumps({"failures": failures}, ensure_ascii=False))
''';

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

Set<String> _requiredYoKeys(Map<String, dynamic> en, Map<String, dynamic> pcm, Map<String, dynamic> ig) {
  final legacy = _messageKeys(en).intersection(_messageKeys(pcm));
  final extension = (_messageKeys(ig).difference(legacy)).toList()..sort();
  return legacy.union(extension.take(41).toSet());
}

void main() {
  test('P5-006 AC1: app_yo.arb has 103 legacy-parity keys', () {
    final yo = jsonDecode(File(_yoArb).readAsStringSync()) as Map<String, dynamic>;
    final ig = jsonDecode(File(_igArb).readAsStringSync()) as Map<String, dynamic>;
    final en = jsonDecode(File(_enArb).readAsStringSync()) as Map<String, dynamic>;
    final pcm = jsonDecode(File(_pcmArb).readAsStringSync()) as Map<String, dynamic>;
    final yoKeys = _messageKeys(yo);
    final required = _requiredYoKeys(en, pcm, ig);

    expect(yoKeys.length, _targetKeys);
    expect(required.length, _targetKeys);
    expect(yoKeys, required);
    expect(yoKeys.length, greaterThanOrEqualTo(_legacyBaseline));
  });

  test('P5-006 AC2: no bare Omo / Eniyan / Okunrin forms', () {
    final yo = jsonDecode(File(_yoArb).readAsStringSync()) as Map<String, dynamic>;
    for (final entry in yo.entries) {
      if (entry.key.startsWith('@') || entry.value is! String) continue;
      final text = entry.value as String;
      for (final banned in _bannedBareForms) {
        expect(
          RegExp(r'\b' + banned + r'\b').hasMatch(text),
          isFalse,
          reason: '${entry.key} contains bare $banned',
        );
      }
    }
  });

  test('P5-006 AC2/AC3: lexicon-anchored strings pass Yoruba lint; review strings gated', () {
    final yo = jsonDecode(File(_yoArb).readAsStringSync()) as Map<String, dynamic>;

    for (final key in _messageKeys(yo)) {
      final meta = yo['@$key'];
      expect(meta, isA<Map<String, dynamic>>(), reason: 'missing @$key metadata');
      final map = meta as Map<String, dynamic>;
      final anchored = map['lexiconAnchored'] == true;
      final review = map['linguistReview'] == true;
      final beta = map['betaShipAllowed'] == true;
      expect(anchored || review, isTrue, reason: key);
      if (review) {
        expect(beta, isFalse, reason: '$key must not ship as Beta while in review');
      }
    }

    final result = Process.runSync('python3', ['-c', _lintYoPy, _yoArb]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final payload = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final failures = payload['failures'] as List<dynamic>;
    expect(failures, isEmpty, reason: failures.toString());
  });
}
