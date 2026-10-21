// P1-030 Spec-Tests (Mode A): AC1–AC4. Derived from acceptance criteria only.
// Scans shipped JSON from a subprocess; does not invent curriculum text.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _gameContent = 'assets/data/game_content.json';
const _curriculum = 'assets/data/lingafriq_authentic_curriculum_a1_c2.json';
const _toneLinter = 'scripts/ci/check_tone_claims.py';
const _quarantine = 'assets/data/quarantine/game_content_false_claims.jsonl';

const _falseToneClaim = 'High tone on àárọ̀ marks respect';
const _falseAffixClaim =
    'Listen for the verb stem; affixes carry tense and person.';
const _falseSvoClaim = 'Pattern: subject → verb → object';

const _scanPy = r'''
import json, sys
from pathlib import Path

FALSE_TONE = "High tone on àárọ̀ marks respect"
FALSE_AFFIX = "Listen for the verb stem; affixes carry tense and person."
FALSE_SVO = "Pattern: subject → verb → object"
CITE_MARKERS = ("elevation", "public-domain", "public domain", "public_domain")
NATIVE_MARKERS = ("native-verified", "native_verified", "native verified")

def words_of(data):
    if isinstance(data, list):
        return [w for w in data if isinstance(w, dict)]
    if isinstance(data, dict):
        for key in ("words", "vocabulary", "items"):
            val = data.get(key)
            if isinstance(val, list):
                return [w for w in val if isinstance(w, dict)]
    return []

def cited(blob: str) -> bool:
    low = blob.lower()
    return any(m in low for m in CITE_MARKERS)

def native_verified(blob: str) -> bool:
    low = blob.lower()
    return any(m in low for m in NATIVE_MARKERS)

def walk_grammar(node, out):
    if isinstance(node, dict):
        g = node.get("grammar")
        if isinstance(g, list):
            out.extend(str(x) for x in g if x is not None and str(x).strip())
        for v in node.values():
            walk_grammar(v, out)
    elif isinstance(node, list):
        for v in node:
            walk_grammar(v, out)

cmd = sys.argv[1]
if cmd == "ac1":
    game = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    words = words_of(game)
    w1 = next((w for w in words if w.get("id") in (1, "1")), None)
    w1_blob = json.dumps(w1, ensure_ascii=False) if w1 else ""
    copied = sum(
        1
        for w in words
        if (w.get("phonetic_guide") or "")
        and w.get("phonetic_guide") == w.get("tonal_note")
    )
    curr_text = Path(sys.argv[3]).read_text(encoding="utf-8")
    print(json.dumps({
        "word1_found": w1 is not None,
        "word1_has_false_tone": FALSE_TONE in w1_blob,
        "copied_guide_count": copied,
        "curriculum_has_affix_claim": FALSE_AFFIX in curr_text,
        "curriculum_has_svo_claim": FALSE_SVO in curr_text,
    }, ensure_ascii=False))
elif cmd == "ac4":
    game = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    words = words_of(game)
    uncited_tone = 0
    native_tone = 0
    remaining_tone = 0
    for w in words:
        note = (w.get("tonal_note") or "").strip()
        guide = (w.get("phonetic_guide") or "").strip()
        teaching = []
        if note:
            teaching.append(note)
        if guide and guide == note:
            teaching.append(guide)
        if not teaching:
            continue
        remaining_tone += 1
        blob = json.dumps(w, ensure_ascii=False)
        if not cited(blob):
            uncited_tone += 1
        if native_verified(blob):
            native_tone += 1
    curr = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
    grammar = []
    walk_grammar(curr, grammar)
    uncited_grammar = 0
    native_grammar = 0
    beta_grammar = 0
    for item in grammar:
        if FALSE_AFFIX in item or FALSE_SVO in item:
            beta_grammar += 1
        blob = item
        if not cited(blob):
            uncited_grammar += 1
        if native_verified(blob):
            native_grammar += 1
    print(json.dumps({
        "remaining_tone_claims": remaining_tone,
        "uncited_tone_claims": uncited_tone,
        "native_verified_tone_claims": native_tone,
        "remaining_grammar_tips": len(grammar),
        "uncited_grammar_tips": uncited_grammar,
        "native_verified_grammar_tips": native_grammar,
        "beta_grammar_tips": beta_grammar,
        "false_tone_still_shipped": any(
            FALSE_TONE in json.dumps(w, ensure_ascii=False) for w in words
        ),
    }, ensure_ascii=False))
else:
    raise SystemExit("unknown scan command")
''';

