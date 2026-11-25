import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_models.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_scoring.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';
import 'package:lingafriq/models/verified_lexeme.dart';

String _modelsJson() =>
    File('assets/data/tone/models.json').readAsStringSync();

VerifiedLexeme _lex({
  required String id,
  required String form,
  required String status,
  List<String>? tonePattern,
}) {
  return VerifiedLexeme(
    lexemeId: id,
    language: 'yo',
    verificationStatus: status,
    lemma: form,
    standardOrthography: form,
    exampleSentence: 'gloss',
    audioUris: const [],
    raw: {
      'id': id,
      'lemma': form,
      'orthography': {'standard': form},
      if (tonePattern != null) 'tone_pattern': tonePattern,
    },
  );
}

void main() {
  late ToneModelsCatalog catalog;

  setUp(() {
    catalog = loadToneModelsCatalogFromJson(_modelsJson());
  });

  group('inventory loading', () {
    test('Yoruba pool uses H/M/L options from models.json', () {
      final model = resolveToneModel(catalog, 'yo');
      final options = toneInventoryOptions(model);
      expect(options.map((o) => o.code), ['H', 'M', 'L']);
    });

    test('Igbo pool uses H/L only (not global Yoruba mid)', () {
      final model = resolveToneModel(catalog, 'ig');
      final options = toneInventoryOptions(model);
      expect(options.map((o) => o.code), ['H', 'L']);
      expect(options.length, 2);
    });

    test('Hausa pool uses H/L/F', () {
      final model = resolveToneModel(catalog, 'ha');
      expect(toneInventoryOptions(model).map((o) => o.code), ['H', 'L', 'F']);
    });
  });

  group('pool exclusion', () {
    test('beta verification status is blocked', () {
      expect(
        isLexemeEligibleForToneGame(
          _lex(id: 'yo.a', form: 'ọkọ́', status: 'beta', tonePattern: ['H']),
        ),
        isFalse,
      );
    });

    test('excludes beta and missing tone_pattern', () {
      final result = buildToneGamePoolFromLexemes(
        lexemes: [
          _lex(id: 'yo.a', form: 'ọkọ́', status: 'beta', tonePattern: ['H']),
          _lex(id: 'yo.b', form: 'bkt', status: 'expert_reviewed'),
          _lex(
            id: 'yo.c',
            form: 'ọkọ̀',
            status: 'expert_reviewed',
            tonePattern: ['L'],
          ),
        ],
        catalog: catalog,
        languageCode: 'yo',
      );
      expect(result.diagnostics.excludedUnverified, 1);
      expect(result.diagnostics.excludedMissingTone, 1);
      expect(result.lexemes.length, 1);
      expect(result.lexemes.single.tonePattern, ['L']);
      expect(result.diagnostics.formatLine(), contains('excluded_unverified=1'));
    });
  });

  group('marked form parsing', () {
    test('derives tone from orthography when pattern absent', () {
      final model = resolveToneModel(catalog, 'yo');
      expect(
        parseTonePatternFromMarkedForm('ọkọ́', model),
        ['H'],
      );
      expect(
        parseTonePatternFromMarkedForm('ọkọ̀', model),
        ['L'],
      );
      expect(
        parseTonePatternFromMarkedForm('ọkọ', model),
        ['M'],
      );
    });
  });

  group('scoring', () {
    test('scores against lexicon pattern not global default', () {
      final ig = resolveToneModel(catalog, 'ig');
      final score = scoreToneInventoryChoice(
        inventory: ig,
        lexiconTonePattern: ['H'],
        syllableIndex: 0,
        selectedInventoryIndex: 0,
      );
      expect(score.isPerfect, isTrue);
    });
  });

  test('tone trainer sources do not hardcode global HML labels', () {
    final trainer = File('lib/screens/games/tone_trainer_game.dart')
        .readAsStringSync();
    expect(trainer, isNot(contains('á (High)')));
    expect(trainer, isNot(contains("'ā (Mid)'")));
    expect(trainer, isNot(contains('rng.nextInt(3)')));
  });
}
