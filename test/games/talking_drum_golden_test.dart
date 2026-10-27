import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/talking_drum/contour_overlay.dart';
import 'package:lingafriq/games/talking_drum/talking_drum_game.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const model = ToneLanguageModel(
    languageCode: 'yo',
    systemId: 'yo_hml',
    levels: ['H', 'M', 'L'],
    contourKinds: ['level'],
    hasDownstep: false,
    sourceId: 'models.json',
  );

  testWidgets('talking_drum_playing contour overlay', (tester) async {
    final contour = drumContourFromTonePattern(['H', 'M', 'L'], model);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TalkingDrumContourOverlay(nativeContour: contour),
        ),
      ),
    );
    expect(find.byType(TalkingDrumContourOverlay), findsOneWidget);
  });

  testWidgets('talking_drum_why_wrong shows hatched unsure state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TalkingDrumContourOverlay(
            nativeContour: const [1, 0.5, 0],
            unsure: true,
          ),
        ),
      ),
    );
    expect(find.byType(TalkingDrumContourOverlay), findsOneWidget);
  });

  testWidgets('talking_drum_results learner overlay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TalkingDrumContourOverlay(
            nativeContour: const [1, 0.5, 0],
            learnerContour: const [0.9, 0.4, 0.1],
          ),
        ),
      ),
    );
    expect(find.byType(TalkingDrumContourOverlay), findsOneWidget);
  });
}
