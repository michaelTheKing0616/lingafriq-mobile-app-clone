import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/universal_game_screen.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('practice banner shows Practice, not scored', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameKitPracticeReplayPanel(
          modelAudio: const GameKitCorrectItemAudio(uri: 'asset:assets/audio/placeholder.wav'),
          learnerRecordingPath: null,
          playModelLabel: 'Model',
          playYoursLabel: 'Yours',
          noAudioLabel: 'No audio',
        ),
      ),
    );
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Yours'), findsOneWidget);
  });
}
