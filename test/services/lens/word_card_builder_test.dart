import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_audio_client.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/lens/word_card_builder.dart';
import 'package:lingafriq/services/tts/dynamic_tts_label.dart';

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

VerifiedLexeme _swNounWithClass() {
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': 'sw.lex.kichwa.head',
    'language': 'sw',
    'verification_status': 'expert_reviewed',
    'entry': {
      'id': 'sw.lex.kichwa.head',
      'lemma': 'kichwa',
      'orthography': {
        'standard': 'kichwa',
        'ascii_fallback': 'kichwa',
        'script': 'Latn',
      },
      'pos': 'noun',
      'noun_class': {
        'sg': '7',
        'pl': '8',
        'plural_form': 'vichwa',
      },
      'senses': [
        {
          'gloss_en': 'head',
          'gloss_fr': 'tête',
          'domain': 'body',
          'register': 'neutral',
          'example_target': 'Nina maumivu ya kichwa.',
        },
      ],
      'cefr': 'A1',
      'frequency_rank': 120,
      'label': 'expert_reviewed',
      'provenance': {
        'author': 'test',
        'created_at': '2026-10-27T00:00:00Z',
        'ai_assisted': false,
        'sources': [
          {
            'name': 'fixture',
            'licence': 'CC BY 4.0',
            'uri_or_citation': 'test',
            'retrieved_at': '2026-10-27T00:00:00Z',
          },
        ],
      },
      'claims': [
        {'kind': 'linguistic', 'source_ref': 'fixture'},
      ],
      'confidence': 0.9,
      'risk_tags': [],
      'audio': [],
    },
  });
}

LensLexiconLabel _verifiedLabel(String lexemeId) {
  return LensLexiconLabel(
    kind: LensLexiconLabelKind.verified,
    objectSetId: 'afr.head',
    livingDictionaryLexemeId: lexemeId,
    learnerLanguageCode: 'yoruba',
    displayWord: 'ọkọ̀',
    verificationStatus: 'expert_reviewed',
  );
}

void main() {
  group('WordCardBuilder', () {
    test('verified Yoruba card carries tone-marked word and example', () {
      final lexeme = _yoOkoVerified();
      final builder = WordCardBuilder();
      final card = builder.build(
        label: _verifiedLabel(lexeme.lexemeId),
        lexeme: lexeme,
      );

      expect(card.word, 'ọkọ̀');
      expect(card.word, isNot(contains('oko')));
      expect(card.exampleSentence, isNotNull);
      expect(card.audio.kind, LensWordCardAudioKind.nativeHuman);
      expect(card.audio.presentsAsNative, isTrue);
      expect(card.audio.showsSyntheticLabel, isFalse);
    });

    test('native audio bundle wins over empty lexeme audio list', () {
      final lexeme = _swNounWithClass();
      final bundle = LexiconAudioBundle.fromApiJson({
        'lexeme_id': lexeme.lexemeId,
        'language': 'sw',
        'recordings': [
          {
            'voice_id': 'sw_f_01',
            'uri': 'audio/sw/abc12345.ogg',
            'speed': 'natural',
            'speaker_age_band': 'adult',
            'speaker_gender': 'f',
            'aligned_phones': [],
          },
        ],
        'needs_more_voices': false,
        'playable_count': 1,
      });
      final card = WordCardBuilder().build(
        label: LensLexiconLabel(
          kind: LensLexiconLabelKind.verified,
          objectSetId: 'afr.head',
          livingDictionaryLexemeId: lexeme.lexemeId,
          learnerLanguageCode: 'swahili',
        ),
        lexeme: lexeme,
        audioBundle: bundle,
      );

      expect(card.nounClass?.singularClass, '7');
      expect(card.nounClass?.pluralClass, '8');
      expect(card.nounClass?.pluralForm, 'vichwa');
      expect(card.audio.playUri, 'audio/sw/abc12345.ogg');
      expect(card.audio.presentsAsNative, isTrue);
    });

    test('no native audio uses labelled TTS when tonal gate passes', () {
      final lexeme = _swNounWithClass();
      final card = WordCardBuilder().build(
        label: LensLexiconLabel(
          kind: LensLexiconLabelKind.verified,
          objectSetId: 'afr.head',
          livingDictionaryLexemeId: lexeme.lexemeId,
          learnerLanguageCode: 'swahili',
        ),
        lexeme: lexeme,
      );

      expect(card.audio.kind, LensWordCardAudioKind.licensedTts);
      expect(card.audio.honestyLabel, dynamicSpeechSyntheticVoiceTag);
      expect(card.audio.presentsAsNative, isFalse);
    });

    test('Yoruba without tone marks blocks TTS and shows no recording', () {
      final lexeme = VerifiedLexeme(
        lexemeId: 'yo.lex.oko.unmarked',
        language: 'yo',
        verificationStatus: 'expert_reviewed',
        lemma: 'oko',
        standardOrthography: 'oko',
        exampleSentence: null,
        audioUris: const [],
        raw: const {
          'lemma': 'oko',
          'orthography': {'standard': 'oko'},
          'audio': [],
        },
      );
      final card = WordCardBuilder().build(
        label: _verifiedLabel(lexeme.lexemeId),
        lexeme: lexeme,
      );

      expect(card.audio.kind, LensWordCardAudioKind.noRecordingYet);
      expect(card.audio.tonalGatePassed, isFalse);
      expect(card.audio.presentsAsNative, isFalse);
    });

    test('lensTonalTtsGateAllows respects yo tone marks', () {
      expect(lensTonalTtsGateAllows('yo', 'ọkọ̀'), isTrue);
      expect(lensTonalTtsGateAllows('yo', 'oko'), isFalse);
    });
  });
}