Map<String, dynamic> _scan(String command) {
  final r = Process.runSync('python3', ['-c', _scanPy, command, _gameContent, _curriculum]);
  expect(r.exitCode, 0, reason: 'scanner failed: ${r.stderr}\n${r.stdout}');
  return jsonDecode('${r.stdout}') as Map<String, dynamic>;
}

List<String> _pubspecAssetEntries() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final start = lines.indexWhere((l) => l.trim() == 'assets:');
  final dirs = <String>[];
  for (var i = start + 1; i < lines.length; i++) {
    final m = RegExp(r'^\s+-\s+(\S+)\s*$').firstMatch(lines[i]);
    if (m == null) break;
    dirs.add(m.group(1)!);
  }
  return dirs;
}

bool _pubspecShips(String path) {
  return _pubspecAssetEntries().any((entry) {
    final prefix = entry.endsWith('/') ? entry : '$entry/';
    return path == entry || path.startsWith(prefix);
  });
}

void main() {
  test('P1-030_AC1_shipped_assets_drop_false_tone_guides_and_grammar_notes', () {
    expect(File(_gameContent).existsSync(), isTrue);
    expect(File(_curriculum).existsSync(), isTrue);
    final s = _scan('ac1');
    expect(s['word1_found'], isTrue, reason: 'word id 1 must exist to be audited');
    expect(s['word1_has_false_tone'], isFalse,
        reason: 'word id 1 still ships "$_falseToneClaim"');
    expect(s['copied_guide_count'], 0,
        reason: 'phonetic_guide still equals tonal_note on ${s['copied_guide_count']} words');
    expect(s['curriculum_has_affix_claim'], isFalse,
        reason: 'curriculum still ships "$_falseAffixClaim"');
    expect(s['curriculum_has_svo_claim'], isFalse,
        reason: 'curriculum still ships "$_falseSvoClaim"');
  });

  test('P1-030_AC2_check_tone_claims_fails_when_phonetic_guide_equals_tonal_note',
      () {
    final script = File(_toneLinter);
    expect(script.existsSync(), isTrue,
        reason: '$_toneLinter must exist; missing script is a failure');

    final tmp = Directory.systemTemp.createTempSync('p1_030_tone_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final fixture = File('${tmp.path}/copied_guide.json')
      ..writeAsStringSync(jsonEncode({
        'words': [
          {
            'id': 1,
            'language': 'yoruba',
            'word': 'àárọ̀',
            'english_meaning': 'morning',
            'phonetic_guide': 'copied-note',
            'tonal_note': 'copied-note',
          }
        ]
      }));

    final r = Process.runSync('python3', [_toneLinter, fixture.path]);
    expect(r.exitCode, isNot(0),
        reason: 'copied phonetic_guide==tonal_note must fail CI: '
            '${r.stdout}\n${r.stderr}');
  });

  test('P1-030_AC3_quarantine_archives_removed_entries_with_reason_codes', () {
    final q = File(_quarantine);
    expect(q.existsSync(), isTrue, reason: '$_quarantine must archive removals');
    expect(_pubspecShips(_quarantine), isFalse,
        reason: '$_quarantine must be excluded from pubspec flutter assets');

    final rows = q
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    expect(rows, isNotEmpty, reason: 'quarantine must list removed entries');
    for (final line in rows) {
      final row = jsonDecode(line) as Map<String, dynamic>;
      final code = row['reason_code'] ?? row['reason'];
      expect(code, isA<String>(), reason: 'each entry needs a reason code: $line');
      expect((code as String).trim(), isNotEmpty,
          reason: 'reason code must be non-empty: $line');
    }
  });

  test(
      'P1-030_AC4_shipped_replacements_cite_source_and_are_not_native_verified_beta',
      () {
    final s = _scan('ac4');
    expect(s['false_tone_still_shipped'], isFalse,
        reason: 'uncitable false tone claim is still in the shipped asset');
    expect(s['beta_grammar_tips'], 0,
        reason: 'model-written Beta grammar tips are still shipped');
    expect(s['uncited_tone_claims'], 0,
        reason: 'tone replacements need an elevation-audit or public-domain citation');
    expect(s['native_verified_tone_claims'], 0,
        reason: 'replacements must not be labelled native-verified');
    expect(s['uncited_grammar_tips'], 0,
        reason: 'grammar replacements need an elevation-audit or public-domain citation');
    expect(s['native_verified_grammar_tips'], 0,
        reason: 'grammar replacements must not be labelled native-verified');
  });
}
