import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/clip_template.dart';
void main() {
  tearDown(ClipTemplatePendingStore.clear);

  test('pending store hands off preset once', () {
    const preset = ClipTemplatePreset(
      languageTag: 'yo',
      suggestedCaption: 'ọkọ̀ — vehicle',
      kind: ClipTemplateKind.phraseOfDay,
      sourceId: 'yo.lex.1',
    );
    ClipTemplatePendingStore.set(preset);
    expect(ClipTemplatePendingStore.take(), preset);
    expect(ClipTemplatePendingStore.take(), isNull);
  });

  test('twister loads sourced minimal pair for yo', () async {
    const json = '''
{
  "languages": {
    "yo": {
      "drills": [
        {
          "pair_source_id": "yo.lex.vehicle",
          "prompt_gloss_en": "vehicle",
          "options": [
            {"form": "ọkọ́", "source_id": "register:fsi-yoruba"},
            {"form": "ọkọ̀", "source_id": "curriculum/lexicon/yo/vehicle-draft"}
          ]
        }
      ]
    }
  }
}
''';
    final repo = ClipTemplateRepository(
      readAsset: (path) async {
        expect(path, 'assets/data/tone/minimal_pairs.json');
        return json;
      },
    );
    final content = await repo.load(
      kind: ClipTemplateKind.tongueTwister,
      languageTag: 'yo',
    );
    expect(content, isNotNull);
    expect(content!.verificationStatus, 'expert_reviewed');
    expect(content.promptLines.first, contains('ọkọ́'));
  });

  test('proverb returns null when asset missing', () async {
    final repo = ClipTemplateRepository(
      readAsset: (_) async => throw Exception('missing'),
    );
    final content = await repo.load(
      kind: ClipTemplateKind.proverbExplainer,
      languageTag: 'yo',
    );
    expect(content, isNull);
  });

  test('pickFirstVerifiedProverb skips unreviewed rows', () {
    final picked = pickFirstVerifiedProverb([
      {
        'id': 'p1',
        'target_text': 'draft',
        'verification_status': 'beta',
      },
      {
        'id': 'p2',
        'target_text': 'Ìwà lẹwà',
        'verification_status': 'expert_reviewed',
      },
    ]);
    expect(picked?.headline, 'Ìwà lẹwà');
  });

}
