import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    group('static link generation', () {
      test('lessonLink returns correct URL for lesson id', () {
        expect(
          DeepLinkService.lessonLink('42'),
          'https://lingafriq.app/lesson/42',
        );
        expect(
          DeepLinkService.lessonLink('abc-123'),
          'https://lingafriq.app/lesson/abc-123',
        );
      });

      test('achievementLink returns correct URL for badge id', () {
        expect(
          DeepLinkService.achievementLink('badge_1'),
          'https://lingafriq.app/achievement/badge_1',
        );
      });

      test('inviteLink returns correct URL for user id', () {
        expect(
          DeepLinkService.inviteLink('user-456'),
          'https://lingafriq.app/invite/user-456',
        );
      });

      test('profileLink returns correct URL for user id', () {
        expect(
          DeepLinkService.profileLink('user-789'),
          'https://lingafriq.app/profile/user-789',
        );
      });

      test('questLink returns correct URL for quest id', () {
        expect(
          DeepLinkService.questLink('quest-101'),
          'https://lingafriq.app/quest/quest-101',
        );
      });
    });

    group('baseUrl', () {
      test('baseUrl is lingafriq.app', () {
        expect(DeepLinkService.baseUrl, 'https://lingafriq.app');
      });
    });
  });
}
