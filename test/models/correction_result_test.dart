import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/correction_result.dart';

void main() {
  test('CorrectionResult maps tier close to near-miss UX copy', () {
    final r = CorrectionResult.fromJson({
      'tier': 'close',
      'has_correction': true,
      'was_correct': false,
      'correction': 'Ó dàbọ̀',
      'note': 'tone',
    });
    expect(r.tier, 'close');
    expect(r.uxFeedbackLine(), isNotEmpty);
    expect(r.uxFeedbackLine().toLowerCase(), isNot(contains('correction:')));
  });

  test('CorrectionResult defaults tier from was_correct', () {
    final r = CorrectionResult.fromJson({
      'has_correction': true,
      'was_correct': false,
      'correction': 'x',
    });
    expect(r.tier, 'incorrect');
  });
}
