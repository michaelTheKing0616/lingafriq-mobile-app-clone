import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/classroom/classroom_session_screen.dart';

void main() {
  group('P9-954 live session consent', () {
    test('only recorded media state persists AV', () {
      expect(shouldPersistClassAv('recorded'), isTrue);
      expect(shouldPersistClassAv('unrecorded'), isFalse);
      expect(shouldPersistClassAv('pending'), isFalse);
    });

    test('phase labels cover lobby live recording declined', () {
      expect(classSessionPhaseLabel(ClassSessionLivePhase.recording), 'Recording');
      expect(classSessionPhaseLabel(ClassSessionLivePhase.declined), 'Unrecorded');
    });

    test('copy keys for recording indicator and consent ask', () {
      expect(sessionRecordingIndicatorCopy, isNotEmpty);
      expect(sessionConsentAskCopy, isNotEmpty);
    });
  });
}
