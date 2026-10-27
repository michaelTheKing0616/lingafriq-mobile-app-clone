import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_suggest_client.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/lens/lens_collection_service.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/point_say_dictionary.dart';
import 'package:lingafriq/services/learning/spaced_repetition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AfricanObjectSet _fixtureSet() {
  final path = File('assets/lens/african_object_set.json').absolute;
  final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
  final set = AfricanObjectSet.fromJson(json);
  AfricanObjectSet.validateContent(set);
  return set;
}

VerifiedLexeme _yoCupLexeme() {
  return VerifiedLexeme(
    lexemeId: 'yo.lex.418526e95cbc',
    language: 'yo',
    verificationStatus: 'expert_reviewed',
    lemma: 'ago',
    standardOrthography: 'ago',
    exampleSentence: 'Mo ní ago.',
    audioUris: const ['https://cdn.example/ago.mp3'],
    raw: const {},
  );
}

void main() {
  late ObjectSetMapper mapper;

  setUp(() {
    mapper = ObjectSetMapper(_fixtureSet());
  });

  group('PointSayDictionaryService', () {
    test('resolveEntry maps Cup to lexeme word and example', () async {
      final service = PointSayDictionaryService(
        mapper: mapper,
        labelResolver: LexiconLabelResolver(
          fetchLexeme: (_) async => _yoCupLexeme(),
        ),
        fetchLexeme: (_) async => _yoCupLexeme(),
      );

      final entry = await service.resolveEntry(
        mlKitLabel: 'Cup',
        learnerLanguageCode: 'yoruba',
      );

      expect(entry, isNotNull);
      expect(entry!.card.word, 'ago');
      expect(entry.card.exampleSentence, 'Mo ní ago.');
      expect(entry.playbackHit.humanAudioUrl, contains('ago.mp3'));
    });

    test('describeMiss for unmapped label', () {
      final service = PointSayDictionaryService(
        mapper: mapper,
        labelResolver: LexiconLabelResolver(fetchLexeme: (_) async => null),
        fetchLexeme: (_) async => null,
      );
      final miss = service.describeMiss('UnknownWidget');
      expect(miss.mappedObject, isFalse);
      expect(miss.mlKitLabel, 'UnknownWidget');
    });

    test('queueLearnerSuggestion passes lemma and gloss verbatim', () async {
      String? capturedLemma;
      String? capturedGloss;
      final service = PointSayDictionaryService(
        mapper: mapper,
        labelResolver: LexiconLabelResolver(fetchLexeme: (_) async => null),
        fetchLexeme: (_) async => null,
        suggestClient: LexiconSuggestClient(
          post: (_, {data}) async {
            capturedLemma = data?['lemma'] as String?;
            capturedGloss = data?['gloss_en'] as String?;
            return {
              'suggestion': {
                'suggestion_id': 's1',
                'language': 'yo',
                'lemma': capturedLemma,
                'gloss_en': capturedGloss,
                'status': 'pending',
                'lexeme_id': '',
              },
            };
          },
        ),
      );

      await service.queueLearnerSuggestion(
        languageCode: 'yoruba',
        lemmaSubmitted: 'ọkọ̀',
        glossSubmitted: 'Cup',
      );
      expect(capturedLemma, 'ọkọ̀');
      expect(capturedGloss, 'Cup');
    });

    test('saveToCollection dedupes by verified lexeme id', () async {
      SharedPreferences.setMockInitialValues({});
      SpacedRepetitionService().clearUserCards('u1');
      final collection = LensCollectionService();
      final card = LensWordCard(
        lexemeId: 'yo.lex.418526e95cbc',
        language: 'yo',
        word: 'ago',
        objectSetId: 'afr.cup',
        exampleSentence: 'Mo ní ago.',
        audio: const LensWordCardAudio(
          kind: LensWordCardAudioKind.nativeHuman,
          playUri: 'https://cdn.example/ago.mp3',
        ),
      );
      final service = PointSayDictionaryService(
        mapper: mapper,
        labelResolver: LexiconLabelResolver(fetchLexeme: (_) async => null),
        fetchLexeme: (_) async => null,
        collectionService: collection,
      );

      final first = await service.saveToCollection(
        userId: 'u1',
        card: card,
        attemptServerSync: false,
      );
      final second = await service.saveToCollection(
        userId: 'u1',
        card: card,
        attemptServerSync: false,
      );
      expect(first.created, isTrue);
      expect(second.created, isFalse);
      expect(second.item.verifiedLexemeId, first.item.verifiedLexemeId);
    });
  });

  group('PointSayDictionarySheet goldens', () {
    testWidgets('entry state shows word and example', (tester) async {
      final service = PointSayDictionaryService(
        mapper: mapper,
        labelResolver: LexiconLabelResolver(
          fetchLexeme: (_) async => _yoCupLexeme(),
        ),
        fetchLexeme: (_) async => _yoCupLexeme(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointSayDictionarySheet(
              service: service,
              mlKitLabel: 'Cup',
              learnerLanguageCode: 'yoruba',
              userId: 'u1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ago'), findsOneWidget);
      expect(find.text('Mo ní ago.'), findsOneWidget);
      expect(find.text(lensPointSayPlayExample), findsOneWidget);
    });

    testWidgets('not_in_dictionary state is announced', (tester) async {
      final service = PointSayDictionaryService(
        mapper: mapper,
        labelResolver: LexiconLabelResolver(fetchLexeme: (_) async => null),
        fetchLexeme: (_) async => null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointSayDictionarySheet(
              service: service,
              mlKitLabel: 'UnknownWidget',
              learnerLanguageCode: 'yoruba',
              userId: 'u1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(lensPointSayNotInDictionary), findsOneWidget);
      expect(find.text(lensPointSaySuggestLabel), findsOneWidget);
    });
  });
}
