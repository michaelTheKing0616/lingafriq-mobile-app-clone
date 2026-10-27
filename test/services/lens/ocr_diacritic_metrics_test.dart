import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/ocr_diacritic_metrics.dart';

void main() {
  test('ọkọ́ vs Latin OCR strip yields 100% per-mark error', () {
    final stats = compareOcrDiacriticMarks(
      reference: 'ọkọ́',
      hypothesis: 'Oko',
    );
    expect(stats.referenceMarks, greaterThanOrEqualTo(2));
    expect(stats.perMarkErrorRate, 1.0);
    expect(stats.mismatchedClusters, isNotEmpty);
  });

  test('matching NFC text yields zero per-mark error', () {
    final stats = compareOcrDiacriticMarks(
      reference: 'Ahịa',
      hypothesis: 'Ahịa',
    );
    expect(stats.perMarkErrorRate, 0.0);
  });

  test('ledger fixture android ig phrase loses dot-below', () {
    final stats = compareOcrDiacriticMarks(
      reference: 'Adị m mma',
      hypothesis: 'Adi m mma',
    );
    expect(stats.referenceMarks, greaterThanOrEqualTo(1));
    expect(stats.perMarkErrorRate, greaterThan(0.0));
  });
}
