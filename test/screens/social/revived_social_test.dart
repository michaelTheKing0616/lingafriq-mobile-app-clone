import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/screens/social/revived_social_screens.dart';
import 'package:lingafriq/services/social/revived_social.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('age gate locks minor, unknown, and a failed server flag', () {
    expect(ageGateFromJson({'ok': true, 'band': 'adult'}).allowsChat, isTrue);
    expect(ageGateFromJson({'ok': true, 'band': 'minor'}).allowsChat, isFalse);
    expect(ageGateFromJson({'ok': true, 'band': 'unknown'}).allowsChat, isFalse);
    expect(ageGateFromJson({'ok': false, 'band': 'adult'}).allowsChat, isFalse);
  });

  test('block and report stay in retry when the server declines', () {
    final SafetyActionResult declined = safetyActionFromJson(
      const <String, dynamic>{'ok': false},
      successMessage: 'sent',
      failureMessage: 'retry',
    );
    expect(declined.accepted, isFalse);
    final SafetyActionResult accepted = safetyActionFromJson(
      const <String, dynamic>{'ok': true, 'caseId': 'c1'},
      successMessage: 'sent',
      failureMessage: 'retry',
    );
    expect(accepted.accepted, isTrue);
  });

  test('moderation denies anyone the server does not call a moderator', () {
    expect(
      moderationFromJson(
        const <String, dynamic>{'ok': true, 'moderator': false},
        denial: 'no',
      ).isModerator,
      isFalse,
    );
    expect(
      moderationFromJson(
        const <String, dynamic>{'ok': true, 'moderator': true},
        denial: 'no',
      ).isModerator,
      isTrue,
    );
  });

  test('family keeps only server rows and denies a non-guardian', () {
    final FamilyDashboardData denied = familyFromJson(
      const <String, dynamic>{'ok': false, 'message': 'not a guardian'},
    );
    expect(denied.isGuardian, isFalse);
    expect(denied.childLabels, isEmpty);
    final FamilyDashboardData empty = familyFromJson(
      const <String, dynamic>{
        'ok': true,
        'guardian': true,
        'children': <Object>[],
        'approvals': <Object>[],
      },
    );
    expect(empty.isGuardian, isTrue);
    expect(empty.childLabels, isEmpty);
    final FamilyDashboardData rows = familyFromJson(
      const <String, dynamic>{
        'ok': true,
        'guardian': true,
        'children': <Object>[
          <String, String>{'label': 'Ada'},
        ],
        'approvals': <Object>[
          <String, String>{'label': 'Circle request'},
        ],
      },
    );
    expect(rows.childLabels, <String>['Ada']);
    expect(rows.approvalLabels, <String>['Circle request']);
  });

  test('Plus stays off unless the store is configured and the server confirms', () {
    expect(
      plusFromJson(
        const <String, dynamic>{'entitled': true},
        storeConfigured: false,
      ).serverConfirmed,
      isFalse,
    );
    expect(
      plusFromJson(
        const <String, dynamic>{
          'ok': true,
          'entitled': true,
          'source': 'client',
        },
        storeConfigured: true,
      ).serverConfirmed,
      isFalse,
    );
    expect(
      plusFromJson(
        const <String, dynamic>{
          'ok': true,
          'entitled': true,
          'source': 'server',
        },
        storeConfigured: true,
      ).serverConfirmed,
      isTrue,
    );
  });

  test('welcome guidelines are recorded once', () {
    final ChatWelcomeStore store = ChatWelcomeStore();
    expect(store.hasAccepted('ada'), isFalse);
    store.accept('ada');
    expect(store.hasAccepted('ada'), isTrue);
    store.accept('  ');
    expect(store.hasAccepted(''), isFalse);
  });

  test('app routes register chat, family, and Plus', () {
    expect(
      generateAppRoute(const RouteSettings(name: '/village/chat-search')),
      isNotNull,
    );
    expect(
      generateAppRoute(const RouteSettings(name: 'me/family')),
      isNotNull,
    );
    expect(generateAppRoute(const RouteSettings(name: 'me/plus')), isNotNull);
    expect(
      generateAppRoute(const RouteSettings(name: 'village/moderation')),
      isNotNull,
    );
    expect(
      generateAppRoute(const RouteSettings(name: 'village/chat-welcome')),
      isNotNull,
    );
  });

  testWidgets('a failed block shows retry and does not say it was accepted', (
    tester,
  ) async {
    final RevivedSocialClient client = RevivedSocialClient(
      get: (String path) async => const <String, dynamic>{'ok': false},
      post: (String path, Map<String, dynamic> body) async =>
          const <String, dynamic>{'ok': false},
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RevivedContactInfoScreen(client: client, userId: '9'),
      ),
    );
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.byKey(RevivedContactInfoScreen.retryKey), findsOneWidget);
    expect(find.byKey(RevivedContactInfoScreen.acceptedKey), findsNothing);
    expect(find.text('Blocked on the server.'), findsNothing);
  });

  testWidgets('Plus does not start a purchase when the store is missing', (
    tester,
  ) async {
    var posts = 0;
    final RevivedSocialClient client = RevivedSocialClient(
      get: (String path) async => const <String, dynamic>{'ok': false},
      post: (String path, Map<String, dynamic> body) async {
        posts += 1;
        return const <String, dynamic>{
          'ok': true,
          'entitled': true,
          'source': 'server',
        };
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RevivedPlusScreen(client: client, storeConfigured: false),
      ),
    );
    expect(find.byKey(RevivedPlusScreen.unavailableKey), findsOneWidget);
    await tester.tap(find.text('Buy Plus'));
    await tester.pumpAndSettle();
    expect(posts, 0);
    expect(find.byKey(RevivedPlusScreen.entitledKey), findsNothing);
  });
}
