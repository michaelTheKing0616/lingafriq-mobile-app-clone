import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';
import 'package:lingafriq/avatars/lipsync/viseme_scheduler.dart';

void main() {
  group('VisemeScheduler', () {
    late VisemeScheduler scheduler;

    setUp(() {
      scheduler = VisemeScheduler(
        languageId: 'yo',
        phonemes: const [
          AlignedPhoneme(
            phoneme: 'gb',
            start: Duration.zero,
            end: const Duration(milliseconds: 80),
          ),
          AlignedPhoneme(
            phoneme: 'a',
            start: const Duration(milliseconds: 80),
            end: const Duration(milliseconds: 160),
          ),
        ],
      );
    });

    test('viseme at audio clock within tolerance budget', () {
      expect(
        scheduler.visemeWireAt(const Duration(milliseconds: 40)),
        'GB',
      );
      expect(
        scheduler.driftFromTokenStartMs(const Duration(milliseconds: 40)),
        40,
      );
      expect(
        scheduler.visemeWireAt(const Duration(milliseconds: 100)),
        'aa',
      );
      for (final t in scheduler.visemeChangeTimes()) {
        expect(
          scheduler.isNearBoundary(t),
          isTrue,
          reason: 'boundary $t',
        );
      }
    });

    test('unaligned scheduler yields null viseme', () {
      final unaligned = VisemeScheduler(languageId: 'yo', phonemes: const []);
      expect(unaligned.visemeWireAt(Duration.zero), isNull);
      expect(unaligned.isAligned, isFalse);
    });
  });
}
