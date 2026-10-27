import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/games/echo_karaoke/echo_karaoke_game.dart';
import 'package:lingafriq/games/echo_karaoke/echo_karaoke_screen.dart';
import 'package:lingafriq/games/echo_karaoke/pitch_line_view.dart';
import 'package:lingafriq/games/echo_karaoke/song_catalog.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

void main() {
  const model = ToneLanguageModel(
    languageCode: 'yo',
    systemId: 'yo_hml',
    levels: ['H', 'M', 'L'],
    contourKinds: ['level'],
    hasDownstep: false,
    sourceId: 'models.json',
  );

  test('licence filter drops unlicensed pieces', () {
    const bad = EchoKaraokePiece(
      id: 'x',
      languageCode: 'yo',
      lyrics: 'test',
      translationEn: 'test',
      tonePattern: ['H'],
      licence: EchoSongLicence(
        kind: EchoSongLicenceKind.unlicensed,
        licenceId: '',
        citation: '',
      ),
    );
    expect(passesLicenceFilter(bad), isFalse);
    final yo = licensedPiecesForLanguage('yo');
    expect(yo, isNotEmpty);
    expect(yo.every(passesLicenceFilter), isTrue);
  });

  test('pitch alignment scores closer contours higher', () {
    const target = [1.0, 0.5, 0.0];
    final close = pitchAlignmentScore(target: target, learner: [0.95, 0.48, 0.05]);
    final far = pitchAlignmentScore(target: target, learner: [0.2, 0.8, 0.9]);
    expect(close, greaterThan(far));
  });

  testWidgets('echo_karaoke_playing pitch line', (tester) async {
    final piece = kEchoKaraokeSeedCatalog.first;
    final contour = targetContourForPiece(piece, model);
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: PitchLineView(
            lyrics: piece.lyrics,
            targetContour: contour,
            progress: 0.4,
          ),
        ),
      ),
    );
    expect(find.byType(PitchLineView), findsOneWidget);
  });

  testWidgets('echo_karaoke_why_wrong preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 840));
    final piece = kEchoKaraokeSeedCatalog.first;
    await tester.pumpWidget(
      _wrap(
        EchoKaraokeScreen(
          language: 'yo',
          initialPhase: EchoKaraokePhase.whyWrong,
          previewPiece: piece,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('pitch drifted'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('echo_karaoke_results practice label', (tester) async {
    final piece = kEchoKaraokeSeedCatalog.first;
    await tester.pumpWidget(
      _wrap(
        EchoKaraokeScreen(
          language: 'yo',
          initialPhase: EchoKaraokePhase.results,
          previewPiece: piece,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Phrase complete'), findsOneWidget);
  });
}
