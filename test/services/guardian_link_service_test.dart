import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GuardianHubLink parses hub payload', () {
    final link = GuardianHubLink.fromJson(<String, dynamic>{
      'child_user_id': 42,
      'status': 'verifying',
      'regime': 'NDPA_2023',
      'policy_version': 'guardian-consent-2026-10-01',
      'consented_at': '2026-10-01T12:00:00.000Z',
    });
    expect(link.childUserId, 42);
    expect(link.status, 'verifying');
    expect(link.regime, 'NDPA_2023');
    expect(link.consentedAt, isNotNull);
  });

  test('acceptInvite queues when offline', () async {
    final posts = <String>[];
    final service = GuardianLinkService(
      isOnline: () async => false,
      loadPending: () async => [],
      savePending: (_) async {},
      post: (path, {data}) async {
        posts.add(path);
        return <String, dynamic>{'ok': true};
      },
    );

    final state = await service.acceptInvite(
      inviteToken: 'tok',
      guardianDisplayName: 'Ada',
    );
    expect(state, GuardianSubmitState.queuedOffline);
    expect(posts, isEmpty);
  });

  test('acceptInvite posts when online', () async {
    Map<String, Object?>? captured;
    final service = GuardianLinkService(
      isOnline: () async => true,
      post: (path, {data}) async {
        captured = data;
        return <String, dynamic>{'ok': true, 'child_user_id': 7};
      },
    );

    final state = await service.acceptInvite(
      inviteToken: 'abc',
      guardianDisplayName: 'Tunde',
    );
    expect(state, GuardianSubmitState.sent);
    expect(captured?['invite_token'], 'abc');
    expect(captured?['guardian_display_name'], 'Tunde');
  });

  test('fetchHubLinks throws on offline', () async {
    final service = GuardianLinkService(isOnline: () async => false);
    expect(() => service.fetchHubLinks(), throwsA(isA<GuardianOfflineException>()));
  });
}
