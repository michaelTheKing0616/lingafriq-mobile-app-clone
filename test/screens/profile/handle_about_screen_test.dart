import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/hub_me.dart';
import 'package:lingafriq/screens/profile/global_handle_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/about_us_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app registers /me/handle and /me/about', () {
    expect(GlobalHandleEditScreen.routePath, '/me/handle');
    expect(GlobalHandleEditScreen.routeKey, 'me/handle');
    expect(AboutUsScreen.routePath, '/me/about');
    expect(AboutUsScreen.routeKey, 'me/about');
    expect(MeRoutes.about, AboutUsScreen.routePath);
    expect(MeRoutes.paths, contains(AboutUsScreen.routePath));

    final String app = File('lib/my_app.dart').readAsStringSync();
    expect(app, contains('GlobalHandleEditScreen.routeKey'));
    expect(app, contains('AboutUsScreen.routeKey'));
    expect(
      app,
      contains("import 'screens/profile/global_handle_edit_screen.dart'"),
    );
    expect(
      app,
      contains("import 'screens/tabs_view/profile/about_us_screen.dart'"),
    );
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains("import 'my_app.dart'"),
    );

    final String handle = File(
      'lib/screens/profile/global_handle_edit_screen.dart',
    ).readAsStringSync();
    expect(handle, isNot(contains('This handle is available')));
    expect(handle, isNot(contains('reservedNames')));
    expect(handle, isNot(contains('searchUsersByHandle')));

    final String about = File(
      'lib/screens/tabs_view/profile/about_us_screen.dart',
    ).readAsStringSync();
    expect(about, isNot(contains('be the first to know when the app is out')));
  });

  test('a handle verdict needs both server flags', () {
    final HandleVerdict taken = parseHandleVerdict(<String, dynamic>{
      'unique': false,
      'profanity_clear': true,
      'reason': 'This handle is already taken',
    });
    expect(taken.answered, isTrue);
    expect(taken.accepted, isFalse);
    expect(taken.unique, isFalse);
    expect(taken.profanityClear, isTrue);
    expect(taken.reason, 'This handle is already taken');

    final HandleVerdict profane = parseHandleVerdict(<String, dynamic>{
      'uniqueness': <String, dynamic>{'ok': true},
      'profanity': <String, dynamic>{
        'ok': false,
        'reason': 'That word is not allowed',
      },
    });
    expect(profane.accepted, isFalse);
    expect(profane.profanityClear, isFalse);
    expect(profane.reason, 'That word is not allowed');

    final HandleVerdict pass = parseHandleVerdict(<String, dynamic>{
      'unique': true,
      'profanity_clear': true,
    });
    expect(pass.accepted, isTrue);
    expect(pass.reason, isNull);

    final HandleVerdict availabilityOnly = parseHandleVerdict(<String, dynamic>{
      'available': true,
    });
    expect(availabilityOnly.answered, isFalse);
    expect(availabilityOnly.accepted, isFalse);
    expect(availabilityOnly.profanityClear, isNull);

    final HandleVerdict bareProfanity = parseHandleVerdict(<String, dynamic>{
      'unique': true,
      'profanity': true,
    });
    expect(bareProfanity.answered, isFalse);
    expect(bareProfanity.profanityClear, isNull);

    expect(parseHandleVerdict(null).answered, isFalse);
    expect(parseHandleVerdict(<String, dynamic>{}).accepted, isFalse);
  });

  testWidgets('Me opens /me/about and the app routes open both screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const MeHub()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(MeHub.placeKey('about')));
    await tester.tap(find.byKey(MeHub.placeKey('about')));
    await tester.pumpAndSettle();
    final ModalRoute<dynamic> route = ModalRoute.of(
      tester.element(find.byType(MeNotAvailablePage)),
    )!;
    expect(route.settings.name, '/me/about');

    final _Client client = _Client(loadView: const HandleView.empty());
    await tester.pumpWidget(_routes(client, id: 'handle'));
    await tester.tap(find.byKey(const ValueKey<String>('open-handle')));
    await tester.pumpAndSettle();
    expect(find.byKey(GlobalHandleEditScreen.emptyKey), findsOneWidget);
    expect(find.byType(GlobalHandleEditScreen), findsOneWidget);

    await tester.pumpWidget(_routes(client, id: 'about'));
    await tester.tap(find.byKey(const ValueKey<String>('open-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(AboutUsScreen.emptyKey), findsOneWidget);
    expect(find.byType(AboutUsScreen), findsOneWidget);
    expect(find.textContaining('be the first to know'), findsNothing);
  });

  testWidgets(
    'an empty about page stays empty and a load error drops the story',
    (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AboutUsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(AboutUsScreen.emptyKey), findsOneWidget);
      expect(find.text('No story is saved.'), findsOneWidget);
      expect(find.textContaining('be the first to know'), findsNothing);

      final List<AboutView> views = <AboutView>[
        const AboutView.ready('Once upon a story'),
        const AboutView.error(),
      ];
      int index = 0;
      Future<AboutView> load() async => views[index++];

      await tester.pumpWidget(_host(AboutUsScreen(load: load)));
      await tester.pumpAndSettle();
      expect(find.byKey(AboutUsScreen.storyKey), findsOneWidget);
      expect(find.text('Once upon a story'), findsOneWidget);

      await tester.pumpWidget(
        _host(AboutUsScreen(load: () async => const AboutView.error())),
      );
      await tester.pump();
      expect(find.text('Once upon a story'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(AboutUsScreen.errorKey), findsOneWidget);
      expect(find.text('Once upon a story'), findsNothing);
      expect(find.byKey(AboutUsScreen.storyKey), findsNothing);
    },
  );

  testWidgets('about offline shows the offline state and no story', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(AboutUsScreen(load: () async => const AboutView.offline())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AboutUsScreen.offlineKey), findsOneWidget);
    expect(find.byKey(AboutUsScreen.storyKey), findsNothing);
    expect(find.text('The phone has no network.'), findsOneWidget);
  });

  testWidgets('about at 200% text still shows the empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const AboutUsScreen(), scale: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(AboutUsScreen.emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an empty handle offers a blank field and a load error hides it',
    (WidgetTester tester) async {
      final _Client empty = _Client(loadView: const HandleView.empty());
      await tester.pumpWidget(_host(GlobalHandleEditScreen(client: empty)));
      await tester.pumpAndSettle();
      expect(find.byKey(GlobalHandleEditScreen.emptyKey), findsOneWidget);
      expect(find.text('No handle is saved.'), findsOneWidget);

      await tester.tap(find.text('Choose a handle'));
      await tester.pumpAndSettle();
      expect(find.byKey(GlobalHandleEditScreen.formKey), findsOneWidget);
      final TextField field = tester.widget<TextField>(
        find.byKey(GlobalHandleEditScreen.fieldKey),
      );
      expect(field.controller?.text, isEmpty);
      expect(find.byKey(GlobalHandleEditScreen.savedKey), findsNothing);

      final _Client failed = _Client(loadView: const HandleView.error());
      await tester.pumpWidget(
        _host(
          GlobalHandleEditScreen(
            client: failed,
            currentGlobalId: 'stale_handle',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('stale_handle'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(GlobalHandleEditScreen.errorKey), findsOneWidget);
      expect(find.text('stale_handle'), findsNothing);
      expect(find.byKey(GlobalHandleEditScreen.formKey), findsNothing);
      expect(find.byKey(GlobalHandleEditScreen.savedKey), findsNothing);
    },
  );

  testWidgets('a rejected handle shows the server reason and is not saved', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(
      loadView: const HandleView.ready('ada'),
      verdict: const HandleVerdict(
        availability: HandleCheckAvailability.answered,
        unique: false,
        profanityClear: true,
        reason: 'This handle is already taken',
      ),
    );
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    expect(find.text('ada'), findsWidgets);
    await tester.enterText(
      find.byKey(GlobalHandleEditScreen.fieldKey),
      'taken_name',
    );
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.checks, <String>['taken_name']);
    expect(client.saves, isEmpty);
    expect(find.byKey(GlobalHandleEditScreen.reasonKey), findsOneWidget);
    expect(find.text('This handle is already taken'), findsOneWidget);
    expect(find.byKey(GlobalHandleEditScreen.savedKey), findsNothing);
    expect(find.text('Handle saved.'), findsNothing);
  });

  testWidgets('profanity rejection shows the reason and does not save', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(
      loadView: const HandleView.empty(),
      verdict: const HandleVerdict(
        availability: HandleCheckAvailability.answered,
        unique: true,
        profanityClear: false,
        reason: 'That word is not allowed',
      ),
    );
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a handle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(GlobalHandleEditScreen.fieldKey),
      'bad_word',
    );
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.checks, <String>['bad_word']);
    expect(client.saves, isEmpty);
    expect(find.text('That word is not allowed'), findsOneWidget);
    expect(find.text('Handle saved.'), findsNothing);
  });

  testWidgets('a missing server check is an error and does not claim a save', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(
      loadView: const HandleView.ready('ada'),
      verdict: parseHandleVerdict(<String, dynamic>{'available': true}),
    );
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(GlobalHandleEditScreen.fieldKey),
      'maybe_free',
    );
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.checks, <String>['maybe_free']);
    expect(client.saves, isEmpty);
    expect(find.byKey(GlobalHandleEditScreen.checkKey), findsOneWidget);
    expect(
      find.text('Uniqueness and profanity could not be checked.'),
      findsOneWidget,
    );
    expect(find.byKey(GlobalHandleEditScreen.savedKey), findsNothing);
    expect(find.text('This handle is available'), findsNothing);
  });

  testWidgets('an offline check does not claim the handle was saved', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(
      loadView: const HandleView.ready('ada'),
      verdict: const HandleVerdict.offline(),
    );
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(GlobalHandleEditScreen.fieldKey), 'ada2');
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.saves, isEmpty);
    expect(find.byKey(GlobalHandleEditScreen.offlineKey), findsOneWidget);
    expect(find.text('Handle saved.'), findsNothing);
  });

  testWidgets('a failed save after both checks does not claim success', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(
      loadView: const HandleView.ready('ada'),
      verdict: const HandleVerdict(
        availability: HandleCheckAvailability.answered,
        unique: true,
        profanityClear: true,
      ),
      saveError: true,
    );
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(GlobalHandleEditScreen.fieldKey),
      'ada_ok',
    );
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.checks, <String>['ada_ok']);
    expect(client.saves, <String>['ada_ok']);
    expect(find.byKey(GlobalHandleEditScreen.saveErrorKey), findsOneWidget);
    expect(find.text('The server did not keep this handle.'), findsOneWidget);
    expect(find.text('Handle saved.'), findsNothing);
  });

  testWidgets('a passing server check then save keeps the handle', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(
      loadView: const HandleView.ready('ada'),
      verdict: const HandleVerdict(
        availability: HandleCheckAvailability.answered,
        unique: true,
        profanityClear: true,
      ),
      stored: 'ada_ok',
    );
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(GlobalHandleEditScreen.fieldKey),
      '@ada_ok',
    );
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.checks, <String>['ada_ok']);
    expect(client.saves, <String>['ada_ok']);
    expect(find.byKey(GlobalHandleEditScreen.savedKey), findsOneWidget);
    expect(find.text('Handle saved.'), findsOneWidget);
    expect(find.text('ada_ok'), findsWidgets);
  });

  testWidgets('a blank handle is not sent to the server', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(loadView: const HandleView.ready('ada'));
    await tester.pumpWidget(_host(GlobalHandleEditScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(GlobalHandleEditScreen.fieldKey), '   ');
    await tester.tap(find.byKey(GlobalHandleEditScreen.saveKey));
    await tester.pumpAndSettle();

    expect(client.checks, isEmpty);
    expect(client.saves, isEmpty);
    expect(find.byKey(GlobalHandleEditScreen.neededKey), findsOneWidget);
    expect(find.text('Handle saved.'), findsNothing);
  });

  testWidgets('handle offline load shows no saved handle', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(loadView: const HandleView.offline());
    await tester.pumpWidget(
      _host(
        GlobalHandleEditScreen(client: client, currentGlobalId: 'stale_handle'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(GlobalHandleEditScreen.offlineKey), findsOneWidget);
    expect(find.text('stale_handle'), findsNothing);
    expect(find.text('Handle saved.'), findsNothing);
  });

  testWidgets('handle at 200% text still shows the empty state', (
    WidgetTester tester,
  ) async {
    final _Client client = _Client(loadView: const HandleView.empty());
    await tester.pumpWidget(
      _host(GlobalHandleEditScreen(client: client), scale: 2),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(GlobalHandleEditScreen.emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(Widget child, {double scale = 1}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(textScaler: TextScaler.linear(scale)),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Widget _routes(_Client client, {required String id}) {
  return MaterialApp(
    key: ValueKey<String>(id),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateRoute: (RouteSettings settings) {
      final String raw = settings.name ?? '';
      final String key = raw.startsWith('/') ? raw.substring(1) : raw;
      if (key == GlobalHandleEditScreen.routeKey) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => GlobalHandleEditScreen(client: client),
        );
      }
      if (key == AboutUsScreen.routeKey) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AboutUsScreen(),
        );
      }
      return null;
    },
    home: Builder(
      builder: (BuildContext context) {
        return Column(
          children: <Widget>[
            TextButton(
              key: const ValueKey<String>('open-handle'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(GlobalHandleEditScreen.routePath);
              },
              child: const Text('open-handle'),
            ),
            TextButton(
              key: const ValueKey<String>('open-about'),
              onPressed: () {
                Navigator.of(context).pushNamed(AboutUsScreen.routePath);
              },
              child: const Text('open-about'),
            ),
          ],
        );
      },
    ),
  );
}

class _Client implements HandleClient {
  _Client({
    required this.loadView,
    this.verdict = const HandleVerdict.failed(),
    this.saveError = false,
    this.stored,
  });

  HandleView loadView;
  HandleVerdict verdict;
  bool saveError;
  String? stored;
  final List<String> checks = <String>[];
  final List<String> saves = <String>[];

  @override
  Future<HandleView> load() async => loadView;

  @override
  Future<HandleVerdict> check(String handle) async {
    checks.add(handle);
    return verdict;
  }

  @override
  Future<String> save(String handle) async {
    saves.add(handle);
    if (saveError) throw const HandleSaveException();
    return stored ?? handle;
  }
}
