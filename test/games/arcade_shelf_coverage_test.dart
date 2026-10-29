import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';
import 'package:lingafriq/screens/games/games_screen_enhanced_with_all_games.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('arcade shelf coverage (P8-917)', () {
    test('every catalog game is on exactly one shelf', () {
      expect(AllGamesRegistry.validateArcadeShelfCoverage(), isEmpty);
    });

    test('listing count matches catalog plus standalone flagships', () {
      expect(
        AllGamesRegistry.standaloneFlagshipIds,
        {'tone_forge', 'talking_drum', 'minimal_pair_duel', 'script_sprint'},
      );
      for (final id in AllGamesRegistry.standaloneFlagshipIds) {
        expect(
          GameCatalog.entries.any((e) => e.type.name == id),
          isFalse,
          reason: '$id must not be double-listed via the catalog',
        );
      }
      expect(
        AllGamesRegistry.totalArcadeListingCount(),
        GameCatalog.entries.length +
            AllGamesRegistry.standaloneFlagshipIds.length,
      );
    });

    test('harvest-pair games stay listed with distinct elevation ids', () {
      final drumWord = AllGamesRegistry.listingFor('drum_to_word_matching');
      final drumRhythm = AllGamesRegistry.listingFor('drum_rhythm_shadowing');
      expect(drumWord, isNotNull);
      expect(drumRhythm, isNotNull);
      expect(drumWord!.elevationCardId, isNotEmpty);
      expect(drumRhythm!.elevationCardId, isNotEmpty);
    });

    testWidgets('shelf tile shows elevation pending copy', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: ArcadeGameShelfTile(
                title: 'Word Match Audio',
                description: 'Match words with audio',
                icon: Icons.headphones,
                elevationCardId: 'P8-917',
                elevationPending: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Elevation pending'), findsOneWidget);
      expect(find.text('P8-917'), findsOneWidget);
    });

    testWidgets('shelf tile hides elevation pending when shipped', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: ArcadeGameShelfTile(
                title: 'Tone Forge',
                description: 'Tone practice',
                icon: Icons.graphic_eq,
                elevationCardId: 'P8-914',
                elevationPending: false,
                featured: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Elevation pending'), findsNothing);
      expect(find.text('Featured'), findsOneWidget);
    });
  });
}
