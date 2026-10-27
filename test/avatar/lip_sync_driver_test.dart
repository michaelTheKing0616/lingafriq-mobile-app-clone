import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatar/lip_sync_driver.dart';

void main() {
  test('viseme payload drives mapped mouth within drift budget', () {
    final driver = LipSyncDriver();
    driver.loadPayload({
      'language_id': 'yo',
      'mode': 'viseme',
      'phonemes': [
        {'label': 'gb', 'start_ms': 0, 'end_ms': 80},
        {'label': 'a', 'start_ms': 80, 'end_ms': 160},
      ],
      'visemes': [
        {'viseme': 'GB', 'start_ms': 0, 'end_ms': 80},
        {'viseme': 'aa', 'start_ms': 80, 'end_ms': 160},
      ],
    });

    final sample = driver.sampleAt(const Duration(milliseconds: 40));
    expect(sample.viseme, 'GB');
    expect(driver.phonemeDriftMs(const Duration(milliseconds: 40)), lessThanOrEqualTo(80));
  });

  test('missing alignments keep neutral viseme without letter guessing', () {
    final driver = LipSyncDriver();
    driver.loadPayload({
      'language_id': 'yo',
      'mode': 'neutral',
      'phonemes': [],
      'visemes': [],
    });
    final sample = driver.sampleAt(const Duration(milliseconds: 50));
    expect(sample.viseme, 'sil');
  });
}
