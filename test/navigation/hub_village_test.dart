import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/hub_village.dart';
import 'package:lingafriq/screens/contribute/lesson_item_verification_screen.dart';
import 'package:lingafriq/screens/village/villages_hub_screen.dart';

const List<String> _fake = <String>[
  'Swahili',
  'Yoruba',
  'Wolof',
  'Kiswahili',
  '3 Active',
  'My Villages',
  '1245',
  'Amharic',
];

Widget _host(
  Widget child, {
  double scale = 1,
  bool reduced = false,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
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

Set<String> _lines(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data ?? '')
      .toSet();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('village routes are registered and within two taps', () {
    expect(VillageRoutes.sitemapIds, <String>[
      '/village',
      'map',
      'circles',
      'square',
      'chats',
      'status',
      'clips',
      'radio',
      'school',
      'elder hut',
      'corrections',
      'create',
      'verify',
    ]);
    expect(VillageRoutes.withinTwoTaps, isTrue);
    expect(VillageRoutes.places, hasLength(13));
    for (final String id in VillageRoutes.sitemapIds) {
      final VillagePlace? place = VillageRoutes.find(id);
      expect(place, isNotNull, reason: id);
      expect(place!.taps, inInclusiveRange(0, 2));
      expect(VillageRoutes.isRegistered(place.path), isTrue);
      expect(VillageRoutes.tapsFor(place.path), place.taps);
    }
    expect(VillageRoutes.tapsFor('/village'), 0);
    expect(VillageRoutes.tapsFor('map'), 0);
    expect(VillageRoutes.tapsFor('/village/map'), 0);
    expect(VillageRoutes.tapsFor('verify'), 2);
    expect(VillageRoutes.tapsFor('/village/nope'), -1);
    expect(
      VillageRoutes.guardianGated.map((VillagePlace place) => place.id),
      <String>['square', 'chats', 'clips', 'radio', 'create'],
    );
    expect(
      VillageRoutes.rootPlaces.map((VillagePlace place) => place.id),
      isNot(contains('verify')),
    );
    expect(
      VillageRoutes.openingFor(VillageRoutes.root),
      isA<VillageHubOpening>(),
    );
    expect(
      VillageRoutes.openingFor(VillageRoutes.map),
      isA<VillageHubOpening>(),
    );
    expect(
      VillageRoutes.openingFor(VillageRoutes.circles),
      isA<VillageGapOpening>(),
    );
    expect(
      VillageRoutes.openingFor(
        VillageRoutes.chats,
        audience: VillageAudience.minor,
        anyway: true,
      ),
      isA<VillageLockedOpening>().having(
        (VillageLockedOpening opening) => opening.gate,
        'gate',
        VillageGateKind.guardian,
      ),
    );
    expect(
      VillageRoutes.openingFor(VillageRoutes.clips, anyway: true),
      isA<VillageGapOpening>(),
    );
    expect(
      VillageRoutes.openingFor(VillageRoutes.create),
      isA<VillageLockedOpening>().having(
        (VillageLockedOpening opening) => opening.gate,
        'gate',
        VillageGateKind.level,
      ),
    );
    expect(
      VillageRoutes.openingFor(VillageRoutes.verify),
      isA<VillageHubOpening>(),
    );
    expect(VillageRoutes.verify, '/village/verify');
    expect(VillageRoutes.contribute, '/village/contribute');
    expect(VillageRoutes.teacher, '/village/school/teacher');
  });

  testWidgets('every village sitemap row opens in two taps or fewer', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const VillagesHubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Village'), findsOneWidget);
    expect(find.text('Village map'), findsOneWidget);
    expect(find.byType(VillageHubPage), findsOneWidget);
    expect(
      tester.widget<VillageStateMark>(find.byType(VillageStateMark)).kind,
      VillageSurfaceKind.ready,
    );
    for (final String banned in _fake) {
      expect(find.text(banned), findsNothing);
    }

    const List<String> open = <String>[
      'circles',
      'square',
      'status',
      'radio',
      'school',
      'elder hut',
      'corrections',
    ];
    for (final String id in open) {
      expect(VillageRoutes.find(id)!.taps, 1);
      await _tap(tester, find.byKey(VillageHub.placeKey(id)));
      expect(find.byType(VillageNotAvailablePage), findsOneWidget);
      expect(
        tester
            .widget<VillageStateMark>(
              find.descendant(
                of: find.byType(VillageNotAvailablePage),
                matching: find.byType(VillageStateMark),
              ),
            )
            .kind,
        VillageSurfaceKind.notAvailable,
      );
      final String? name = ModalRoute.of(
        tester.element(find.byType(VillageNotAvailablePage)),
      )!.settings.name;
      expect(VillageRoutes.tapsFor(name!), lessThanOrEqualTo(2));
      await _tap(tester, find.text('Back to Village'));
      expect(find.byType(VillageHubPage), findsOneWidget);
    }

    await _tap(tester, find.byKey(VillageHub.openAnywayKey('clips')));
    expect(find.byType(VillageNotAvailablePage), findsOneWidget);
    expect(find.text('Clips is not available yet.'), findsOneWidget);
    expect(find.textContaining('lesson'), findsNothing);
    await _tap(tester, find.text('Back to Village'));

    await _tap(tester, find.byKey(VillageHub.openAnywayKey('create')));
    expect(find.byType(VillageNotAvailablePage), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(VillageNotAvailablePage)))!
          .settings
          .name,
      VillageRoutes.create,
    );
    await _tap(tester, find.byKey(VillageHub.verifyKey));
    expect(find.byType(LessonItemVerificationScreen), findsOneWidget);
    final String verifyRoute = ModalRoute.of(
      tester.element(find.byType(LessonItemVerificationScreen)),
    )!.settings.name!;
    expect(verifyRoute, VillageRoutes.verify);
    expect(verifyRoute, '/village/verify');
    expect(VillageRoutes.tapsFor(verifyRoute), 2);
    expect(
      find.text('This account is not a verified native speaker.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Back to Village'));
    expect(find.byType(VillageHubPage), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('a place that is not built shows no sample rows', (tester) async {
    await tester.pumpWidget(
      _host(const VillageHub(initialRoute: VillageRoutes.circles)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VillageNotAvailablePage), findsOneWidget);
    expect(find.byKey(VillageHub.gapKey), findsOneWidget);
    expect(_lines(tester), <String>{
      'Circles',
      'Not available yet',
      'Circles is not available yet.',
      'This screen is not built yet.',
      'Go back to Village.',
      'Back to Village',
    });
    for (final String banned in _fake) {
      expect(find.text(banned), findsNothing);
    }
  });

  testWidgets('an empty hub points at the next step', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        VillageHub(status: VillageHubStatus.empty, onRetry: () => retries += 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(VillageHub.emptyKey), findsOneWidget);
    expect(find.text('No places yet.'), findsOneWidget);
    expect(find.text('The place list is empty.'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(VillageHub.placeKey('circles')), findsNothing);
    expect(find.text('Village map'), findsNothing);
    for (final String banned in _fake) {
      expect(find.text(banned), findsNothing);
    }
    expect(
      tester.widget<VillageStateMark>(find.byType(VillageStateMark)).kind,
      VillageSurfaceKind.empty,
    );
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('a minor sees guardian-gated rows locked and still listed', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const VillagesHubScreen(audience: VillageAudience.minor)),
    );
    await tester.pumpAndSettle();

    const List<String> locked = <String>[
      'square',
      'chats',
      'clips',
      'radio',
      'create',
    ];
    const List<String> labels = <String>[
      'Square',
      'Chats',
      'Clips',
      'Radio',
      'Create',
    ];
    for (final String id in VillageRoutes.rootPlaces.map(
      (VillagePlace place) => place.id,
    )) {
      expect(find.byKey(VillageHub.placeKey(id)), findsOneWidget);
    }
    for (final String label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Locked'), findsNWidgets(5));
    expect(find.text('A guardian must open this.'), findsNWidgets(5));
    expect(find.text('Preview'), findsNWidgets(5));
    expect(find.text('Open anyway'), findsNothing);
    expect(find.text('Unlocks at A2.'), findsNothing);
    expect(find.text('Unlocks at B1.'), findsNothing);
    await tester.ensureVisible(find.byKey(VillageHub.placeKey('chats')));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(VillageHub.placeKey('chats'))).label,
      'Chats, Locked. A guardian must open this.',
    );

    await _tap(tester, find.byKey(VillageHub.previewKey('chats')));
    expect(find.byType(VillageLockedPage), findsOneWidget);
    expect(find.byType(VillageNotAvailablePage), findsNothing);
    expect(_lines(tester), <String>{
      'Chats',
      'Locked',
      'A guardian must open this.',
      'Back to Village',
    });
    expect(find.text('Open anyway'), findsNothing);
    await _tap(tester, find.text('Back to Village'));
    expect(find.text('Chats'), findsOneWidget);

    await _tap(tester, find.byKey(VillageHub.placeKey('circles')));
    expect(find.byType(VillageNotAvailablePage), findsOneWidget);
    expect(find.text('Circles is not available yet.'), findsOneWidget);
    expect(locked, hasLength(5));
    handle.dispose();
  });

  testWidgets('an adult level lock offers preview and open anyway', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const VillageHub()));
    await tester.pumpAndSettle();

    expect(find.text('Unlocks at A2.'), findsOneWidget);
    expect(find.text('Unlocks at B1.'), findsOneWidget);
    expect(find.text('Open anyway'), findsNWidgets(2));
    expect(find.text('A guardian must open this.'), findsNothing);
    expect(find.text('Circles'), findsOneWidget);
    expect(find.text('Locked'), findsNWidgets(2));

    await _tap(tester, find.byKey(VillageHub.previewKey('clips')));
    expect(find.byType(VillageLockedPage), findsOneWidget);
    expect(_lines(tester), <String>{
      'Clips',
      'Locked',
      'Unlocks at A2.',
      'Back to Village',
    });
    expect(find.text('Open anyway'), findsNothing);
    await _tap(tester, find.text('Back to Village'));
    expect(find.byType(VillageHubPage), findsOneWidget);
  });

  testWidgets('error and offline name what to do', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        VillageHub(status: VillageHubStatus.error, onRetry: () => retries += 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Village did not open.'), findsOneWidget);
    expect(find.text('The place list did not come back.'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);

    await tester.pumpWidget(
      _host(const VillageHub(status: VillageHubStatus.offline)),
    );
    await tester.pumpAndSettle();
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(find.text('Village is not saved on the phone.'), findsOneWidget);
    expect(find.text('Connect, then try again.'), findsOneWidget);
    expect(find.byKey(VillageHub.placeKey('square')), findsNothing);
  });

  testWidgets('rows stay at least 48 and wrap at 200 percent', (tester) async {
    tester.view.physicalSize = const Size(390, 4800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const VillageHub(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final VillagePlace place in VillageRoutes.rootPlaces) {
      final VillageGateKind gate = villageGate(place, VillageAudience.adult);
      if (gate == VillageGateKind.none) {
        final Finder row = find.byKey(VillageHub.placeKey(place.id));
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        final Size size = tester.getSize(row);
        expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
        expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      } else {
        final Finder preview = find.byKey(VillageHub.previewKey(place.id));
        await tester.ensureVisible(preview);
        await tester.pumpAndSettle();
        expect(
          tester.getSize(preview).height,
          greaterThanOrEqualTo(LingAfriqTokens.spacing48),
        );
        final Finder open = find.byKey(VillageHub.openAnywayKey(place.id));
        await tester.ensureVisible(open);
        await tester.pumpAndSettle();
        expect(
          tester.getSize(open).height,
          greaterThanOrEqualTo(LingAfriqTokens.spacing48),
        );
      }
    }
    expect(find.text('Elder Hut'), findsOneWidget);
  });

  testWidgets('reduced motion and dark still list the places', (tester) async {
    await tester.pumpWidget(
      _host(
        const VillageHub(),
        reduced: true,
        theme: ThemeData(brightness: Brightness.dark),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Village map'), findsOneWidget);
    expect(find.text('Elder Hut'), findsOneWidget);
    expect(find.text('Corrections'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
