import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/navigation/app_shell.dart';
import 'package:lingafriq/navigation/hub_me.dart';
import 'package:lingafriq/navigation/tab_routes.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/utils/constants.dart';

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Widget _host(Widget child, {double scale = 1, bool reduced = false}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

bool _tabSelected(WidgetTester tester, ShellTab tab) {
  return tester
          .getSemantics(find.byKey(AppShell.tabKey(tab)))
          .flagsCollection
          .isSelected ==
      Tristate.isTrue;
}

Set<String> _lines(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data ?? '')
      .where((String line) => line.isNotEmpty)
      .toSet();
}

ProfileModel _person({
  String first = 'Ada',
  String last = 'Okafor',
  String username = 'ada_codes',
  String? avatar,
}) {
  return ProfileModel(
    id: 7,
    email: 'secret@example.com',
    username: username,
    first_name: first,
    last_name: last,
    is_current_user: true,
    rank: 4,
    nationality: 'Nigeria',
    agree_to_privacy_terms: true,
    avatar: avatar,
    completed_point: 120,
    streak: 9,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('me routes are registered and within two taps', () {
    const List<String> required = <String>[
      MeRoutes.root,
      MeRoutes.profile,
      MeRoutes.progress,
      MeRoutes.achievements,
      MeRoutes.leagues,
      MeRoutes.family,
      MeRoutes.plus,
      MeRoutes.settings,
      MeRoutes.about,
    ];
    expect(MeRoutes.paths, required);
    for (final String path in required) {
      expect(MeRoutes.isRegistered(path), isTrue, reason: path);
      expect(MeRoutes.tapsFromRoot(path), inInclusiveRange(0, 2));
    }
    expect(MeRoutes.tapsFromRoot(MeRoutes.root), 0);
    expect(MeRoutes.tapsFromRoot(MeRoutes.profile), 1);
    expect(MeRoutes.tapsFromRoot(MeRoutes.about), 1);
    expect(MeRoutes.tapsFromRoot('/me/nope'), -1);

    expect(MeRoutes.openingFor(MeRoutes.root), isA<MeHubOpening>());
    expect(MeRoutes.openingFor(MeRoutes.profile), isA<MeProfileOpening>());
    for (final MePlace place in MeRoutes.places) {
      if (place.kind != MePlaceKind.notAvailable) continue;
      final MeOpening opening = MeRoutes.openingFor(place.path);
      expect(opening, isA<MeGapOpening>());
      final MeGapOpening gap = opening as MeGapOpening;
      expect(gap.gap.placeId, place.id);
    }
    expect(
      MeRoutes.places
          .where((MePlace place) => place.kind == MePlaceKind.ready)
          .map((MePlace place) => place.id),
      <String>['profile'],
    );
    expect(const MeNotAvailable('progress').placeId, 'progress');
  });

  testWidgets('every me sitemap row opens in one tap', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const MeHub()));
    await tester.pumpAndSettle();

    expect(find.text('Me'), findsOneWidget);
    const List<(String, String, Type)> rows = <(String, String, Type)>[
      ('profile', 'Profile and avatar', MeProfileScreen),
      ('progress', 'Progress', MeNotAvailablePage),
      ('achievements', 'Achievements', MeNotAvailablePage),
      ('leagues', 'Leagues', MeNotAvailablePage),
      ('family', 'Family', MeNotAvailablePage),
      ('plus', 'Plus', MeNotAvailablePage),
      ('settings', 'Settings', MeNotAvailablePage),
      ('about', 'About', MeNotAvailablePage),
    ];

    for (final (String id, String label, Type page) in rows) {
      expect(find.text(label), findsOneWidget);
      expect(tester.getSemantics(find.byKey(MeHub.placeKey(id))).label, label);
      await tester.tap(find.byKey(MeHub.placeKey(id)));
      await tester.pumpAndSettle();
      expect(find.byType(page), findsOneWidget);
      final ModalRoute<dynamic> route = ModalRoute.of(
        tester.element(find.byType(page)),
      )!;
      expect(route.settings.name, isNot(MeRoutes.root));
      expect(MeRoutes.tapsFromRoot(route.settings.name!), lessThanOrEqualTo(2));
      expect(MeRoutes.tapsFromRoot(route.settings.name!), 1);
      final Finder back = find.text('Back to Me');
      await tester.ensureVisible(back);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(MeHubPage), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('a place that is not built shows no sample rows', (tester) async {
    const List<(String, String)> gaps = <(String, String)>[
      (MeRoutes.progress, 'Progress'),
      (MeRoutes.achievements, 'Achievements'),
      (MeRoutes.leagues, 'Leagues'),
      (MeRoutes.family, 'Family'),
      (MeRoutes.plus, 'Plus'),
      (MeRoutes.settings, 'Settings'),
      (MeRoutes.about, 'About'),
    ];
    for (final (String path, String name) in gaps) {
      await tester.pumpWidget(
        _host(MeHub(key: ValueKey<String>(path), initialRoute: path)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MeNotAvailablePage), findsOneWidget);
      expect(MeRoutes.openingFor(path), isA<MeGapOpening>());
      expect(_lines(tester), <String>{
        name,
        'Not available yet',
        '$name is not available yet.',
        'This screen is not built yet.',
        'Go back to Me.',
        'Back to Me',
      });
    }
  });

  testWidgets('profile without a saved account shows no stand-in', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MeHub(initialRoute: MeRoutes.profile)));
    await tester.pumpAndSettle();

    expect(find.byType(MeProfileScreen), findsOneWidget);
    expect(find.byKey(MeProfileScreen.emptyKey), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(_lines(tester), <String>{
      'Profile and avatar',
      'No profile is saved on this phone.',
      'A name and avatar have not been saved.',
      'Go back to Me.',
      'Back to Me',
    });

    final ProfileModel hidden = _person(
      first: '',
      last: '',
      username: '',
      avatar: 'not-a-picture',
    );
    await tester.pumpWidget(
      _host(MeHub(initialRoute: MeRoutes.profile, account: hidden)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(MeProfileScreen.emptyKey), findsOneWidget);
    expect(find.text('secret@example.com'), findsNothing);
    expect(find.text('Nigeria'), findsNothing);
    expect(find.text('120'), findsNothing);
    expect(find.text('9'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a saved profile shows that name and avatar only', (
    tester,
  ) async {
    final String avatarKey = kAvatarsList.keys.first;
    await tester.pumpWidget(
      _host(
        MeHub(
          initialRoute: MeRoutes.profile,
          account: _person(avatar: avatarKey),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada Okafor'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('No avatar is saved.'), findsNothing);
    expect(find.text('secret@example.com'), findsNothing);
    expect(find.text('Nigeria'), findsNothing);
    expect(find.text('120'), findsNothing);
    expect(find.text('9'), findsNothing);
    expect(find.text('ada_codes'), findsNothing);
    expect(
      tester.getSemantics(find.byKey(MeProfileScreen.avatarKey)).label,
      'Avatar',
    );

    await tester.pumpWidget(
      _host(
        MeHub(initialRoute: MeRoutes.profile, account: _person(avatar: null)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada Okafor'), findsOneWidget);
    expect(find.text('No avatar is saved.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.pumpWidget(
      _host(
        MeHub(
          initialRoute: MeRoutes.profile,
          account: _person(
            first: '',
            last: '',
            username: '',
            avatar: avatarKey,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No name is saved.'), findsOneWidget);
    expect(find.text('Ada Okafor'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('an empty hub points to profile', (tester) async {
    await tester.pumpWidget(_host(const MeHub(status: MeHubStatus.empty)));
    await tester.pumpAndSettle();

    expect(find.byKey(MeHub.emptyKey), findsOneWidget);
    expect(find.text('Me has nothing to open yet.'), findsOneWidget);
    expect(find.text('No profile is saved.'), findsOneWidget);
    expect(find.text('Open Profile and avatar.'), findsOneWidget);
    expect(find.byKey(MeHub.placeKey('progress')), findsNothing);
    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(MeProfileScreen), findsOneWidget);
    expect(find.byKey(MeProfileScreen.emptyKey), findsOneWidget);
    expect(find.text('secret@example.com'), findsNothing);
  });

  testWidgets('error and offline name what to do', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(MeHub(status: MeHubStatus.error, onRetry: () => retries += 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Me did not open.'), findsOneWidget);
    expect(find.text('The list did not come back.'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);

    await tester.pumpWidget(_host(const MeHub(status: MeHubStatus.offline)));
    await tester.pumpAndSettle();
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(find.text('Me is not saved on the phone.'), findsOneWidget);
    expect(find.text('Connect, then try again.'), findsOneWidget);
    expect(find.byKey(MeHub.placeKey('leagues')), findsNothing);
  });

  testWidgets('rows stay at least 48 and wrap at 200 percent', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const MeHub(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final MePlace place in MeRoutes.places) {
      final Size size = tester.getSize(find.byKey(MeHub.placeKey(place.id)));
      expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
    }
    expect(find.text('Profile and avatar'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('reduced motion still shows the places', (tester) async {
    await tester.pumpWidget(_host(const MeHub(), reduced: true));
    await tester.pumpAndSettle();
    expect(find.text('Profile and avatar'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me from any tab returns to that same tab', (tester) async {
    for (final ShellTab tab in ShellTab.values) {
      late AppShellState shell;
      await tester.pumpWidget(
        _host(
          AppShell(
            key: ValueKey<ShellTab>(tab),
            index: tab.index,
            onMe: () => openMeHub(shell.navigatorOf(tab)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      shell = tester.state<AppShellState>(find.byType(AppShell));

      expect(shell.routeNameOf(tab), ShellRoutes.root);
      expect(_tabSelected(tester, tab), isTrue);

      await tester.tap(find.byKey(AppShell.toolKey(ShellTool.me)));
      await tester.pumpAndSettle();
      expect(find.byType(MeHubPage), findsOneWidget);
      expect(shell.routeNameOf(tab), MeRoutes.root);
      expect(_tabSelected(tester, tab), isTrue);
      for (final ShellTab other in ShellTab.values) {
        if (other == tab) continue;
        expect(shell.routeNameOf(other), ShellRoutes.root);
        expect(_tabSelected(tester, other), isFalse);
      }

      await tester.ensureVisible(find.byKey(MeHub.leaveKey));
      await tester.tap(find.byKey(MeHub.leaveKey));
      await tester.pumpAndSettle();
      expect(find.byType(MeHubPage), findsNothing);
      expect(shell.routeNameOf(tab), ShellRoutes.root);
      expect(_tabSelected(tester, tab), isTrue);
    }
  });
}
