import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/screens/classroom/live_classroom_screen.dart';
import 'package:lingafriq/screens/gamification/classroom_dashboard_screen.dart';
import 'package:lingafriq/services/gamification/tribes_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('harvested session rules', () {
    test('only recorded media is kept, and only a teacher camera turns on', () {
      expect(shouldPersistClassAv('recorded'), isTrue);
      expect(shouldPersistClassAv('unrecorded'), isFalse);
      expect(shouldPersistClassAv('pending'), isFalse);
      expect(shouldPersistClassAv(null), isFalse);
      expect(
        classSessionCameraEnabled(mediaState: 'recorded', isTeacher: true),
        isTrue,
      );
      expect(
        classSessionCameraEnabled(mediaState: 'recorded', isTeacher: false),
        isFalse,
      );
      expect(
        classSessionCameraEnabled(mediaState: 'unrecorded', isTeacher: true),
        isFalse,
      );
    });

    test('consent, connect, and recording banner follow the session screen', () {
      expect(classSessionNeedsConsentPrompt(null), isTrue);
      expect(classSessionNeedsConsentPrompt('granted'), isFalse);
      expect(classSessionNeedsConsentPrompt('declined'), isFalse);
      expect(
        phaseAfterRecordingConsent('declined'),
        ClassSessionLivePhase.declined,
      );
      expect(
        phaseAfterRecordingConsent('granted'),
        ClassSessionLivePhase.lobby,
      );
      expect(
        phaseAfterLiveConnect(recordingActive: true),
        ClassSessionLivePhase.recording,
      );
      expect(
        phaseAfterLiveConnect(recordingActive: false),
        ClassSessionLivePhase.live,
      );
      expect(
        classSessionShowsRecordingBanner(
          recordingActive: false,
          phase: ClassSessionLivePhase.recording,
        ),
        isTrue,
      );
      expect(
        classSessionShowsRecordingBanner(
          recordingActive: false,
          phase: ClassSessionLivePhase.live,
        ),
        isFalse,
      );
      expect(classSessionPhaseLabel(ClassSessionLivePhase.recording), 'Recording');
      expect(classSessionPhaseLabel(ClassSessionLivePhase.declined), 'Unrecorded');
      expect(sessionRecordingIndicatorCopy, isNotEmpty);
      expect(sessionConsentAskCopy, isNotEmpty);
      expect(sessionRecordingIndicatorCopy.contains('—'), isFalse);
      expect(sessionQueuedCheckInCopy.contains('—'), isFalse);
      expect(classroomAttendanceCheckInType, 'classroom_attendance_checkin');
      expect(classroomOutboxSyncBatchSize, 50);
    });

    test('active session and date label come from the session list', () {
      expect(activeClassSession(const []), isNull);
      final active = activeClassSession(const [
        {'sessionId': 'old', 'status': 'ended'},
        {'sessionId': 'now', 'status': 'active'},
      ]);
      expect(active?['sessionId'], 'now');
      expect(classSessionDateLabel(null), 'Session');
      expect(classSessionDateLabel('not-a-date'), 'Session');
      expect(classSessionDateLabel('2026-03-04T12:00:00Z'), '2026-03-04');
    });
  });

  group('route arguments harvested from classroom_v2_route_args', () {
    test('missing or blank tribe id stays on the catalog', () {
      final missing = liveClassroomRouteConfig(null);
      expect(missing.entry, LiveClassroomEntry.catalog);
      expect(missing.tribeId, isNull);
      expect(missing.tribeName, isNull);

      final blank = liveClassroomRouteConfig({
        'tribeId': '  ',
        'tribeName': 'My Class',
      });
      expect(blank.tribeId, isNull);
      expect(blank.entry, LiveClassroomEntry.catalog);

      final notAMap = liveClassroomRouteConfig('tribe');
      expect(notAMap.entry, LiveClassroomEntry.catalog);
    });

    test('tribe id opens the session and a room id opens the room', () {
      final session = liveClassroomRouteConfig({
        'tribeId': ' abc ',
        'tribeName': ' Room ',
        'languageTag': ' yo ',
      });
      expect(session.tribeId, 'abc');
      expect(session.tribeName, 'Room');
      expect(session.languageTag, 'yo');
      expect(session.entry, LiveClassroomEntry.session);

      final room = liveClassroomRouteConfig({
        'tribeId': 'abc',
        'tribeName': 'Room',
        'roomId': 'abc',
        'roomName': 'Room',
      });
      expect(room.entry, LiveClassroomEntry.room);
      expect(room.roomId, 'abc');
    });
  });

  group('lobby room list', () {
    test('classroom tribes win, and a hot room is a headcount over 20', () {
      final rooms = classroomRoomsFromTribes([
        {
          'id': 'c1',
          'name': 'Yoruba Circle',
          'language_tag': 'yo',
          'members_count': 21,
          'is_classroom': true,
        },
        {
          'id': 'n1',
          'name': 'Hidden tribe',
          'is_classroom': false,
        },
      ]);
      expect(rooms, hasLength(1));
      expect(rooms.single.title, 'Yoruba Circle');
      expect(rooms.single.language, 'yo');
      expect(rooms.single.instructor, 'Community classroom');
      expect(rooms.single.isTrending, isTrue);
      expect(rooms.single.isLive, isFalse);
      expect(rooms.single.tribeId, 'c1');
    });

    test('an empty classroom flag falls back to the tribe list', () {
      final rooms = classroomRoomsFromTribes([
        {
          '_id': 'mongo-1',
          'name': 'Village chat',
          'language_tag': '',
          'members_count': '4',
          'is_classroom': false,
        },
      ]);
      expect(rooms.single.tribeId, 'mongo-1');
      expect(rooms.single.participants, 4);
      expect(rooms.single.language, isEmpty);
      expect(rooms.single.isTrending, isFalse);
    });

    test('filters are the lobby chips and do not describe a second list', () {
      expect(classroomLobbyFilters, ['All', 'Starting Soon', 'My Languages']);
    });
  });

  testWidgets('classroom-lobby route builds the live classroom', (tester) async {
    late Widget lobby;
    late Widget teacher;
    late Widget material3;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            lobby = (generateAppRoute(
              const RouteSettings(name: '/classroom-lobby'),
            )! as MaterialPageRoute<dynamic>)
                .builder(context);
            final withTribe = (generateAppRoute(
              const RouteSettings(
                name: 'classroom-lobby',
                arguments: <String, dynamic>{
                  'tribeId': ' abc ',
                  'tribeName': ' Room ',
                },
              ),
            )! as MaterialPageRoute<dynamic>)
                .builder(context) as LiveClassroomScreen;
            expect(withTribe.tribeId, 'abc');
            expect(withTribe.tribeName, 'Room');
            expect(withTribe.entry, LiveClassroomEntry.session);
            teacher = (generateAppRoute(
              const RouteSettings(name: '/village/school/teacher'),
            )! as MaterialPageRoute<dynamic>)
                .builder(context);
            material3 = (generateAppRoute(
              const RouteSettings(name: '/live-classroom'),
            )! as MaterialPageRoute<dynamic>)
                .builder(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(lobby, isA<LiveClassroomScreen>());
    expect((lobby as LiveClassroomScreen).entry, LiveClassroomEntry.catalog);
    expect(teacher, isA<ClassroomDashboardScreen>());
    expect((teacher as ClassroomDashboardScreen).isTeacher, isFalse);
    expect(material3.runtimeType.toString(), 'LiveClassroomScreenMaterial3');

    final app = File('lib/my_app.dart').readAsStringSync();
    expect(app.contains('ClassroomLobbyScreen'), isFalse);
    expect(app.contains('classroom_lobby_screen.dart'), isFalse);
    expect(
      File('lib/screens/classroom/classroom_lobby_screen.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/screens/classroom/classroom_session_screen.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/screens/classroom/live_classroom_mobile_screen.dart')
          .existsSync(),
      isFalse,
    );
  });

  testWidgets('catalog shows classroom tribes, notes, and the speaker queue', (
    tester,
  ) async {
    final seen = <RouteSettings>[];
    await _pump(
      tester,
      LiveClassroomScreen(
        loaders: LiveClassroomLoaders(
          loadTribes: () async => [
            {
              'id': 'tribe-1',
              'name': 'Yoruba Circle',
              'language_tag': 'yo',
              'members_count': 25,
              'is_classroom': true,
            },
            {
              'id': 'tribe-2',
              'name': 'Hidden tribe',
              'language_tag': 'sw',
              'members_count': 2,
              'is_classroom': false,
            },
          ],
        ),
      ),
      onGenerateRoute: (settings) {
        seen.add(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(body: Text(settings.name ?? '')),
        );
      },
    );
    await _flush(tester);

    expect(find.text('Practice Rooms'), findsOneWidget);
    expect(find.text('Enter class code'), findsOneWidget);
    expect(find.text('Yoruba Circle'), findsOneWidget);
    expect(find.text('Hidden tribe'), findsNothing);
    expect(find.text('yo'), findsOneWidget);
    expect(find.text('Community classroom'), findsOneWidget);
    expect(find.text('HOT'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('—'), findsNothing);

    await tester.tap(find.text('STARTING SOON'));
    await tester.pump();
    expect(find.text('Yoruba Circle'), findsOneWidget);
    expect(find.text('MY LANGUAGES'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Queue'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Queue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(seen.last.name, '/speaker-queue');
    final queueArgs = seen.last.arguments! as Map;
    expect(queueArgs['tribeId'], 'tribe-1');
    expect(queueArgs['roomName'], 'Yoruba Circle');

    Navigator.of(tester.element(find.text('/speaker-queue'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Notes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(seen.last.name, '/classroom-notes');
    final noteArgs = seen.last.arguments! as Map;
    expect(noteArgs['tribeId'], 'tribe-1');
    expect(noteArgs['roomName'], 'Yoruba Circle');
  });

  testWidgets('empty catalog, load error, and class code sheet', (tester) async {
    await _pump(
      tester,
      LiveClassroomScreen(
        loaders: LiveClassroomLoaders(loadTribes: () async => const []),
      ),
    );
    await _flush(tester);
    expect(
      find.text(
        'No classroom sessions yet. Create a classroom tribe on the server or use Live Classroom to host.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('lobby-enter-class-code')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ask your teacher for the class code.'), findsOneWidget);
  });

  testWidgets('catalog error copy and the host room', (tester) async {
    await _pump(
      tester,
      LiveClassroomScreen(
        loaders: LiveClassroomLoaders(
          loadTribes: () async => throw Exception('down'),
        ),
      ),
    );
    await _flush(tester);
    expect(
      find.text('Could not load classrooms. Pull to retry.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Active Lesson'), findsOneWidget);
    expect(find.text('Greetings & Introductions'), findsOneWidget);
    expect(find.text('Yoruba Conversations'), findsWidgets);
  });

  testWidgets('production catalog asks for classroom tribes', (tester) async {
    final tribes = _RecordingTribes();
    await _pump(
      tester,
      const LiveClassroomScreen(),
      overrides: [tribesServiceProvider.overrideWithValue(tribes)],
    );
    await _flush(tester);
    expect(tribes.includeClassrooms, isTrue);
    expect(
      find.text(
        'No classroom sessions yet. Create a classroom tribe on the server or use Live Classroom to host.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('in-room mute, lesson, listeners, and reactions', (tester) async {
    await _pump(
      tester,
      const LiveClassroomScreen(roomName: 'Yoruba Conversations'),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('live-classroom-lesson')), findsOneWidget);
    expect(
      find.text(
        'Practice everyday Yoruba greetings with proper tonal pronunciation',
      ),
      findsOneWidget,
    );
    expect(find.text('Host · Speaking'), findsOneWidget);
    expect(find.text('Listeners'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byKey(const ValueKey('listener-online-Fatima B.')), findsOneWidget);
    expect(find.byKey(const ValueKey('listener-online-Sipho M.')), findsNothing);
    expect(find.text('Lit'), findsOneWidget);
    expect(find.text('🎉'), findsOneWidget);
    expect(find.text('👏'), findsOneWidget);
    expect(find.text('Bawo ni'), findsOneWidget);
    expect(find.text('How are you'), findsOneWidget);
    expect(find.text('Mute'), findsOneWidget);
    expect(find.text('Raise'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('live-control-Mute')));
    await tester.pump();
    expect(find.text('Unmute'), findsOneWidget);
    expect(find.byIcon(Icons.mic_off_rounded), findsWidgets);

    await tester.ensureVisible(find.text('Chidi O.'));
    await tester.tap(find.text('Chidi O.'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('active-speaker-name'))).data,
      'Chidi O.',
    );
  });

  testWidgets('session list, offline check-in, and start agenda', (tester) async {
    String? startedAgenda;
    List<String>? languages;
    String? queuedType;
    Map<String, dynamic>? queuedPayload;
    var sessionLoads = 0;
    await _pump(
      tester,
      ClassroomSessionScreen(
        tribeId: 'tribe-9',
        tribeName: 'Saturday class',
        languageTag: 'yo',
        loaders: LiveClassroomLoaders(
          pendingOutboxCount: () async => 2,
          loadSessions: (_) async {
            sessionLoads += 1;
            return {
              'sessions': [
                {
                  'sessionId': 's1',
                  'status': 'active',
                  'agenda': 'Market greetings',
                  'meCheckedIn': false,
                  'startedAt': '2026-03-04T12:00:00Z',
                },
                {
                  'sessionId': 's0',
                  'status': 'ended',
                  'startedAt': '2026-03-01T12:00:00Z',
                },
              ],
            };
          },
          checkIn: (_, __, ___) async => throw Exception('offline'),
          enqueueCheckIn: ({required type, required payload}) async {
            queuedType = type;
            queuedPayload = payload;
          },
          startSession: (tribeId, {agenda, packLanguages}) async {
            expect(tribeId, 'tribe-9');
            startedAgenda = agenda;
            languages = packLanguages;
          },
          syncOutbox: () async => 2,
        ),
      ),
    );
    await _flush(tester);

    expect(find.text('Session: Saturday class'), findsOneWidget);
    expect(find.text('Active now'), findsOneWidget);
    expect(find.text('Market greetings'), findsOneWidget);
    expect(find.text('Check in'), findsOneWidget);
    expect(find.text('Join live class'), findsOneWidget);
    expect(find.text('2026-03-04'), findsOneWidget);
    expect(find.text('2026-03-01'), findsOneWidget);
    expect(find.text('ended'), findsOneWidget);
    expect(find.text('2 action(s) queued for sync (offline).'), findsOneWidget);

    await tester.ensureVisible(find.text('Check in'));
    await tester.tap(find.text('Check in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(sessionQueuedCheckInCopy), findsOneWidget);
    expect(queuedType, classroomAttendanceCheckInType);
    expect(queuedPayload?['tribeId'], 'tribe-9');
    expect(queuedPayload?['sessionId'], 's1');
    expect(queuedPayload?['checkedInAtClient'], isA<String>());
    expect(sessionLoads, greaterThan(1));

    await tester.tap(find.byTooltip('Start session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Start class session'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tone warm-up');
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump();
    await tester.pump();
    expect(startedAgenda, 'Tone warm-up');
    expect(languages, ['yo']);
  });

  testWidgets('checked-in session, empty session, sync, and retry', (tester) async {
    var pending = 1;
    var loads = 0;
    var checkIns = 0;
    await _pump(
      tester,
      LiveClassroomScreen(
        tribeId: 'tribe-3',
        tribeName: 'Evening',
        languageTag: 'ig',
        entry: LiveClassroomEntry.session,
        loaders: LiveClassroomLoaders(
          pendingOutboxCount: () async => pending,
          loadSessions: (_) async {
            loads += 1;
            if (loads == 1) {
              return {
                'sessions': [
                  {
                    'sessionId': 's2',
                    'status': 'active',
                    'meCheckedIn': true,
                  },
                ],
              };
            }
            return {'sessions': <Map<String, dynamic>>[]};
          },
          checkIn: (_, __, ___) async => checkIns += 1,
          syncOutbox: () async {
            pending = 0;
            return 1;
          },
        ),
      ),
    );
    await _flush(tester);

    final checked = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Checked in'),
    );
    expect(checked.onPressed, isNull);
    expect(checkIns, 0);

    await tester.tap(find.text('Sync now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Synced 1 queued actions.'), findsOneWidget);

    await _flush(tester);
    expect(find.text('No active session'), findsOneWidget);
    expect(find.textContaining('offline-ready'), findsOneWidget);
  });

  testWidgets('session load error can be retried', (tester) async {
    var loads = 0;
    await _pump(
      tester,
      LiveClassroomScreen(
        tribeId: 'tribe-4',
        tribeName: 'Morning',
        entry: LiveClassroomEntry.session,
        loaders: LiveClassroomLoaders(
          pendingOutboxCount: () async => 0,
          loadSessions: (_) async {
            loads += 1;
            if (loads == 1) throw Exception('down');
            return {'sessions': <Map<String, dynamic>>[]};
          },
        ),
      ),
    );
    await _flush(tester);
    expect(find.text('Unable to load sessions right now.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await _flush(tester);
    expect(find.text('No active session'), findsOneWidget);
    expect(loads, 2);
  });

  testWidgets('live phase shows the recording banner and consent ask', (
    tester,
  ) async {
    var joined = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ClassSessionLiveView(
          phase: ClassSessionLivePhase.lobby,
          recordingActive: false,
          isTeacher: false,
          tribeName: 'Saturday class',
          onJoin: () => joined = true,
          onLeave: () {},
          onStartRecording: null,
          declined: false,
        ),
      ),
    );
    expect(find.text('Lobby'), findsOneWidget);
    expect(
      find.text('Review consent, then connect to the live room.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Connect to live room'));
    expect(joined, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: ClassSessionLiveView(
          phase: ClassSessionLivePhase.recording,
          recordingActive: true,
          isTeacher: true,
          tribeName: 'Saturday class',
          onJoin: () {},
          onLeave: () {},
          onStartRecording: () {},
          declined: false,
          retentionDeleteAt: '2026-04-01',
        ),
      ),
    );
    expect(find.text(sessionRecordingIndicatorCopy), findsWidgets);
    expect(find.text('Start recording'), findsOneWidget);
    expect(find.text('Stored until 2026-04-01'), findsOneWidget);
    expect(
      find.text(
        'Stay connected with your class. Teachers can start recording once everyone consents.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ClassRecordingConsentDialog(),
      ),
    );
    expect(find.text(sessionConsentAskCopy), findsOneWidget);
    expect(find.text(ClassRecordingConsentDialog.body), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Agree'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ClassSessionLiveView(
          phase: ClassSessionLivePhase.declined,
          recordingActive: false,
          isTeacher: true,
          tribeName: 'Saturday class',
          onJoin: () {},
          onLeave: () {},
          onStartRecording: () {},
          declined: true,
        ),
      ),
    );
    expect(find.text('Unrecorded'), findsOneWidget);
    expect(find.text('Start recording'), findsNothing);
    expect(find.text('Connect to live room'), findsNothing);
    expect(
      find.text(
        'You joined without being recorded. Your mic and camera stay off for this recording.',
      ),
      findsOneWidget,
    );
  });
}

class _RecordingTribes extends TribesService {
  _RecordingTribes() : super(Dio());

  bool? includeClassrooms;

  @override
  Future<List<Map<String, dynamic>>> getAllTribes({
    String? languageTag,
    bool includeClassrooms = false,
  }) async {
    this.includeClassrooms = includeClassrooms;
    return const [];
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  RouteFactory? onGenerateRoute,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(390, 1400),
        builder: (_, __) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: onGenerateRoute,
          home: screen,
        ),
      ),
    ),
  );
}

Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
