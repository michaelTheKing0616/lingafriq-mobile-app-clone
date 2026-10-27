import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';
import 'package:lingafriq/widgets/learning_path/polie_path_mascot.dart';

void main() {
  group('pathSceneryArtboardFor', () {
    test('yo unit alternates drummer and adire', () {
      expect(
        pathSceneryArtboardFor(languageKey: 'yo', unitIndex: 0),
        'yoruba_drummer',
      );
      expect(
        pathSceneryArtboardFor(languageKey: 'yo', unitIndex: 1),
        'yoruba_adireLine',
      );
      expect(
        pathSceneryArtboardFor(languageKey: 'Yoruba', unitIndex: 2),
        'yoruba_drummer',
      );
    });

    test('seven kit languages map to contract artboards', () {
      final langs = ['yo', 'ig', 'ha', 'zu', 'xh', 'sw', 'pcm'];
      for (final lang in langs) {
        final ab = pathSceneryArtboardFor(languageKey: lang, unitIndex: 0);
        expect(ab, isNotNull);
        expect(kPathSceneryArtboards, contains(ab));
      }
    });
  });

  group('pathParchmentColorFor', () {
    test('language themes differ', () {
      expect(
        pathParchmentColorFor('yo'),
        isNot(pathParchmentColorFor('ig')),
      );
    });
  });

  group('pathSceneDimmedForLesson', () {
    test('future lessons dim', () {
      expect(
        pathSceneDimmedForLesson(lessonIndex: 3, activeLessonIndex: 1),
        isTrue,
      );
      expect(
        pathSceneDimmedForLesson(lessonIndex: 1, activeLessonIndex: 1),
        isFalse,
      );
    });
  });

  group('path licence gate', () {
    late List<Map<String, dynamic>> register;

    setUp(() {
      final file = File('curriculum/sources/licence_register.json');
      register = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
    });

    test('path bundle ids are shippable in register', () {
      expect(pathLicenceGateForIds(register, kPathBundleLicenceIds), isTrue);
    });

    test('excluded row fails gate', () {
      expect(
        pathLicenceRowShippable({'licence': 'AGPL-3.0', 'use': 'excluded'}),
        isFalse,
      );
    });
  });

  group('PathSceneArtSlot widget', () {
    testWidgets('alt text and dim overlay', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PathSceneArtSlot(
              languageKey: 'ig',
              unitIndex: 0,
              dimmed: true,
              bundleLicensed: true,
            ),
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(PathSceneArtSlot));
      expect(semantics.label, contains('Igbo elder'));
      handle.dispose();
    });

    testWidgets('unlicensed bundle shows missing art', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PathSceneArtSlot(
              languageKey: 'ha',
              unitIndex: 0,
              dimmed: false,
              bundleLicensed: false,
              artMissingLabel: 'Missing',
            ),
          ),
        ),
      );
      expect(find.text('Missing'), findsOneWidget);
    });
  });

  group('PoliePathMascot', () {
    testWidgets('still frame when riv not present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PoliePathMascot(
              mood: PoliePathMood.pointUp,
              rivAssetPresent: false,
            ),
          ),
        ),
      );
      expect(find.text('pointUp'), findsOneWidget);
    });
  });
}
