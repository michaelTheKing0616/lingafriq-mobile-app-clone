import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/social_feed_provider.dart'
    show socialFeedProvider, SocialFeedItem, kSocialFeedSkipApi;

void main() {
  setUp(() {
    kSocialFeedSkipApi = true;
  });

  tearDown(() {
    kSocialFeedSkipApi = false;
  });

  group('SocialFeedNotifier', () {
    test('initial state is empty list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(socialFeedProvider);
      expect(state, isEmpty);
    });

    test('loadFeed updates state when API returns feed array', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(socialFeedProvider.notifier);

      await notifier.loadFeed();

      final state = container.read(socialFeedProvider);
      expect(state, isA<List<SocialFeedItem>>());
    });

    test('addFeedItem prepends item to state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(socialFeedProvider.notifier);
      final before = container.read(socialFeedProvider).length;

      notifier.addFeedItem(SocialFeedItem(
        id: 'new-1',
        type: 'lesson_complete',
        userId: 'u1',
        userName: 'Test User',
        timestamp: DateTime.now(),
      ));

      final after = container.read(socialFeedProvider);
      expect(after.length, before + 1);
      expect(after.first.id, 'new-1');
      expect(after.first.userName, 'Test User');
    });
  });

  group('SocialFeedItem', () {
    test('fromJson parses minimal payload', () {
      final json = {
        'id': 'feed-1',
        'type': 'badge_earned',
        'userId': 'u2',
        'userName': 'Alice',
        'timestamp': '2025-01-15T12:00:00.000Z',
      };
      final item = SocialFeedItem.fromJson(json);
      expect(item.id, 'feed-1');
      expect(item.type, 'badge_earned');
      expect(item.userId, 'u2');
      expect(item.userName, 'Alice');
      expect(item.details, isNull);
      expect(item.metadata, isNull);
    });

    test('fromJson accepts details and metadata', () {
      final json = {
        '_id': 'oid-1',
        'type': 'lesson_complete',
        'user_id': 'u3',
        'username': 'Bob',
        'details': 'Completed Greetings',
        'timestamp': '2025-01-16T10:00:00.000Z',
        'metadata': {'xp': 50},
      };
      final item = SocialFeedItem.fromJson(json);
      expect(item.id, 'oid-1');
      expect(item.userId, 'u3');
      expect(item.userName, 'Bob');
      expect(item.details, 'Completed Greetings');
      expect(item.metadata, {'xp': 50});
    });
  });
}
