import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/phoneme_viseme.dart';

void main() {
  test('yoruba kp and gb map to labial-velar visemes, not letters', () {
    expect(visemeForPhoneme('yo', 'kp'), 'KP');
    expect(visemeForPhoneme('yo', 'gb'), 'GB');
    expect(visemeForPhoneme('yo', 'ã'), 'Nnasal');
    expect(visemeForPhoneme('yo', 'hello'), isNull);
  });

  test('zulu clicks and ethiopian ejectives use their own tables', () {
    expect(visemeForPhoneme('zu', 'ǀ'), 'C');
    expect(visemeForPhoneme('zu', 'ǁ'), 'Q');
    expect(visemeForPhoneme('zu', 'ǃ'), 'X');
    expect(visemeForPhoneme('zu', 'x'), isNull);
    expect(visemeForPhoneme('am', 'kʼ'), 'Q');
    expect(visemeForPhoneme('am', 'x'), 'X');
  });

  test(
    'alignment follows the audio clock and RMS-only fallback ignores spelling',
    () {
      final aligned = LipSyncTrack(
        language: 'yo',
        phonemes: const [
          AlignedPhoneme(
            phoneme: 'gb',
            start: Duration.zero,
            end: Duration(milliseconds: 80),
          ),
          AlignedPhoneme(
            phoneme: 'a',
            start: Duration(milliseconds: 80),
            end: Duration(milliseconds: 160),
          ),
        ],
        rms: const [RmsSample(at: Duration.zero, level: 0.9)],
      );
      final first = aligned.at(
        const Duration(milliseconds: 40),
        delta: const Duration(milliseconds: 16),
      );
      expect(first.viseme, 'GB');
      expect(first.jawOpen, greaterThan(0));
      expect(first.jawOpen, lessThanOrEqualTo(1));

      final fallback = LipSyncTrack(
        language: 'yo',
        phonemes: const [],
        rms: const [RmsSample(at: Duration.zero, level: 0.4)],
      );
      expect(
        fallback
            .at(Duration.zero, delta: const Duration(milliseconds: 16))
            .viseme,
        'aa',
      );
      final quiet = LipSyncTrack(language: 'yo', phonemes: const []);
      expect(quiet.at(const Duration(milliseconds: 50)).viseme, 'sil');
    },
  );
}
