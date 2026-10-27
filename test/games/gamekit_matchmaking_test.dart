import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_animation_bridge.dart';
import 'package:lingafriq/games/gamekit/game_engine_service.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/services/polie_game_client.dart';

void main() {
  final service = GameEngineService(
    polieClient: PolieGameClient(),
    animationBridge: GameAnimationBridge(),
  );

  GameSession baseSession() => GameSession(
        sessionId: 's',
        userId: 'u',
        gameId: 'tone_forge',
        language: 'yo',
        startTime: DateTime(2026, 1, 1),
      );

  test('buildDuelMatchRequest never sends client level', () {
    final body = service.buildDuelMatchRequest(
      requestId: 'r1',
      language: 'yo',
      skillId: 'tone_yo',
      gameId: 'tone_forge',
    );
    expect(body.containsKey('clientLevel'), isFalse);
    expect(body.containsKey('level'), isFalse);
  });

  test('applyDuelHumanMatch stores opponent level labels', () {
    final updated = service.applyDuelHumanMatch(baseSession(), {
      'matchId': 'm1',
      'self': {'levelLabel': 'Building'},
      'opponent': {'userId': 'peer', 'levelLabel': 'Steady'},
    });
    expect(updated.duelOpponentLevelLabel, 'Steady');
    expect(updated.duelSelfLevelLabel, 'Building');
    expect(updated.duelOpponentIsBot, isFalse);
  });

  test('applyDuelTimeoutOffer exposes bot and retry flags', () {
    final updated = service.applyDuelTimeoutOffer(baseSession(), {
      'offerBot': true,
      'botLevelLabel': 'Building',
      'retryAllowed': true,
    });
    expect(updated.duelMatchmakingStatus, 'timeout');
    expect(updated.metadata['duel_timeout_offer_bot'], isTrue);
  });
}
