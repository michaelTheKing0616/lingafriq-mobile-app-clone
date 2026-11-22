import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/hub_speak.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';
import 'package:lingafriq/screens/tutor/shadowing_exercise_screen.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('speak routes are registered and within two taps', () {
    const List<String> required = <String>[
      SpeakRoutes.root,
      SpeakRoutes.polie,
      SpeakRoutes.scenarios,
      SpeakRoutes.personas,
      SpeakRoutes.mission,
      SpeakRoutes.shadowing,
      SpeakRoutes.codeSwitch,
      SpeakRoutes.missions,
      SpeakRoutes.coachInsights,
    ];
    expect(SpeakRoutes.paths, required);
    for (final String path in required) {
      expect(SpeakRoutes.isRegistered(path), isTrue, reason: path);
      expect(SpeakRoutes.tapsFromRoot(path), inInclusiveRange(0, 2));
    }
    expect(SpeakRoutes.tapsFromRoot(SpeakRoutes.root), 0);
    expect(SpeakRoutes.tapsFromRoot(SpeakRoutes.polie), 1);
    expect(SpeakRoutes.tapsFromRoot(SpeakRoutes.mission), 2);
    expect(SpeakRoutes.tapsFromRoot('/speak/nope'), -1);

    expect(SpeakRoutes.openingFor(SpeakRoutes.root), isA<SpeakHubOpening>());
    expect(SpeakRoutes.openingFor(SpeakRoutes.polie), isA<SpeakPolieOpening>());
    expect(
      SpeakRoutes.openingFor(SpeakRoutes.shadowing),
      isA<SpeakShadowingOpening>(),
    );
    for (final SpeakPlace place in SpeakRoutes.places) {
      if (place.kind != SpeakPlaceKind.notAvailable) continue;
      final SpeakOpening opening = SpeakRoutes.openingFor(place.path);
      expect(opening, isA<SpeakGapOpening>());
      final SpeakGapOpening gap = opening as SpeakGapOpening;
      expect(gap.gap.placeId, place.id);
    }
    expect(
      SpeakRoutes.places
          .where((SpeakPlace place) => place.kind == SpeakPlaceKind.ready)
          .map((SpeakPlace place) => place.id),
      <String>['polie', 'shadowing'],
    );
    expect(SpeakTutorMode.values, hasLength(6));
    expect(SpeakTutorMode.values, <SpeakTutorMode>[
      SpeakTutorMode.chat,
      SpeakTutorMode.explain,
      SpeakTutorMode.correctMe,
      SpeakTutorMode.roleplay,
      SpeakTutorMode.story,
      SpeakTutorMode.translate,
    ]);
  });

  testWidgets('every speak sitemap row opens in one tap', (tester) async {
    await tester.pumpWidget(_host(const SpeakHub()));
    await tester.pumpAndSettle();

    expect(find.text('Speak'), findsOneWidget);
    const List<(String, String, Type)> rows = <(String, String, Type)>[
      ('polie', 'Polie', SpeakPolieScreen),
      ('scenarios', 'Scenarios', SpeakNotAvailablePage),
      ('personas', 'Personas and Missions', SpeakNotAvailablePage),
      ('shadowing', 'Shadowing', ShadowingExerciseScreen),
      ('codeSwitch', 'Code-Switch and Respect', SpeakNotAvailablePage),
      ('missions', 'Speak Missions', SpeakNotAvailablePage),
      ('coach', 'Coach insights', SpeakNotAvailablePage),
    ];

    for (final (String id, String label, Type page) in rows) {
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.byKey(SpeakHub.placeKey(id)));
      await tester.pumpAndSettle();
      expect(find.byType(page), findsOneWidget);
      final ModalRoute<dynamic> route = ModalRoute.of(
        tester.element(find.byType(page)),
      )!;
      expect(route.settings.name, isNot(SpeakRoutes.root));
      expect(
        SpeakRoutes.tapsFromRoot(route.settings.name!),
        lessThanOrEqualTo(2),
      );
      final Finder back = find.text('Back to Speak');
      await tester.ensureVisible(back);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(SpeakHubPage), findsOneWidget);
    }
  });

  testWidgets('polie keeps the six named modes on one screen', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const SpeakHub()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeakHub.placeKey('polie')));
    await tester.pumpAndSettle();

    expect(find.byType(SpeakPolieScreen), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Explain'), findsOneWidget);
    expect(find.text('Correct me'), findsOneWidget);
    expect(find.text('Roleplay'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.text('Vocabulary'), findsNothing);
    expect(find.text('Pronunciation'), findsNothing);
    expect(find.text('Assessment'), findsNothing);
    expect(find.text('Grammar'), findsNothing);
    expect(find.text('Dialogue'), findsNothing);
    expect(find.text('Tutor'), findsNothing);
    expect(find.text('Review'), findsNothing);

    expect(
      tester
          .getSemantics(
            find.byKey(SpeakPolieScreen.modeKey(SpeakTutorMode.chat)),
          )
          .label,
      'Chat, on',
    );
    expect(
      tester
          .getSemantics(
            find.byKey(SpeakPolieScreen.modeKey(SpeakTutorMode.chat)),
          )
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(SpeakPolieScreen.modeKey(SpeakTutorMode.explain)),
          )
          .label,
      'Explain',
    );

    final String polieRoute = ModalRoute.of(
      tester.element(find.byType(SpeakPolieScreen)),
    )!.settings.name!;
    await tester.tap(
      find.byKey(SpeakPolieScreen.modeKey(SpeakTutorMode.story)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SpeakPolieScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(SpeakPolieScreen)),
      )!.settings.name,
      polieRoute,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(SpeakPolieScreen.modeKey(SpeakTutorMode.story)),
          )
          .label,
      'Story, on',
    );
    expect(find.text('Ẹ kú àárọ̀'), findsNothing);
    handle.dispose();
  });

  testWidgets('a place that is not built shows no sample rows', (tester) async {
    await tester.pumpWidget(
      _host(const SpeakHub(initialRoute: SpeakRoutes.scenarios)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SpeakNotAvailablePage), findsOneWidget);
    expect(
      SpeakRoutes.openingFor(SpeakRoutes.scenarios),
      isA<SpeakGapOpening>(),
    );
    final Set<String> lines = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text text) => text.data ?? '')
        .toSet();
    expect(lines, <String>{
      'Scenarios',
      'Not available yet',
      'Scenarios is not available yet.',
      'This screen is not built yet.',
      'Go back to Speak.',
      'Back to Speak',
    });
  });

  testWidgets('an empty hub points to Polie', (tester) async {
    await tester.pumpWidget(
      _host(const SpeakHub(status: SpeakHubStatus.empty)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SpeakHub.emptyKey), findsOneWidget);
    expect(find.text('Speak has nothing to open yet.'), findsOneWidget);
    expect(find.text('No speaking place is listed.'), findsOneWidget);
    expect(find.text('Open Polie and hold to talk.'), findsOneWidget);
    expect(find.byKey(SpeakHub.placeKey('scenarios')), findsNothing);
    await tester.tap(find.text('Open Polie'));
    await tester.pumpAndSettle();
    expect(find.byType(SpeakPolieScreen), findsOneWidget);
    expect(find.text('Hold to talk'), findsOneWidget);
    expect(find.text('Polie has not spoken.'), findsOneWidget);
  });

  testWidgets('hold to talk does not invent a reply', (tester) async {
    await tester.pumpWidget(_host(const SpeakPolieScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hold to talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hold to talk'));
    await tester.pumpAndSettle();
    expect(find.text('Polie has not spoken.'), findsOneWidget);
    expect(find.text('You have not held to talk.'), findsOneWidget);
    expect(find.text('Ẹ kú àárọ̀'), findsNothing);
  });

  testWidgets('error and offline name what to do', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        SpeakHub(status: SpeakHubStatus.error, onRetry: () => retries += 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Speak did not open.'), findsOneWidget);
    expect(find.text('The list did not come back.'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);

    await tester.pumpWidget(
      _host(const SpeakHub(status: SpeakHubStatus.offline)),
    );
    await tester.pumpAndSettle();
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(find.text('Speak is not saved on the phone.'), findsOneWidget);
    expect(find.text('Connect, then try again.'), findsOneWidget);
  });

  testWidgets('chips stay at least 48 and wrap at 200 percent', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const SpeakPolieScreen(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final SpeakTutorMode mode in SpeakTutorMode.values) {
      final Size size = tester.getSize(
        find.byKey(SpeakPolieScreen.modeKey(mode)),
      );
      expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
    }
    expect(find.text('Correct me'), findsOneWidget);
  });

  testWidgets('reduced motion still shows the six chips', (tester) async {
    await tester.pumpWidget(_host(const SpeakPolieScreen(), reduced: true));
    await tester.pumpAndSettle();
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
