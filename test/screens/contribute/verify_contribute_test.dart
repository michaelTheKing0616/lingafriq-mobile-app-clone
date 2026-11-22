import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/navigation/hub_village.dart';
import 'package:lingafriq/screens/contribute/lesson_item_verification_screen.dart';
import 'package:lingafriq/screens/contribute/native_speaker_contribution_screen.dart';
import 'package:lingafriq/screens/gamification/classroom_dashboard_screen.dart';
import 'package:lingafriq/screens/village/villages_hub_screen.dart';
import 'package:lingafriq/services/lesson_item_verification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'import walk from lib/main.dart reaches verify, contribute, and teacher',
    () {
      final Set<String> reached = _reachableFrom('lib/main.dart');
      expect(reached, contains('lib/my_app.dart'));
      expect(reached, contains('lib/navigation/hub_village.dart'));
      expect(
        reached,
        contains('lib/screens/contribute/lesson_item_verification_screen.dart'),
      );
      expect(
        reached,
        contains(
          'lib/screens/contribute/native_speaker_contribution_screen.dart',
        ),
      );
      expect(
        reached,
        contains('lib/screens/gamification/classroom_dashboard_screen.dart'),
      );

      final String mainSource = File('lib/main.dart').readAsStringSync();
      expect(mainSource, contains("import 'my_app.dart'"));
      final String app = File('lib/my_app.dart').readAsStringSync();
      expect(app, contains('onGenerateRoute: generateAppRoute'));
      expect(app, contains('LessonItemVerificationScreen.routeKey'));
      expect(app, contains('LessonItemVerificationScreen.live'));
      expect(app, contains('NativeSpeakerContributionScreen.routeKey'));
      expect(app, contains('const NativeSpeakerContributionScreen.live()'));
      expect(app, contains('ClassroomDashboardScreen.routeKey'));
      expect(
        app,
        contains(
          "import 'screens/contribute/lesson_item_verification_screen.dart'",
        ),
      );
      expect(
        app,
        contains(
          "import 'screens/contribute/native_speaker_contribution_screen.dart'",
        ),
      );
      expect(
        app,
        contains("import 'screens/gamification/classroom_dashboard_screen.dart'"),
      );

      expect(LessonItemVerificationScreen.routePath, '/village/verify');
      expect(LessonItemVerificationScreen.routeKey, 'village/verify');
      expect(NativeSpeakerContributionScreen.routePath, '/village/contribute');
      expect(NativeSpeakerContributionScreen.routeKey, 'village/contribute');
      expect(ClassroomDashboardScreen.routePath, '/village/school/teacher');
      expect(ClassroomDashboardScreen.routeKey, 'village/school/teacher');
      expect(VillageRoutes.verify, LessonItemVerificationScreen.routePath);
      expect(
        VillageRoutes.contribute,
        NativeSpeakerContributionScreen.routePath,
      );
      expect(VillageRoutes.teacher, ClassroomDashboardScreen.routePath);

      final String hub = File('lib/navigation/hub_village.dart').readAsStringSync();
      expect(hub, contains('VillageRoutes.verify'));
      expect(hub, contains('VillageRoutes.contribute'));
      expect(hub, contains('VillageRoutes.teacher'));
    },
  );

  test('a blank lesson row is dropped', () {
    final items = verificationItemsFromRows(<Map<String, dynamic>>[
      <String, dynamic>{'id': '1', 'text': 'Bawo ni', 'translation': 'How are you'},
      <String, dynamic>{'id': '2', 'text': '   ', 'translation': 'skip me'},
    ]);
    expect(items.map((item) => item.text), <String>['Bawo ni']);
    expect(const VerificationQueue.error().items, isEmpty);
    expect(const VerificationQueue.offline().items, isEmpty);
    expect(const ContributionView.error().prompts, isEmpty);
  });

  testWidgets('the route table registers the three Village paths', (
    tester,
  ) async {
    final Map<String, Type> expected = <String, Type>{
      '/village/verify': LessonItemVerificationScreen,
      'village/verify': LessonItemVerificationScreen,
      '/village/contribute': NativeSpeakerContributionScreen,
      'village/contribute': NativeSpeakerContributionScreen,
      '/village/school/teacher': ClassroomDashboardScreen,
      'village/school/teacher': ClassroomDashboardScreen,
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
      if (built is LessonItemVerificationScreen) {
        expect(
          (built as LessonItemVerificationScreen).verifiedNativeSpeaker,
          isFalse,
        );
      }
      if (built is ClassroomDashboardScreen) {
        expect((built as ClassroomDashboardScreen).isTeacher, isFalse);
      }
    }

    late Widget verified;
    late Widget recorded;
    late Widget teacher;
    late Widget deniedAccount;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            verified = (generateAppRoute(
              const RouteSettings(
                name: '/village/verify',
                arguments: <String, dynamic>{'verifiedNativeSpeaker': true},
              ),
            )! as MaterialPageRoute<dynamic>).builder(context);
            recorded = (generateAppRoute(
              const RouteSettings(
                name: '/village/verify',
                arguments: <String, dynamic>{
                  'account': <String, dynamic>{'verifiedNativeSpeaker': true},
                },
              ),
            )! as MaterialPageRoute<dynamic>).builder(context);
            teacher = (generateAppRoute(
              const RouteSettings(
                name: '/village/school/teacher',
                arguments: <String, dynamic>{
                  'account': <String, dynamic>{'teacher': true},
                },
              ),
            )! as MaterialPageRoute<dynamic>).builder(context);
            deniedAccount = (generateAppRoute(
              const RouteSettings(
                name: '/village/school/teacher',
                arguments: <String, dynamic>{
                  'account': <String, dynamic>{'name': 'Ada'},
                },
              ),
            )! as MaterialPageRoute<dynamic>).builder(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(
      (verified as LessonItemVerificationScreen).verifiedNativeSpeaker,
      isTrue,
    );
    expect(
      (recorded as LessonItemVerificationScreen).verifiedNativeSpeaker,
      isTrue,
    );
    expect((teacher as ClassroomDashboardScreen).isTeacher, isTrue);
    expect((deniedAccount as ClassroomDashboardScreen).isTeacher, isFalse);
  });

  testWidgets('Village entries open verify, contribute, and teacher', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const VillagesHubScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(VillageHub.openAnywayKey('create')));
    await tester.tap(find.byKey(VillageHub.openAnywayKey('create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VillageHub.verifyKey));
    await tester.pumpAndSettle();
    expect(find.byType(LessonItemVerificationScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(LessonItemVerificationScreen)),
      )!.settings.name,
      '/village/verify',
    );
    expect(find.byKey(LessonItemVerificationScreen.limitedKey), findsOneWidget);
    expect(
      find.text('This account is not a verified native speaker.'),
      findsOneWidget,
    );
    expect(find.byKey(LessonItemVerificationScreen.listKey), findsNothing);

    await tester.tap(find.text('Back to Village'));
    await tester.pumpAndSettle();
    expect(find.byType(VillageHubPage), findsOneWidget);

    await tester.ensureVisible(find.byKey(VillageHub.openAnywayKey('create')));
    await tester.tap(find.byKey(VillageHub.openAnywayKey('create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VillageHub.contributeKey));
    await tester.pumpAndSettle();
    expect(find.byType(NativeSpeakerContributionScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(NativeSpeakerContributionScreen)),
      )!.settings.name,
      '/village/contribute',
    );
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(NativeSpeakerContributionScreen.emptyKey), findsOneWidget);

    await tester.tap(find.text('Back to Village'));
    await tester.pumpAndSettle();
    expect(find.byType(VillageHubPage), findsOneWidget);

    await tester.ensureVisible(find.byKey(VillageHub.placeKey('school')));
    await tester.tap(find.byKey(VillageHub.placeKey('school')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VillageHub.teacherKey));
    await tester.pumpAndSettle();
    expect(find.byType(ClassroomDashboardScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(ClassroomDashboardScreen)),
      )!.settings.name,
      '/village/school/teacher',
    );
    expect(find.byKey(ClassroomDashboardScreen.deniedKey), findsOneWidget);
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('This account is not a teacher.'), findsOneWidget);
    expect(find.text('Learners'), findsNothing);
    expect(find.text('Class Overview'), findsNothing);
  });

  testWidgets('an empty verify queue stays empty and an error clears it', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(
      _host(const LessonItemVerificationScreen(verifiedNativeSpeaker: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(LessonItemVerificationScreen.emptyKey), findsOneWidget);
    expect(find.text('No lesson item is waiting.'), findsOneWidget);
    expect(find.byKey(LessonItemVerificationScreen.listKey), findsNothing);
    expect(find.text('Bawo ni'), findsNothing);

    await tester.pumpWidget(
      _host(
        LessonItemVerificationScreen(
          verifiedNativeSpeaker: true,
          load: () async => VerificationQueue.ready(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': '1',
              'text': 'Bawo ni',
              'translation': 'How are you',
            },
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonItemVerificationScreen.listKey), findsOneWidget);
    expect(find.text('Bawo ni'), findsOneWidget);
    expect(find.text('How are you'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        LessonItemVerificationScreen(
          verifiedNativeSpeaker: true,
          load: () async => const VerificationQueue.error(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Bawo ni'), findsNothing);
    expect(find.text('How are you'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.byKey(LessonItemVerificationScreen.errorKey), findsOneWidget);
    expect(find.byKey(LessonItemVerificationScreen.listKey), findsNothing);
    expect(find.text('Bawo ni'), findsNothing);
    expect(find.text('The queue did not open.'), findsOneWidget);
  });

  testWidgets('an empty contribute list stays empty and an error clears it', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const NativeSpeakerContributionScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(NativeSpeakerContributionScreen.emptyKey), findsOneWidget);
    expect(find.text('No prompt is ready.'), findsOneWidget);
    expect(find.byKey(NativeSpeakerContributionScreen.listKey), findsNothing);
    expect(find.text('E kaaro'), findsNothing);

    await tester.pumpWidget(
      _host(
        NativeSpeakerContributionScreen(
          load: () async => ContributionView.ready(<RecordingPrompt>[
            RecordingPrompt(
              id: '1',
              text: 'E kaaro',
              translation: 'Good morning',
              instructions: 'Speak clearly',
              category: 'words',
              language: 'Yoruba',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(NativeSpeakerContributionScreen.listKey), findsOneWidget);
    expect(find.text('E kaaro'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        NativeSpeakerContributionScreen(
          load: () async => const ContributionView.error(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('E kaaro'), findsNothing);
    expect(find.text('Good morning'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.byKey(NativeSpeakerContributionScreen.errorKey), findsOneWidget);
    expect(find.byKey(NativeSpeakerContributionScreen.listKey), findsNothing);
    expect(find.text('E kaaro'), findsNothing);
    expect(find.text('The prompts did not open.'), findsOneWidget);
  });

  testWidgets('a person who is not a verified native speaker cannot verify', (
    tester,
  ) async {
    _wide(tester);
    var calls = 0;
    await tester.pumpWidget(
      _host(
        LessonItemVerificationScreen(
          load: () async {
            calls += 1;
            return VerificationQueue.ready(<Map<String, dynamic>>[
              <String, dynamic>{'id': '1', 'text': 'Bawo ni'},
            ]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byKey(LessonItemVerificationScreen.limitedKey), findsOneWidget);
    expect(
      find.text('This account is not a verified native speaker.'),
      findsOneWidget,
    );
    expect(find.text('Verify is limited.'), findsOneWidget);
    expect(find.text('Bawo ni'), findsNothing);
    expect(find.byKey(LessonItemVerificationScreen.listKey), findsNothing);
    expect(find.byType(LingEmptyState), findsNothing);

    await tester.pumpWidget(
      _host(
        LessonItemVerificationScreen(
          verifiedNativeSpeaker: false,
          load: () async {
            calls += 1;
            return VerificationQueue.ready(<Map<String, dynamic>>[
              <String, dynamic>{'id': '1', 'text': 'Bawo ni'},
            ]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Bawo ni'), findsNothing);
  });

  testWidgets('a caller-marked native speaker can see the queue', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(
      _host(const VillageHub(verifiedNativeSpeaker: true)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(VillageHub.openAnywayKey('create')));
    await tester.tap(find.byKey(VillageHub.openAnywayKey('create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VillageHub.verifyKey));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonItemVerificationScreen.limitedKey), findsNothing);
    expect(
      find.text('This account is not a verified native speaker.'),
      findsNothing,
    );
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.text('No lesson item is waiting.'), findsOneWidget);
  });

  testWidgets('a non-teacher is denied and a teacher can see the dashboard', (
    tester,
  ) async {
    _wide(tester);
    var loads = 0;
    await tester.pumpWidget(
      _screenHost(
        ClassroomDashboardScreen(
          tribeId: 'tribe-9',
          tribeName: 'Ada class',
          languageTag: 'yo',
          dashboardLoad: () async {
            loads += 1;
            return <String, dynamic>{
              'classroom': <Map<String, dynamic>>[
                <String, dynamic>{'username': 'Kojo'},
              ],
              'aggregate': <String, dynamic>{},
            };
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 0);
    expect(find.byKey(ClassroomDashboardScreen.deniedKey), findsOneWidget);
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('This account is not a teacher.'), findsOneWidget);
    expect(find.text('This dashboard is closed.'), findsOneWidget);
    expect(find.textContaining('Ada class'), findsNothing);
    expect(find.text('Kojo'), findsNothing);
    expect(find.text('Learners'), findsNothing);
    expect(find.text('Class Overview'), findsNothing);

    await tester.pumpWidget(
      _screenHost(
        ClassroomDashboardScreen(
          tribeId: 'tribe-9',
          tribeName: 'Ada class',
          languageTag: 'yo',
          isTeacher: true,
          dashboardLoad: () async {
            loads += 1;
            return <String, dynamic>{
              'classroom': <Map<String, dynamic>>[
                <String, dynamic>{'username': 'Kojo'},
              ],
              'aggregate': <String, dynamic>{'classSize': 1},
            };
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(find.byKey(ClassroomDashboardScreen.deniedKey), findsNothing);
    expect(find.text('This account is not a teacher.'), findsNothing);
    expect(find.text('Class Overview'), findsWidgets);
    expect(find.text('Learners'), findsWidgets);
    expect(find.text('Kojo'), findsOneWidget);
    expect(find.textContaining('Ada class'), findsOneWidget);
  });

  testWidgets('limited and empty copy stays visible at 200 percent text', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(
      _host(const LessonItemVerificationScreen(), scale: 2),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'Verify is limited.');
    _expectUnclipped(
      tester,
      'This account is not a verified native speaker.',
    );

    await tester.pumpWidget(
      _host(
        const LessonItemVerificationScreen(verifiedNativeSpeaker: true),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'No lesson item is waiting.');

    await tester.pumpWidget(
      _host(const NativeSpeakerContributionScreen(), scale: 2),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'No prompt is ready.');
    expect(tester.takeException(), isNull);
  });
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
  return ProviderScope(
    child: MaterialApp(
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
    ),
  );
}

Widget _screenHost(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 2400)),
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? _) => child,
        ),
      ),
    ),
  );
}
