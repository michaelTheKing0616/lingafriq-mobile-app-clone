import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_contract.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';

void main() {
  test(
    'graded events write activity without a client amount or letter mouth',
    () {
      final session = CastSession(preset: 'Polie');
      session.onGraded(correct: true);
      expect(session.pose.activity, 'encouraging');
      expect(session.pose.expression, 'proud');
      session.onGraded(correct: false);
      expect(session.pose.activity, 'hinting');
      expect(session.pose.expression, 'concerned');
      session.onMic(true);
      expect(session.pose.activity, 'listening');
      session.onAiStreaming(true);
      expect(session.pose.activity, 'thinking');
      session.onLessonComplete();
      expect(session.pose.activity, 'celebrating');
      session.dispose();
    },
  );

  test('semantics label names the expression', () {
    expect(
      castSemanticsLabel(
        name: 'Polie',
        expression: 'proud',
        activity: 'listening',
      ),
      'Polie looks proud and is listening',
    );
  });

  test('wear records the part before a file is bound and does not decode', () {
    final session = CastSession(preset: 'Learner');
    session.wear('hair', 'Hair/Locs');
    expect(session.pose.parts['hair'], 'Hair/Locs');
    expect(session.file, isNull);
    session.dispose();
  });
}
