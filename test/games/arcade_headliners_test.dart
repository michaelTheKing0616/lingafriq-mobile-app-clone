import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('arcade headliners (P8-918)', () {
    test('config has ten slots with Tone Forge featured', () {
      expect(AllGamesRegistry.validateHeadlinerConfig(), isEmpty);
      expect(kArcadeHeadlinerOrder.length, 10);
      expect(
        kArcadeHeadlinerOrder.first.gameId,
        AllGamesRegistry.toneForgeGameId,
      );
      expect(kArcadeHeadlinerOrder.first.showFeaturedBadge, isTrue);
    });

    test('only shipped elevation cards are playable', () {
      final toneForge = kArcadeHeadlinerOrder.first;
      expect(AllGamesRegistry.headlinerIsPlayable(toneForge), isTrue);
      final talkingDrum = kArcadeHeadlinerOrder[1];
      expect(AllGamesRegistry.headlinerIsPlayable(talkingDrum), isFalse);
    });

    test('headliner slots reference registry listings or future ids', () {
      for (final slot in kArcadeHeadlinerOrder) {
        expect(slot.elevationCardId, startsWith('P8-'));
        expect(slot.flagshipTitle, isNotEmpty);
      }
      expect(
        kArcadeHeadlinerOrder.map((s) => s.gameId),
        contains(AllGamesRegistry.toneForgeGameId),
      );
    });
  });
}
