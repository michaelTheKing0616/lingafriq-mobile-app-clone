import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/widgets/progress_meter.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('gamekit bot strip shows Bot chip and no human name', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 160));
    await tester.pumpWidget(
      _wrap(
        const GamekitDuelOpponentStrip(
          isBot: true,
          levelLabel: 'Building',
          phase: GamekitDuelSurfacePhase.playing,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Bot'), findsWidgets);
    expect(find.textContaining('Practice opponent'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
  });

  testWidgets('gamekit_bot_label_playing golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 120));
    await tester.pumpWidget(
      _wrap(
        const GamekitDuelOpponentStrip(
          isBot: true,
          levelLabel: 'Steady',
          phase: GamekitDuelSurfacePhase.playing,
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/gamekit_bot_label_playing.png'),
    );
  });

  testWidgets('gamekit_bot_label_results golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 140));
    await tester.pumpWidget(
      _wrap(
        const GamekitDuelOpponentStrip(
          isBot: true,
          levelLabel: 'Building',
          phase: GamekitDuelSurfacePhase.results,
          selfScore: 8,
          opponentScore: 6,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/gamekit_bot_label_results.png'),
    );
  });
}
