import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/utils/roster_import_feedback.dart';

void main() {
  test('P9-952 summarizeRosterImportResult counts ok rows and merges parse errors', () {
    final out = summarizeRosterImportResult({
      'parseErrors': [
        {'lineNumber': 3, 'reason': 'student_local_id is required'},
      ],
      'imported': [
        {'lineNumber': 2, 'ok': true},
        {'lineNumber': 4, 'ok': false, 'reason': 'duplicate'},
      ],
    });
    expect(out['okCount'], 1);
    expect((out['errors'] as List).length, 2);
    expect(out['summary'], contains('1 learners'));
  });
}
