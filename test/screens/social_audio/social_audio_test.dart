import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/social_audio/social_audio_room_model.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/navigation/hub_village.dart';
import 'package:lingafriq/screens/social_audio/following_screen.dart';
import 'package:lingafriq/screens/social_audio/scheduled_sessions_screen.dart';
import 'package:lingafriq/screens/village/villages_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'import walk from lib/main.dart reaches the registered Radio routes',
    () {
      final Set<String> reached = _reachableFrom('lib/main.dart');
      expect(reached, contains('lib/my_app.dart'));
      expect(reached, contains('lib/navigation/hub_village.dart'));
      expect(reached, contains('lib/screens/village/villages_hub_screen.dart'));
      expect(
        reached,
        contains('lib/screens/social_audio/following_screen.dart'),
      );
      expect(
        reached,
        contains('lib/screens/social_audio/scheduled_sessions_screen.dart'),
      );

      final String mainSource = File('lib/main.dart').readAsStringSync();
      expect(mainSource, contains("import 'my_app.dart'"));
      final String app = File('lib/my_app.dart').readAsStringSync();
      expect(app, contains('onGenerateRoute: generateAppRoute'));
      expect(app, contains('FollowingScreen.routeKey'));
      expect(app, contains('const FollowingScreen.live()'));
      expect(app, contains('ScheduledSessionsScreen.routeKey'));
      expect(app, contains('const ScheduledSessionsScreen.live()'));
      expect(
        app,
        contains("import 'screens/social_audio/following_screen.dart'"),
      );
      expect(
        app,
        contains(
          "import 'screens/social_audio/scheduled_sessions_screen.dart'",
        ),
      );

      expect(FollowingScreen.routePath, '/village/radio/following');
      expect(FollowingScreen.routeKey, 'village/radio/following');
      expect(ScheduledSessionsScreen.routePath, '/village/radio/scheduled');
      expect(ScheduledSessionsScreen.routeKey, 'village/radio/scheduled');
      expect(VillageRoutes.radioFollowing, FollowingScreen.routePath);
      expect(VillageRoutes.radioScheduled, ScheduledSessionsScreen.routePath);
      expect(VillageRoutes.find(VillageRoutes.radio)!.guardianGated, isTrue);
      expect(radioSpeakHostLocked(VillageAudience.minor), isTrue);
      expect(radioSpeakHostLocked(VillageAudience.adult), isFalse);
    },
  );

  test('rows without a name or id are dropped', () {
    final List<RadioPerson> people = radioPeopleFromRows(<Map<String, dynamic>>[
      <String, dynamic>{'id': '1', 'name': 'Ada'},
      <String, dynamic>{'user_id': '2'},
      <String, dynamic>{'bio': 'no name'},
    ]);
    expect(people.map((RadioPerson person) => person.label), <String>[
      'Ada',
      '2',
    ]);
    expect(
      people.map((RadioPerson person) => person.label),
      isNot(contains('Unknown')),
    );

    final SocialAudioRoom blank = _room(id: '', name: '   ');
    expect(scheduledRoomTitle(blank), isNull);
    final SocialAudioRoom named = _room(name: 'Folktale night');
    expect(scheduledRoomTitle(named), 'Folktale night');
    expect(const FollowingView.error().following, isEmpty);
    expect(const FollowingView.error().followers, isEmpty);
    expect(const ScheduledSessionsView.error().rooms, isEmpty);
  });

  testWidgets('the route table builds both Radio screens', (tester) async {
    final Map<String, Type> expected = <String, Type>{
      FollowingScreen.routePath: FollowingScreen,
      FollowingScreen.routeKey: FollowingScreen,
      ScheduledSessionsScreen.routePath: ScheduledSessionsScreen,
      ScheduledSessionsScreen.routeKey: ScheduledSessionsScreen,
    };
    for (final MapEntry<String, Type> entry in expected.entries) {
      late Widget built;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              final Route<dynamic>? route = generateAppRoute(
                RouteSettings(name: entry.key),
              );
              expect(route, isA<MaterialPageRoute<dynamic>>());
              built = (route! as MaterialPageRoute<dynamic>).builder(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(built.runtimeType, entry.value);
    }
  });

  testWidgets('Village radio opens following and scheduled', (tester) async {
    _wide(tester);
    await tester.pumpWidget(_host(const VillagesHubScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(VillageHub.placeKey('radio')));
    await tester.tap(find.byKey(VillageHub.placeKey('radio')));
    await tester.pumpAndSettle();
    expect(find.byType(VillageNotAvailablePage), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(VillageNotAvailablePage)),
      )!.settings.name,
      VillageRoutes.radio,
    );

    await tester.tap(find.byKey(VillageHub.radioFollowingKey));
    await tester.pumpAndSettle();
    expect(find.byType(FollowingScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(FollowingScreen)),
      )!.settings.name,
      FollowingScreen.routePath,
    );
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(FollowingScreen.emptyKey), findsOneWidget);
    expect(find.byKey(FollowingScreen.listKey), findsNothing);
    expect(find.byKey(FollowingScreen.speakKey), findsOneWidget);
    expect(find.byKey(FollowingScreen.hostKey), findsOneWidget);
    expect(find.text('Unknown'), findsNothing);

    await tester.tap(find.text('Back to Radio'));
    await tester.pumpAndSettle();
    expect(find.byType(VillageNotAvailablePage), findsOneWidget);

    await tester.tap(find.byKey(VillageHub.radioScheduledKey));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduledSessionsScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(ScheduledSessionsScreen)),
      )!.settings.name,
      ScheduledSessionsScreen.routePath,
    );
    expect(find.byKey(ScheduledSessionsScreen.emptyKey), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.listKey), findsNothing);
    expect(find.text('TBD'), findsNothing);
    expect(find.byKey(ScheduledSessionsScreen.speakKey), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.hostKey), findsOneWidget);
  });

  testWidgets('an empty following list stays empty and an error clears it', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const FollowingScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.text('No one is on this list.'), findsOneWidget);
    expect(find.byKey(FollowingScreen.listKey), findsNothing);
    expect(find.text('Ada'), findsNothing);

    await tester.pumpWidget(
      _host(
        FollowingScreen(
          load: () async => const FollowingView.ready(
            following: <RadioPerson>[RadioPerson(id: '1', label: 'Ada')],
            followers: <RadioPerson>[RadioPerson(id: '2', label: 'Kojo')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(FollowingScreen.listKey), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Kojo'), findsOneWidget);

    await tester.pumpWidget(
      _host(FollowingScreen(load: () async => const FollowingView.error())),
    );
    await tester.pump();
    expect(find.text('Ada'), findsNothing);
    expect(find.text('Kojo'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.byKey(FollowingScreen.errorKey), findsOneWidget);
    expect(find.byKey(FollowingScreen.listKey), findsNothing);
    expect(find.text('Ada'), findsNothing);
    expect(find.text('Kojo'), findsNothing);
    expect(find.text('The list did not open.'), findsOneWidget);
  });

  testWidgets('an empty schedule stays empty and an error clears the rooms', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const ScheduledSessionsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.emptyKey), findsOneWidget);
    expect(find.text('No session is scheduled.'), findsOneWidget);
    expect(find.text('TBD'), findsNothing);
    expect(find.text('Folktale night'), findsNothing);

    final SocialAudioRoom room = _room(
      name: 'Folktale night',
      hostName: 'Nia',
      when: DateTime(2026, 3, 15, 18, 30),
    );
    await tester.pumpWidget(
      _host(
        ScheduledSessionsScreen(
          load: () async =>
              ScheduledSessionsView.ready(<SocialAudioRoom>[room]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ScheduledSessionsScreen.listKey), findsOneWidget);
    expect(find.text('Folktale night'), findsOneWidget);
    expect(find.text('Hosted by Nia'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.text('TBD'), findsNothing);

    await tester.pumpWidget(
      _host(
        ScheduledSessionsScreen(
          load: () async => const ScheduledSessionsView.error(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Folktale night'), findsNothing);
    expect(find.text('Hosted by Nia'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.errorKey), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.listKey), findsNothing);
    expect(find.text('Folktale night'), findsNothing);
    expect(find.text('The sessions did not open.'), findsOneWidget);
  });

  testWidgets('a minor keeps speak and host locked on both Radio screens', (
    tester,
  ) async {
    _wide(tester);
    expect(radioSpeakHostLocked(VillageAudience.minor), isTrue);

    await tester.pumpWidget(_host(buildRadioFollowing(VillageAudience.minor)));
    await tester.pumpAndSettle();
    expect(find.byKey(FollowingScreen.lockedKey), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('A guardian must open this.'), findsOneWidget);
    expect(find.byKey(FollowingScreen.speakKey), findsNothing);
    expect(find.byKey(FollowingScreen.hostKey), findsNothing);
    expect(find.text('Speak'), findsNothing);
    expect(find.text('Host'), findsNothing);
    expect(find.byKey(FollowingScreen.emptyKey), findsOneWidget);

    await tester.pumpWidget(_host(buildRadioScheduled(VillageAudience.minor)));
    await tester.pumpAndSettle();
    expect(find.byKey(ScheduledSessionsScreen.lockedKey), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('A guardian must open this.'), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.speakKey), findsNothing);
    expect(find.byKey(ScheduledSessionsScreen.hostKey), findsNothing);
    expect(find.text('Speak'), findsNothing);
    expect(find.text('Host'), findsNothing);

    await tester.pumpWidget(_host(buildRadioFollowing(VillageAudience.adult)));
    await tester.pumpAndSettle();
    expect(find.byKey(FollowingScreen.speakKey), findsOneWidget);
    expect(find.byKey(FollowingScreen.hostKey), findsOneWidget);
    expect(find.byKey(FollowingScreen.lockedKey), findsNothing);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);

    await tester.pumpWidget(_host(buildRadioScheduled(VillageAudience.adult)));
    await tester.pumpAndSettle();
    expect(find.byKey(ScheduledSessionsScreen.speakKey), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.hostKey), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);
    expect(find.byKey(ScheduledSessionsScreen.lockedKey), findsNothing);
  });

  testWidgets('empty and error titles stay visible at 200 percent text', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const FollowingScreen(), scale: 2));
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'Following');
    _expectUnclipped(tester, 'No one is on this list.');

    await tester.pumpWidget(
      _host(
        FollowingScreen(load: () async => const FollowingView.error()),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'The list did not open.');

    await tester.pumpWidget(_host(const ScheduledSessionsScreen(), scale: 2));
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'Scheduled sessions');
    _expectUnclipped(tester, 'No session is scheduled.');

    await tester.pumpWidget(
      _host(
        ScheduledSessionsScreen(
          load: () async => const ScheduledSessionsView.error(),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'The sessions did not open.');
    expect(tester.takeException(), isNull);
  });
}

SocialAudioRoom _room({
  String id = 'room-1',
  String name = 'Room',
  String? hostName,
  DateTime? when,
}) {
  return SocialAudioRoom(
    id: id,
    name: name,
    description: 'A story',
    language: 'yo',
    hostName: hostName,
    type: RoomType.storytelling,
    status: RoomStatus.scheduled,
    createdAt: DateTime.utc(2026, 1, 1),
    scheduledStartTime: when,
  );
}

Set<String> _reachableFrom(String entry) {
  final Set<String> seen = <String>{};
  final List<String> queue = <String>[entry];
  final RegExp importRe = RegExp('''(?:import|export)\\s+['"]([^'"]+)['"]''');
  while (queue.isNotEmpty) {
    final String rel = queue.removeLast();
    if (!seen.add(rel)) continue;
    final File file = File(rel);
    if (!file.existsSync()) continue;
    final String source = file.readAsStringSync();
    for (final RegExpMatch match in importRe.allMatches(source)) {
      final String? next = _resolveImport(rel, match.group(1)!);
      if (next != null && File(next).existsSync()) queue.add(next);
    }
  }
  return seen;
}

String? _resolveImport(String fromRel, String spec) {
  if (spec.startsWith('dart:') || spec.startsWith('package:flutter')) {
    return null;
  }
  if (spec.startsWith('package:lingafriq/')) {
    return 'lib/${spec.substring('package:lingafriq/'.length)}';
  }
  if (spec.startsWith('package:')) return null;
  final String path = Uri.parse(fromRel).resolve(spec).path;
  final String normalized = path.startsWith('/') ? path.substring(1) : path;
  if (!normalized.startsWith('lib/') || !normalized.endsWith('.dart')) {
    return null;
  }
  return normalized;
}

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectUnclipped(WidgetTester tester, String title) {
  final Finder finder = find.text(title);
  expect(finder, findsWidgets);
  for (final Element element in finder.evaluate()) {
    final Text text = element.widget as Text;
    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, isNull);
    expect(
      tester.getSize(find.byWidget(text)).height,
      greaterThanOrEqualTo(LingAfriqType.bodySize),
    );
  }
  expect(tester.takeException(), isNull);
}

Widget _host(Widget child, {double scale = 1}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? routed) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: routed ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}
