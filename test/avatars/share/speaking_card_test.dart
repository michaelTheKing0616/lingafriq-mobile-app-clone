import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/share/speaking_card.dart';

void main() {
  test('minor share input strips personal fields from visible copy', () {
    const input = SpeakingShareCardInput(
      preset: 'Learner',
      phrase: 'Ẹ kú àárọ̀',
      isMinor: true,
      learnerDisplayName: 'Temi',
      learnerId: 'learner-1',
      email: 'temi@example.com',
    );
    final fields = input.sanitized().visibleTextFields();
    expect(fields['headline'], contains('Ẹ kú àárọ̀'));
    expect(fields.containsKey('attribution'), isFalse);
    expect(fields.values.join(' '), isNot(contains('Temi')));
    expect(fields.values.join(' '), isNot(contains('learner-1')));
    expect(fields.values.join(' '), isNot(contains('@')));
  });

  test('adult share may show attribution when provided', () {
    const input = SpeakingShareCardInput(
      preset: 'Learner',
      phrase: 'Sannu',
      learnerDisplayName: 'Amina',
    );
    final fields = input.visibleTextFields();
    expect(fields['attribution'], 'Amina');
  });

  test('speaking share pose uses speaking activity on cast rig', () {
    const input = SpeakingShareCardInput(
      preset: 'Polie',
      phrase: 'Ẹ kú àárọ̀',
    );
    final pose = buildSpeakingSharePose(input);
    expect(pose.preset, 'Polie');
    expect(pose.activity, 'speaking');
    expect(pose.viseme, 'aa');
    expect(
      speakingSharePhraseLabel(input.phrase),
      'I can now say… Ẹ kú àárọ̀',
    );
  });
}
