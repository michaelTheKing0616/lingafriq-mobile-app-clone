import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/games/flashcard_safari.dart';
import 'package:lingafriq/screens/learn/object_lessons.dart';
import 'package:lingafriq/screens/lens/see_it_in_the_wild.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/widgets/app_top_bar.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

AfricanObjectSet _fixtureObjectSet() {
  return AfricanObjectSet.fromJson({
    'version': 1,
    'entries': [
      {
        'object_set_id': 'obj.cup',
        'ml_kit_labels': ['Cup', 'Mug'],
        'living_dictionary_lexeme_id': 'yo.lex.cup',
      },
      {
        'object_set_id': 'obj.chair',
        'ml_kit_labels': ['Chair'],
        'living_dictionary_lexeme_id': 'yo.lex.chair',
      },
    ],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filterMlKitLabelsForScope', () {
    test('keeps only labels in scoped object set', () {
      final set = _fixtureObjectSet();
      final filtered = filterMlKitLabelsForScope(
        labels: ['Cup', 'Chair', 'Dog'],
        scopedObjectSetIds: ['obj.cup'],
        objectSet: set,
      );
      expect(filtered, ['Cup']);
    });
  });

  group('probeLensAvailability', () {
    test('unavailable when no cameras', () async {
      final result = await probeLensAvailability(
        cameras: () async => <CameraDescription>[],
      );
      expect(result.available, isFalse);
      expect(result.reason, LensAvailabilityReason.noCamera);
    });

    test('available when camera and model asset exist', () async {
      final result = await probeLensAvailability(
        cameras: () async => [
          const CameraDescription(
            name: 'back',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ],
        loadAsset: (key) async {
          if (key.contains('tflite')) {
            return ByteData(8);
          }
          throw FlutterError('missing');
        },
      );
      expect(result.available, isTrue);
    });
  });

  group('AppTopBar Lens entry', () {
    testWidgets('Lens button opens scoped host when available', (tester) async {
      SharedPreferences.setMockInitialValues({'learning_language': 'yoruba'});
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppTopBar(
                title: 'Today',
                language: 'yoruba',
                lensPreflight: const LensAvailability(
                  available: true,
                  reason: LensAvailabilityReason.ready,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LensTopBarButton), findsOneWidget);
      await tester.tap(find.byType(LensTopBarButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Lens'), findsWidgets);
    });

    testWidgets('Lens button shows explanation when unavailable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppTopBar(
                title: 'Learn',
                language: 'yoruba',
                lensPreflight: const LensAvailability(
                  available: false,
                  reason: LensAvailabilityReason.noCamera,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LensTopBarButton));
      await tester.pumpAndSettle();
      expect(find.text(kLensUnavailableMessage), findsOneWidget);
    });
  });

  group('Learn object lesson', () {
    testWidgets('find-at-home opens Lens with scope banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LearnObjectLessonScreen(
            title: 'Kitchen',
            language: 'yoruba',
            objectSetIds: const ['obj.cup', 'obj.chair'],
            preflight: const LensAvailability(
              available: true,
              reason: LensAvailabilityReason.ready,
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text(LearnObjectLessonScreen.findAtHomeLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('Find these at home: obj.cup, obj.chair'),
        findsOneWidget,
      );
    });
  });

  group('Flashcard Safari pipeline', () {
    test('uses shared Lens detector factory', () {
      expect(
        flashcardSafariLensPipelineFactory,
        createLensRecognitionPipeline,
      );
    });
  });

  group('Word Card see it in the wild', () {
    testWidgets('button is present on sheet', (tester) async {
      final model = WordCardSheetModel(
        lexemeId: 'yo.lex.cup',
        language: 'yo',
        standardWord: 'ìfẹ́',
        tonePattern: const ['L', 'H'],
        syllables: const ['ì', 'fẹ́'],
        speakerClips: const [],
        examples: const [],
        dialectVariants: const [],
        showsAiDraftBadge: false,
        gloss: 'love',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCardSheet(model: model),
          ),
        ),
      );

      expect(find.text(kSeeItInTheWildLabel), findsOneWidget);
    });
  });
}
