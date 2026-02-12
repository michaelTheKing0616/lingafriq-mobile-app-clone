import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/api_contract.dart';

void main() {
  group('ApiContract', () {
    test('baseUrl removes trailing slash', () {
      // Note: This test depends on EnvConfig.backendBaseUrl
      // In a real test, you'd mock EnvConfig
      final baseUrl = ApiContract.baseUrl;
      expect(baseUrl.endsWith('/'), isFalse);
    });

    test('url builds absolute URL correctly', () {
      final baseUrl = ApiContract.baseUrl;
      final path = '/auth/login';
      final fullUrl = ApiContract.url(path);
      expect(fullUrl, equals('$baseUrl$path'));
    });

    group('Auth domain', () {
      test('login path is correct', () {
        expect(ApiContract.auth.login, equals('/auth/jwt/create/'));
      });

      test('refresh path is correct', () {
        expect(ApiContract.auth.refresh, equals('/auth/jwt/refresh/'));
      });

      test('register path is correct', () {
        expect(ApiContract.auth.register, equals('/accounts/auth/users/'));
      });

      test('updateProfile substitutes id correctly', () {
        expect(ApiContract.auth.updateProfile(123), equals('/accounts/auth/users/123/'));
      });

      test('unregisterFcmDevice substitutes token correctly', () {
        expect(
          ApiContract.auth.unregisterFcmDevice('token123'),
          equals('/devices/token123/'),
        );
      });
    });

    group('Gamification domain', () {
      test('sync path is correct', () {
        expect(ApiContract.gamification.sync, equals('/api/gamification/sync'));
      });

      test('xpAward path is correct', () {
        expect(ApiContract.gamification.xpAward, equals('/api/gamification/xp/award'));
      });

      test('challenges substitutes goalId correctly', () {
        expect(
          ApiContract.gamification.challenges('goal123'),
          equals('/api/gamification/advanced/challenges/goal123'),
        );
      });

      test('userBadges substitutes userId correctly', () {
        expect(
          ApiContract.gamification.userBadges('user456'),
          equals('/api/gamification/badges/users/user456'),
        );
      });
    });

    group('Social domain', () {
      test('gift path is correct', () {
        expect(ApiContract.social.gift, equals('/api/social/gift'));
      });

      test('connectionAccept substitutes id correctly', () {
        expect(
          ApiContract.social.connectionAccept('conn789'),
          equals('/connections/conn789/accept'),
        );
      });
    });

    group('Content domain', () {
      test('lessons path is correct', () {
        expect(ApiContract.content.lessons, equals('/lessons/'));
      });

      test('sectionLessons substitutes lessonId correctly', () {
        expect(
          ApiContract.content.sectionLessons(42),
          equals('/lessons/42/all'),
        );
      });

      test('cultureArticles handles published parameter', () {
        expect(
          ApiContract.content.cultureArticles(published: true),
          equals('/culture-magazine/articles?published=true'),
        );
        expect(
          ApiContract.content.cultureArticles(published: false),
          equals('/culture-magazine/articles?published=false'),
        );
        expect(
          ApiContract.content.cultureArticles(),
          equals('/culture-magazine/articles'),
        );
      });
    });

    group('All domain groups exist', () {
      test('all domain groups are accessible', () {
        expect(ApiContract.auth, isNotNull);
        expect(ApiContract.accounts, isNotNull);
        expect(ApiContract.gamification, isNotNull);
        expect(ApiContract.chat, isNotNull);
        expect(ApiContract.social, isNotNull);
        expect(ApiContract.socialAudio, isNotNull);
        expect(ApiContract.content, isNotNull);
        expect(ApiContract.grammar, isNotNull);
        expect(ApiContract.ai, isNotNull);
        expect(ApiContract.games, isNotNull);
        expect(ApiContract.lessonItems, isNotNull);
        expect(ApiContract.interactive, isNotNull);
        expect(ApiContract.adaptiveLearning, isNotNull);
        expect(ApiContract.personalities, isNotNull);
        expect(ApiContract.items, isNotNull);
        expect(ApiContract.events, isNotNull);
        expect(ApiContract.badges, isNotNull);
        expect(ApiContract.media, isNotNull);
        expect(ApiContract.voice, isNotNull);
        expect(ApiContract.onboarding, isNotNull);
        expect(ApiContract.sync, isNotNull);
        expect(ApiContract.offline, isNotNull);
        expect(ApiContract.userContent, isNotNull);
        expect(ApiContract.villages, isNotNull);
        expect(ApiContract.tribes, isNotNull);
        expect(ApiContract.journey, isNotNull);
        expect(ApiContract.avatar, isNotNull);
        expect(ApiContract.currency, isNotNull);
        expect(ApiContract.subscriptions, isNotNull);
        expect(ApiContract.leaderboards, isNotNull);
        expect(ApiContract.competitions, isNotNull);
        expect(ApiContract.pronunciation, isNotNull);
        expect(ApiContract.misc, isNotNull);
      });
    });
  });
}
