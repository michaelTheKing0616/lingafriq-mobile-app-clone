import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/tts/dynamic_tts_label.dart';

Widget _localized(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('dynamic speech TTS policy', () {
    test('polie and persona use permanent server TTS', () {
      for (final source in DynamicSpeechSource.values) {
        expect(dynamicSpeechUsesPermanentServerTts(source), isTrue);
        expect(dynamicSpeechEligibleForNativeReplacement(source), isFalse);
        expect(dynamicSpeechAudioKindFor(source), dynamicSpeechAudioKind);
        expect(dynamicSpeechShowsSyntheticTag(source), isTrue);
      }
    });

    test('null source is not dynamic speech', () {
      expect(dynamicSpeechUsesPermanentServerTts(null), isFalse);
      expect(dynamicSpeechAudioKindFor(null), isNull);
      expect(dynamicSpeechShowsSyntheticTag(null), isFalse);
    });

    test('synthetic tag string matches publish gate', () {
      expect(dynamicSpeechSyntheticTagMatchesGate('Synthetic voice'), isTrue);
      expect(dynamicSpeechSyntheticTagMatchesGate('human'), isFalse);
    });
  });

  group('DynamicTtsHonestyLabel', () {
    testWidgets('shows Synthetic voice for Polie', (tester) async {
      await tester.pumpWidget(
        _localized(const DynamicTtsHonestyLabel(source: DynamicSpeechSource.polie)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic voice'), findsOneWidget);
    });

    testWidgets('shows Synthetic voice for persona', (tester) async {
      await tester.pumpWidget(
        _localized(const DynamicTtsHonestyLabel(source: DynamicSpeechSource.persona)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic voice'), findsOneWidget);
    });
  });
}
