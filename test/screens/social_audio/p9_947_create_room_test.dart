import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/social_audio/social_audio_room_model.dart';

void main() {
  test('P9-947 practice room model parses backend fields', () {
    final room = SocialAudioRoom.fromJson({
      'id': 'abc',
      'name': 'Yo room',
      'description': 'desc',
      'language': 'yo',
      'type': 'practice',
      'status': 'live',
      'created_at': DateTime.now().toIso8601String(),
      'practiceTopic': 'Greetings',
      'cefrLevel': 'A1',
      'dropIn': true,
      'sourceKind': 'practice_room',
      'aiFacilitatorEnabled': true,
    });
    expect(room.isPracticeRoom, isTrue);
    expect(room.cefrLevel, 'A1');
    expect(room.aiFacilitatorEnabled, isTrue);
  });
}
