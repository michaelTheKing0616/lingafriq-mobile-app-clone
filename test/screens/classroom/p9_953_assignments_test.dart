import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/classroom/classroom_assignments_screen.dart';

void main() {
  group('P9-953 assignment grade display', () {
    test('unsure when autoGrade.unsure is true without composite score', () {
      expect(
        assignmentGradeIsUnsure({
          'status': 'unsure',
          'autoGrade': {'unsure': true, 'compositeScore': null},
        }),
        isTrue,
      );
      expect(assignmentDisplayScore({'displayScore': null}), isNull);
    });

    test('shows override display score when present', () {
      expect(
        assignmentDisplayScore({'displayScore': 88, 'status': 'overridden'}),
        '88',
      );
    });
  });
}
