import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/translate/live_translate_confidence.dart';

void main() {
  group('P6-030 live translate confidence', () {
    test('low STT maps to low band', () {
      final view = mapLiveTranslateConfidence(
        sttConfidence: 0.35,
        sourceText: 'hello there friend',
        isFinal: true,
      );
      expect(view.band, LiveTranslateConfidenceBand.low);
      expect(view.labelKey, 'live.confidence_low');
    });

    test('short text caps confidence', () {
      final view = mapLiveTranslateConfidence(
        sttConfidence: 0.95,
        sourceText: 'hi',
        isFinal: true,
      );
      expect(view.band, isNot(LiveTranslateConfidenceBand.high));
    });

    test('camera input without STT uses cautious default', () {
      final view = mapLiveTranslateConfidence(
        sourceText: 'Exit sign ahead',
        isFinal: true,
        inputKind: LiveTranslateInputKind.camera,
      );
      expect(view.score, lessThan(liveTranslateHighConfidenceThreshold));
    });
  });
}
