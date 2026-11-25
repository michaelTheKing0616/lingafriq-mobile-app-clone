import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';

VerifiedLexeme _yoOkoVerified() {
  final fixturePath = File(
    'test/content/fixtures/lexeme_yo_oko.json',
  ).absolute.path;
  final fixture =
      jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': fixture['id'],
    'language': 'yo',
    'verification_status': 'expert_reviewed',
    'entry': fixture,
  });
}

void main() {
  group('LexiconLabelResolver', () {
    test('returns verified orthography for expert_reviewed lexeme', () async {
      final resolver = LexiconLabelResolver(
        fetchLexeme: (_) async => _yoOkoVerified(),
      );
      final label = await resolver.resolveForMappedObject(
        objectSetId: 'afr.cup',
        livingDictionaryLexemeId: 'yo.lex.ọkọ.vehicle',
        learnerLanguageCode: 'yoruba',
      );
      expect(label.kind, LensLexiconLabelKind.verified);
      expect(label.displayWord, 'ọkọ̀');
      expect(label.showsAiDraftBadge, isFalse);
    });

    test('beta label is AI draft with honest badge and verify queue', () async {
      var queued = false;
      final resolver = LexiconLabelResolver(
        fetchLexeme: (_) async {
          final row = _yoOkoVerified();
          return VerifiedLexeme(
            lexemeId: row.lexemeId,
            language: row.language,
            verificationStatus: 'beta',
            lemma: row.lemma,
            standardOrthography: row.standardOrthography,
            exampleSentence: row.exampleSentence,
            audioUris: row.audioUris,
            raw: row.raw,
          );
        },
        enqueueVerify: ({
          required String lexemeId,
          required String objectSetId,
          required String learnerLanguageCode,
        }) async {
          queued = true;
          expect(lexemeId, 'yo.lex.ọkọ.vehicle');
          expect(objectSetId, 'afr.cup');
          return true;
        },
      );
      final label = await resolver.resolveForMappedObject(
        objectSetId: 'afr.cup',
        livingDictionaryLexemeId: 'yo.lex.ọkọ.vehicle',
        learnerLanguageCode: 'yoruba',
      );
      expect(label.kind, LensLexiconLabelKind.aiDraft);
      expect(label.overlayHonestLabel, lensAiDraftHonestLabel);
      expect(queued, isTrue);
    });

    test('missing lexeme queues verify without inventing a word', () async {
      var queued = false;
      final resolver = LexiconLabelResolver(
        fetchLexeme: (_) async => null,
        enqueueVerify: ({
          required String lexemeId,
          required String objectSetId,
          required String learnerLanguageCode,
        }) async {
          queued = true;
          return true;
        },
      );
      final label = await resolver.resolveForMappedObject(
        objectSetId: 'afr.cup',
        livingDictionaryLexemeId: 'yo.lex.ọkọ.vehicle',
        learnerLanguageCode: 'yoruba',
      );
      expect(label.kind, LensLexiconLabelKind.missingLexeme);
      expect(label.displayWord, isNull);
      expect(queued, isTrue);
    });
  });

  group('Lens flow lint', () {
    test('lib/services/lens has no NLLB, MyMemory, or translation_service imports',
        () {
      final lensDir = Directory('lib/services/lens');
      final violations = <String>[];
      for (final entity in lensDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        if (text.contains('translation_service.dart') ||
            text.contains('NLLB') ||
            text.contains('MyMemory') ||
            text.contains('nllb-200')) {
          violations.add(entity.path);
        }
      }
      expect(violations, isEmpty);
    });

    test('TranslationService documents NC harvest callers', () {
      final src = File('lib/services/hybrid_polie/translation_service.dart')
          .readAsStringSync();
      expect(src, contains('P7-905 harvest'));
      expect(src, contains('resolveLensWordForObject'));
    });
  });
}
