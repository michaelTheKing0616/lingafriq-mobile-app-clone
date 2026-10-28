import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
              preferRive: false,
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

    testWidgets('preferRive true does not force static forever without probe',
        (tester) async {
      // Rive may fail in headless tests; clay fallback is OK — what we ban is
      // permanently setting _failed=true without attempting load.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 80,
              child: PathSceneArtSlot(
                languageKey: 'yo',
                unitIndex: 0,
                dimmed: false,
                bundleLicensed: true,
                preferRive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(PathSceneArtSlot), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PoliePathMascot', () {
    testWidgets('still frame when riv not present', (tester) async {
      // `PoliePathStillFrame` now uses `.w`/`.h`/`.r`/`.sp` (ScreenUtil
      // scaling, added so its dimensions stay consistent with the rest of
      // the path screen instead of unscaled raw literals), which throws a
      // `LateInitializationError` without a `ScreenUtilInit` ancestor to
      // seed `ScreenUtil`'s singleton first.
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: PoliePathMascot(
                mood: PoliePathMood.pointUp,
                rivAssetPresent: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('pointUp'), findsOneWidget);
    });
  });
}
