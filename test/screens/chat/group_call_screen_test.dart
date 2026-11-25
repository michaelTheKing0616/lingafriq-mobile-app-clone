import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/chat/group_call_screen.dart';

void main() {
  test('groupCallShouldOfferAudioOnly at threshold', () {
    expect(groupCallShouldOfferAudioOnly(0.12), isTrue);
    expect(groupCallShouldOfferAudioOnly(0.05), isFalse);
  });

  test('call copy keys are human and non-placeholder', () {
    expect(kCallJoinCopy, isNot(contains('Lorem')));
    expect(kCallDeniedCopy, isNotEmpty);
    expect(kCallDegradedCopy, contains('audio'));
  });
}
