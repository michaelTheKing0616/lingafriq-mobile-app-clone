import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/guardian/messaging_explainer_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

class _FakeExplainerService extends GuardianMessagingExplainerService {
  _FakeExplainerService(this.payload, {this.throwsOffline = false});

  final GuardianMessagingExplainer payload;
  final bool throwsOffline;

  @override
  Future<GuardianMessagingExplainer> fetchExplainer() async {
    if (throwsOffline) {
      throw const GuardianOfflineException();
    }
    return payload;
  }
}

const _guideTexts = [
  'How messages work for young learners',
  'Messages are checked first',
  'Photos, voice notes and links wait for review',
  'You can stop a contact',
  'Teachers need your approval',
];

GuardianMessagingExplainer _payload(String body) => GuardianMessagingExplainer(
  title: 'Server title',
  body: body,
  moderatorsSee: const [],
  e2eeTradeoff: 'Server tradeoff',
);

void main() {
  testWidgets('online shows the bundled guide with every section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GuardianMessagingExplainerScreen(
          explainerService: _FakeExplainerService(_payload('Server body')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in _guideTexts) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // Server wording never replaces the reviewed, translated guide.
    expect(find.text('Server body'), findsNothing);
  });

  testWidgets('offline shows the banner and exactly the same guide', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GuardianMessagingExplainerScreen(
          explainerService: _FakeExplainerService(
            _payload('unused'),
            throwsOffline: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You are offline. Showing the last saved explanation.'),
      findsOneWidget,
    );
    for (final text in _guideTexts) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('hub tile opens explainer screen', (tester) async {
    final fake = _FakeExplainerService(_payload('B'));
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ListView(
            children: [
              GuardianMessagingExplainerHubTile(explainerService: fake),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text(GuardianMessagingExplainerHubTile.tileTitle));
    await tester.pumpAndSettle();
    expect(find.text('How messages work for young learners'), findsOneWidget);
  });
}
