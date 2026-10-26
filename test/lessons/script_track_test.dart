import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/content/label_state.dart';
import 'package:lingafriq/lessons/script_track.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  late ScriptTracksCatalog catalog;
  late List<ScriptLesson> geezLessons;

  setUp(() {
    catalog = loadScriptTracksCatalogFromJson(
      _read('assets/data/scripts/tracks_catalog.json'),
    );
    geezLessons = loadScriptLessonsFromJson(
      _read('assets/data/scripts/fidel_geez_lessons.json'),
    );
  });

  group('track loader', () {
    test('catalog parses all five script systems', () {
      expect(catalog.tracks.keys, containsAll(['geez_fidel', 'nko', 'adlam', 'tifinagh', 'ajami']));
    });
  });

  group('Ge\'ez/Fidel for Amharic and Tigrinya (AC1)', () {
    test('Amharic opens Fidel lessons', () {
      final view = resolveScriptTrack(
        catalog: catalog,
        languageCode: 'am',
        geezLessons: geezLessons,
      );
      expect(view.descriptor.scriptId, 'geez_fidel');
      expect(view.uiState, ScriptTrackUiState.list);
      expect(view.lessons, isNotEmpty);
      expect(view.lessons.first.glyphs.first.character, '\u1200');
    });

    test('Tigrinya shares Fidel track with lessons', () {
      final view = resolveScriptTrack(
        catalog: catalog,
        languageCode: 'ti',
        geezLessons: geezLessons,
      );
      expect(view.lessons, isNotEmpty);
      expect(
        view.lessons.every((l) => l.languageCodes.contains('ti') || l.languageCodes.contains('am')),
        isTrue,
      );
    });
  });

  group('coming-later scripts (AC2)', () {
    test('N\'Ko track is coming later with no lessons', () {
      final view = resolveScriptTrack(
        catalog: catalog,
        languageCode: 'bm-nko',
        geezLessons: geezLessons,
      );
      expect(view.uiState, ScriptTrackUiState.comingLater);
      expect(view.lessons, isEmpty);
    });

    test('Adlam, Tifinagh and Ajami resolve to coming-later', () {
      for (final code in ['ff-adlm', 'tzm-tfng', 'ha-arab']) {
        final view = resolveScriptTrack(
          catalog: catalog,
          languageCode: code,
          geezLessons: geezLessons,
        );
        expect(view.isComingLater, isTrue);
      }
    });
  });

  group('label honesty (AC3)', () {
    test('unreviewed label fails closed at parse time', () {
      expect(
        () => parseScriptLessonsFile({
          'lessons': [
            {
              'lesson_id': 'bad',
              'title': 'x',
              'label': 'draft',
              'language_codes': ['am'],
              'glyphs': [],
            },
          ],
        }),
        throwsA(isA<ScriptContentMislabeled>()),
      );
    });

    test('beta and reviewed lessons are displayable', () {
      for (final lesson in geezLessons) {
        expect(isScriptLessonDisplayable(lesson.label), isTrue);
      }
    });

    test('verified presentation only for expert or native labels', () {
      expect(
        wouldPresentAsVerified(ContentQualityLabel.expertReviewed),
        isTrue,
      );
      expect(wouldPresentAsVerified(ContentQualityLabel.beta), isFalse);
    });
  });

  testWidgets('coming-later panel is screen-reader labelled', (tester) async {
    final view = resolveScriptTrack(
      catalog: catalog,
      languageCode: 'ff-nko',
      geezLessons: geezLessons,
    );
    await tester.pumpWidget(
      MaterialApp(home: ScriptTrackPanel(view: view)),
    );
    expect(find.text(ScriptTrackCopyKeys.defaultComingLater), findsOneWidget);
  });
}
