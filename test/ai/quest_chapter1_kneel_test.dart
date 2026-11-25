import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/scene_chapter1.dart';

void main() {
  group('P11-017 respect posture → cast activity', () {
    test('respectful option kneels', () {
      expect(
        castActivityForRespectChoice(QuestRespectPostureChoice.respectfulKneel),
        kQuestCastActivityKneeling,
      );
      expect(
        learnerAvatarShowsKneeling(
          castActivityForRespectChoice(QuestRespectPostureChoice.respectfulKneel),
        ),
        isTrue,
      );
    });

    test('casual option never kneels', () {
      expect(
        castActivityForRespectChoice(QuestRespectPostureChoice.casualBow),
        kQuestCastActivityStanding,
      );
      expect(
        learnerAvatarShowsKneeling(
          castActivityForRespectChoice(QuestRespectPostureChoice.casualBow),
        ),
        isFalse,
      );
    });
  });
}
