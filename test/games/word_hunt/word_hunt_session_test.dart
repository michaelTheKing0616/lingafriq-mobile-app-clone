import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/word_hunt/word_hunt_screen.dart';
import 'package:lingafriq/games/word_hunt/word_hunt_session.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/lens/point_say_dictionary.dart';

AfricanObjectSet _fixtureSet() {
  final path = File('assets/lens/african_object_set.json').absolute;
  final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
  return AfricanObjectSet.fromJson(json);
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

PointSayDictionaryService _dictionaryService(ObjectSetMapper mapper) {
  return PointSayDictionaryService(
    mapper: mapper,
    labelResolver: LexiconLabelResolver(
      fetchLexeme: (_) async => _yoCupLexeme(),
    ),
    fetchLexeme: (_) async => _yoCupLexeme(),
  );
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: child),
  );
}

void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late ObjectSetMapper mapper;

  setUp(() {
    mapper = ObjectSetMapper(_fixtureSet());
  });

  group('WordHuntSession', () {
    test('found only on a listed label with sufficient confidence', () {
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'Cup', displayLabel: 'Cup'),
          WordHuntTarget(classifierLabel: 'Bowl', displayLabel: 'Bowl'),
        ],
        mapper: mapper,
      );

      expect(
        session.pickListedLabel([
          const ObjectClassificationLabel(label: 'Chair', score: 0.9),
        ]),
        isNull,
      );
      expect(
        session.pickListedLabel([
          const ObjectClassificationLabel(label: 'Cup', score: 0.1),
        ]),
        isNull,
      );
      expect(
        session.pickListedLabel([
          const ObjectClassificationLabel(label: 'Cup', score: 0.5),
        ]),
        'Cup',
      );
    });

    test('not in dictionary does not mark found', () {
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'UnknownWidget', displayLabel: 'Gadget'),
        ],
        mapper: mapper,
      );
      expect(session.isMappedInDictionary('UnknownWidget'), isFalse);
      final outcome = session.applyDictionaryResult(
        classifierLabel: 'UnknownWidget',
        dictionaryHit: false,
      );
      expect(outcome.kind, WordHuntFrameOutcomeKind.notInDictionary);
      expect(session.isComplete, isFalse);
    });

    test('dictionary hit marks found and completes hunt', () {
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'Cup', displayLabel: 'Cup'),
        ],
        mapper: mapper,
      );
      final outcome = session.applyDictionaryResult(
        classifierLabel: 'Cup',
        dictionaryHit: true,
        spokenWord: 'ago',
      );
      expect(outcome.kind, WordHuntFrameOutcomeKind.huntComplete);
      expect(session.progress().first.status, WordHuntItemStatus.found);
    });

    test('offline path never records upload attempts by default', () {
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'Cup', displayLabel: 'Cup'),
        ],
        mapper: mapper,
      );
      expect(session.uploadAttempts, 0);
    });
  });

  group('WordHuntScreen integration', () {
    testWidgets('airplane mode scan uses on-device labels only', (tester) async {
      _phoneSurface(tester);
      var uploads = 0;
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'Cup', displayLabel: 'Cup'),
        ],
        mapper: mapper,
      );
      final dictionary = _dictionaryService(mapper);
      var spoke = <String>[];

      await tester.pumpWidget(
        _wrap(
          WordHuntScreen(
            language: 'yoruba',
            session: session,
            dictionaryService: dictionary,
            hasInternet: () async => false,
            classifyFrame: () async => [
              const ObjectClassificationLabel(label: 'Cup', score: 0.55),
            ],
            onSpeakWord: (w) async => spoke.add(w),
            debugPreview: const ColoredBox(color: Color(0xFF112233)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan object'));
      await tester.pumpAndSettle();

      expect(uploads, 0);
      expect(session.uploadAttempts, 0);
      expect(spoke, ['ago']);
      expect(find.text(wordHuntCompleteMessage), findsOneWidget);
    });

  });

  group('WordHuntScreen goldens', () {
    testWidgets('hunting checklist layout', (tester) async {
      _phoneSurface(tester);
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'Cup', displayLabel: 'Cup'),
          WordHuntTarget(classifierLabel: 'Bowl', displayLabel: 'Bowl'),
        ],
        mapper: mapper,
      );

      await tester.pumpWidget(
        _wrap(
          WordHuntScreen(
            language: 'yoruba',
            session: session,
            dictionaryService: _dictionaryService(mapper),
            debugPreview: const ColoredBox(color: Color(0xFF1B4332)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(WordHuntScreen),
        matchesGoldenFile('goldens/word_hunt_hunting.png'),
      );
    });

    testWidgets('complete state layout', (tester) async {
      _phoneSurface(tester);
      final session = WordHuntSession(
        targets: const [
          WordHuntTarget(classifierLabel: 'Cup', displayLabel: 'Cup'),
        ],
        mapper: mapper,
      );
      session.applyDictionaryResult(
        classifierLabel: 'Cup',
        dictionaryHit: true,
        spokenWord: 'ago',
      );

      await tester.pumpWidget(
        _wrap(
          WordHuntScreen(
            language: 'yoruba',
            session: session,
            dictionaryService: _dictionaryService(mapper),
            debugPreview: const ColoredBox(color: Color(0xFF1B4332)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(WordHuntScreen),
        matchesGoldenFile('goldens/word_hunt_complete.png'),
      );
    });
  });
}
