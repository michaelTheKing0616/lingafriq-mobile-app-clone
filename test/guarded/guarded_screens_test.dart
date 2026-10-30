import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/classroom/class_code_join_sheet.dart';
import 'package:lingafriq/screens/classroom/classroom_student_requests_screen.dart';
import 'package:lingafriq/screens/guardian/child_messages_screen.dart';
import 'package:lingafriq/screens/guardian/family_tools_section.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';

import '../compliance/golden_kit.dart';
import 'fake_guarded.dart';

const _threads = 'GET /api/v2/guardian/children/7/dm-threads';
const _requests = 'GET /api/v2/classroom/guarded/t1/pending-students';
const _join = 'POST /api/tribes/classrooms/join';

void main() {
  setUpAll(() => loadComplianceFonts('test/guarded/guarded_screens_test.dart'));
  final base = goldenVariants.first;

  group('guardian: who is messaging my child', () {
    testWidgets('shows peers, roles, counts and flags; never message text', (
      t,
    ) async {
      final f = FakeGuarded({
        _threads: const GuardedResponse(200, threadsJson),
      });
      await pumpVariant(
        t,
        base,
        GuardianChildMessagesScreen(childUserId: 7, service: f.service),
      );
      expect(find.text('Mrs Adebayo'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('14 messages'), findsOneWidget);
      expect(find.text('1 report'), findsOneWidget);
      expect(find.text('2 messages stopped by safety checks'), findsOneWidget);
      expect(
        find.text('1 photo or voice note waiting for a moderator'),
        findsOneWidget,
      );
      expect(find.textContaining('waiting for a moderator'), findsOneWidget);
      expect(find.text('Unknown user'), findsOneWidget);
      expect(find.text('Messages stopped'), findsOneWidget);
      expect(f.calls.single.path, '/api/v2/guardian/children/7/dm-threads');
    });

    testWidgets('stop asks first, then posts revoke-peer and flips to allow', (
      t,
    ) async {
      final f = FakeGuarded({
        _threads: const GuardedResponse(200, threadsJson),
        'POST /api/v2/guardian/children/7/revoke-peer': const GuardedResponse(
          200,
          {'ok': true},
        ),
      });
      await pumpVariant(
        t,
        base,
        GuardianChildMessagesScreen(childUserId: 7, service: f.service),
      );
      await t.tap(find.byKey(const ValueKey('gdm-stop-11')));
      await t.pumpAndSettle();
      expect(find.text('Stop messages from Mrs Adebayo?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(f.calls.length, 1);
      await t.tap(find.byKey(const ValueKey('gdm-stop-11')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('gdm-confirm-stop')));
      await t.pumpAndSettle();
      expect(f.calls.last.path, '/api/v2/guardian/children/7/revoke-peer');
      expect(f.calls.last.data, {'peer_user_id': 11});
      expect(find.byKey(const ValueKey('gdm-allow-11')), findsOneWidget);
    });

    testWidgets('allow again posts restore-peer without a dialog', (t) async {
      final f = FakeGuarded({
        _threads: const GuardedResponse(200, threadsJson),
        'POST /api/v2/guardian/children/7/restore-peer': const GuardedResponse(
          200,
          {'ok': true},
        ),
      });
      await pumpVariant(
        t,
        base,
        GuardianChildMessagesScreen(childUserId: 7, service: f.service),
      );
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('gdm-allow-13')),
        200,
      );
      await t.tap(find.byKey(const ValueKey('gdm-allow-13')));
      await t.pumpAndSettle();
      expect(f.calls.last.path, '/api/v2/guardian/children/7/restore-peer');
      expect(find.byKey(const ValueKey('gdm-stop-13')), findsOneWidget);
    });

    testWidgets('error offers retry; empty explains who can message', (
      t,
    ) async {
      final f = FakeGuarded({});
      await pumpVariant(
        t,
        base,
        GuardianChildMessagesScreen(childUserId: 7, service: f.service),
      );
      expect(
        find.text('We could not load messages. Try again.'),
        findsOneWidget,
      );
      f.routes[_threads] = const GuardedResponse(200, {
        'ok': true,
        'threads': [],
      });
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('No direct messages yet'), findsOneWidget);
    });

    testWidgets('every Stop button uses the same outlined style', (t) async {
      final f = FakeGuarded({
        _threads: const GuardedResponse(200, threadsJson),
      });
      await pumpVariant(
        t,
        base,
        GuardianChildMessagesScreen(childUserId: 7, service: f.service),
      );
      final stops = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('gdm-stop-'),
      );
      expect(stops, findsWidgets);
      for (final e in stops.evaluate()) {
        expect(e.widget, isA<OutlinedButton>());
      }
      expect(find.byType(FilledButton), findsNothing);
    });

    final stateCases = <String, GuardedResponse?>{
      'loading': null,
      'error': const GuardedResponse(500, {}),
      'empty': const GuardedResponse(200, {'ok': true, 'threads': []}),
    };
    for (final v in [goldenVariants.first, goldenVariants.last]) {
      stateCases.forEach((state, r) {
        testWidgets('golden $state ${v.name}', (t) async {
          final f = FakeGuarded({if (r != null) _threads: r});
          final service = r == null
              ? GuardedMessagingService(
                  request: (m, p, {data}) =>
                      Completer<GuardedResponse>().future,
                )
              : f.service;
          await pumpVariant(
            t,
            v,
            GuardianChildMessagesScreen(childUserId: 7, service: service),
            settle: r != null,
          );
          if (r == null) await t.pump(const Duration(milliseconds: 100));
          expectNoLayoutErrors(t);
          await expectLater(
            find.byType(GuardianChildMessagesScreen),
            matchesGoldenFile('goldens/child_messages_${state}_${v.name}.png'),
          );
        });
      });
    }

    for (final v in goldenVariants) {
      testWidgets('golden ${v.name}', (t) async {
        final f = FakeGuarded({
          _threads: const GuardedResponse(200, threadsJson),
        });
        await pumpVariant(
          t,
          v,
          GuardianChildMessagesScreen(childUserId: 7, service: f.service),
        );
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(GuardianChildMessagesScreen),
          matchesGoldenFile('goldens/child_messages_${v.name}.png'),
        );
      });
    }
  });

  group('class code sheet', () {
    Future<FakeGuarded> pumpSheet(
      WidgetTester t,
      GuardedResponse r, {
      GoldenVariant? v,
    }) async {
      final f = FakeGuarded({_join: r});
      await pumpVariant(
        t,
        v ?? base,
        Scaffold(body: _AsSheet(ClassCodeJoinSheet(service: f.service))),
      );
      return f;
    }

    testWidgets('has a drag handle and a close button that pops', (t) async {
      final f = FakeGuarded({});
      await pumpVariant(
        t,
        base,
        Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    ClassCodeJoinSheet.show(ctx, service: f.service),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('gcc-handle')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('gcc-close')));
      await t.pumpAndSettle();
      expect(find.byType(ClassCodeJoinSheet), findsNothing);
    });

    testWidgets('guardian link error offers Family hub', (t) async {
      final f = FakeGuarded({
        _join: const GuardedResponse(403, {'code': 'guardian_link_required'}),
      });
      final pushed = <String?>[];
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (s) {
            pushed.add(s.name);
            return MaterialPageRoute<void>(
              settings: s,
              builder: (_) => s.name == '/'
                  ? Scaffold(body: ClassCodeJoinSheet(service: f.service))
                  : const Scaffold(body: Text('hub')),
            );
          },
        ),
      );
      await t.enterText(find.byKey(const ValueKey('gcc-field')), 'ABC');
      await t.tap(find.byKey(const ValueKey('gcc-submit')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('gcc-family-hub')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('gcc-family-hub')));
      await t.pumpAndSettle();
      expect(pushed.last, '/family-hub');
      expect(find.text('hub'), findsOneWidget);
    });

    testWidgets('other errors do not show the Family hub button', (t) async {
      await pumpSheet(t, const GuardedResponse(404, {}));
      await t.enterText(find.byKey(const ValueKey('gcc-field')), 'ABC');
      await t.tap(find.byKey(const ValueKey('gcc-submit')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('gcc-family-hub')), findsNothing);
    });

    testWidgets('202 shows waiting for guardian', (t) async {
      final f = await pumpSheet(
        t,
        const GuardedResponse(202, {'status': 'pending'}),
      );
      await t.enterText(find.byKey(const ValueKey('gcc-field')), ' yor201 ');
      await t.tap(find.byKey(const ValueKey('gcc-submit')));
      await t.pumpAndSettle();
      expect(f.calls.single.data, {'code': 'yor201'});
      expect(find.byKey(const ValueKey('gcc-waiting')), findsOneWidget);
      expect(find.text('Waiting for your guardian'), findsOneWidget);
    });

    testWidgets('201 shows joined and calls onJoined', (t) async {
      var joined = 0;
      final f = FakeGuarded({_join: const GuardedResponse(201, {})});
      await pumpVariant(
        t,
        base,
        Scaffold(
          body: ClassCodeJoinSheet(
            service: f.service,
            onJoined: () => joined++,
          ),
        ),
      );
      await t.enterText(find.byKey(const ValueKey('gcc-field')), 'ABC');
      await t.tap(find.byKey(const ValueKey('gcc-submit')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('gcc-joined')), findsOneWidget);
      expect(joined, 1);
    });

    final cases = <String, (GuardedResponse, String)>{
      'link': (
        const GuardedResponse(403, {'code': 'guardian_link_required'}),
        'Ask a parent or guardian to link to your account in Family hub first.',
      ),
      'age': (
        const GuardedResponse(403, {'code': 'age_verification_required'}),
        'Confirm your age in settings before joining a class.',
      ),
      'notfound': (
        const GuardedResponse(404, {}),
        'No class has that code. Check it with your teacher.',
      ),
      'member': (
        const GuardedResponse(409, {}),
        'You are already in this class.',
      ),
      'error': (
        const GuardedResponse(0, {}),
        'Could not join right now. Try again.',
      ),
    };
    cases.forEach((name, c) {
      testWidgets('refusal $name shows clear copy', (t) async {
        await pumpSheet(t, c.$1);
        await t.enterText(find.byKey(const ValueKey('gcc-field')), 'ABC');
        await t.tap(find.byKey(const ValueKey('gcc-submit')));
        await t.pumpAndSettle();
        expect(find.text(c.$2), findsOneWidget);
      });
    });

    testWidgets('empty code does not call the server', (t) async {
      final f = await pumpSheet(t, const GuardedResponse(201, {}));
      await t.tap(find.byKey(const ValueKey('gcc-submit')));
      await t.pumpAndSettle();
      expect(f.calls, isEmpty);
      expect(find.text('Enter the code first.'), findsOneWidget);
    });

    for (final v in goldenVariants) {
      testWidgets('golden waiting ${v.name}', (t) async {
        await pumpSheet(t, const GuardedResponse(202, {}), v: v);
        await t.enterText(find.byKey(const ValueKey('gcc-field')), 'YOR201');
        await t.tap(find.byKey(const ValueKey('gcc-submit')));
        await t.pumpAndSettle();
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(ClassCodeJoinSheet),
          matchesGoldenFile('goldens/class_code_waiting_${v.name}.png'),
        );
      });
      testWidgets('golden link error ${v.name}', (t) async {
        await pumpSheet(
          t,
          const GuardedResponse(403, {'code': 'guardian_link_required'}),
          v: v,
        );
        await t.enterText(find.byKey(const ValueKey('gcc-field')), 'YOR201');
        await t.tap(find.byKey(const ValueKey('gcc-submit')));
        await t.pumpAndSettle();
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(ClassCodeJoinSheet),
          matchesGoldenFile('goldens/class_code_link_${v.name}.png'),
        );
      });
    }
  });

  group('teacher: student requests', () {
    testWidgets('lists waiting and school students; toggle posts approval', (
      t,
    ) async {
      final f = FakeGuarded({
        _requests: const GuardedResponse(200, requestsJson),
        'POST /api/v2/classroom/guarded/t1/students/31/approve-teacher-dm':
            const GuardedResponse(200, {'ok': true}),
        'POST /api/v2/classroom/guarded/t1/students/32/revoke-teacher-dm':
            const GuardedResponse(200, {'ok': true}),
      });
      await pumpVariant(
        t,
        base,
        ClassroomStudentRequestsScreen(tribeId: 't1', service: f.service),
      );
      expect(find.text('Amara'), findsOneWidget);
      expect(find.text('Waiting for a guardian'), findsOneWidget);
      expect(
        find.text('Locked until the school confirms consent'),
        findsOneWidget,
      );
      // Locked rows keep full-contrast text.
      final scheme = Theme.of(t.element(find.text('Amara'))).colorScheme;
      final lockedTitle = t.widget<Text>(
        find
            .descendant(
              of: find.byKey(const ValueKey('gtp-dm-33')),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(lockedTitle.style?.color, scheme.onSurface);
      SwitchListTile sw(int id) =>
          t.widget<SwitchListTile>(find.byKey(ValueKey('gtp-dm-$id')));
      expect(sw(31).value, isFalse);
      expect(sw(32).value, isTrue);
      expect(sw(33).onChanged, isNull);
      await t.tap(find.byKey(const ValueKey('gtp-dm-31')));
      await t.pumpAndSettle();
      expect(
        f.calls.last.path,
        '/api/v2/classroom/guarded/t1/students/31/approve-teacher-dm',
      );
      expect(sw(31).value, isTrue);
      await t.tap(find.byKey(const ValueKey('gtp-dm-32')));
      await t.pumpAndSettle();
      expect(
        f.calls.last.path,
        '/api/v2/classroom/guarded/t1/students/32/revoke-teacher-dm',
      );
      expect(sw(32).value, isFalse);
    });

    testWidgets('a failed toggle keeps the old value and says so', (t) async {
      final f = FakeGuarded({
        _requests: const GuardedResponse(200, requestsJson),
      });
      await pumpVariant(
        t,
        base,
        ClassroomStudentRequestsScreen(tribeId: 't1', service: f.service),
      );
      await t.tap(find.byKey(const ValueKey('gtp-dm-31')));
      await t.pumpAndSettle();
      expect(
        t.widget<SwitchListTile>(find.byKey(const ValueKey('gtp-dm-31'))).value,
        isFalse,
      );
      expect(find.text('That did not work. Try again.'), findsOneWidget);
    });

    testWidgets('403 says only the teacher can see requests', (t) async {
      final f = FakeGuarded({
        _requests: const GuardedResponse(403, {
          'code': 'not_classroom_teacher',
        }),
      });
      await pumpVariant(
        t,
        base,
        ClassroomStudentRequestsScreen(tribeId: 't1', service: f.service),
      );
      expect(
        find.text("Only this class's teacher can see requests."),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsNothing);
    });

    for (final v in [goldenVariants.first, goldenVariants.last]) {
      testWidgets('empty state golden ${v.name}', (t) async {
        final f = FakeGuarded({
          _requests: const GuardedResponse(200, {
            'ok': true,
            'waiting_for_guardian': [],
            'school_students': [],
          }),
        });
        await pumpVariant(
          t,
          v,
          ClassroomStudentRequestsScreen(
            tribeId: 't1',
            tribeName: 'Yoruba 201',
            service: f.service,
          ),
        );
        expect(find.byKey(const ValueKey('gtp-empty')), findsOneWidget);
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(ClassroomStudentRequestsScreen),
          matchesGoldenFile('goldens/student_requests_empty_${v.name}.png'),
        );
      });
    }

    testWidgets('long class name wraps instead of truncating', (t) async {
      final f = FakeGuarded({
        _requests: const GuardedResponse(200, requestsJson),
      });
      await pumpVariant(
        t,
        goldenVariants.last,
        ClassroomStudentRequestsScreen(
          tribeId: 't1',
          tribeName: 'Yoruba 201 for the Saturday morning group',
          service: f.service,
        ),
      );
      final title = find.text('Yoruba 201 for the Saturday morning group');
      expect(title, findsOneWidget);
      final para = t.renderObject<RenderParagraph>(title);
      expect(para.didExceedMaxLines, isFalse);
      expectNoLayoutErrors(t);
    });

    for (final v in goldenVariants) {
      testWidgets('golden ${v.name}', (t) async {
        final f = FakeGuarded({
          _requests: const GuardedResponse(200, requestsJson),
        });
        await pumpVariant(
          t,
          v,
          ClassroomStudentRequestsScreen(
            tribeId: 't1',
            tribeName: 'Yoruba 201',
            service: f.service,
          ),
        );
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(ClassroomStudentRequestsScreen),
          matchesGoldenFile('goldens/student_requests_${v.name}.png'),
        );
      });
    }
  });

  group('family hub entries', () {
    testWidgets('each entry opens its named route', (t) async {
      final pushed = <(String?, Object?)>[];
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (s) {
            pushed.add((s.name, s.arguments));
            return MaterialPageRoute<void>(
              settings: s,
              builder: (_) => s.name == '/'
                  ? const Scaffold(
                      body: SingleChildScrollView(
                        child: FamilyToolsSection(activeChildIds: [7, 9]),
                      ),
                    )
                  : const Scaffold(body: Text('dest')),
            );
          },
        ),
      );
      await t.pumpAndSettle();
      Future<void> open(String key) async {
        await t.tap(find.byKey(ValueKey(key)));
        await t.pumpAndSettle();
        Navigator.of(t.element(find.text('dest'))).pop();
        await t.pumpAndSettle();
      }

      await open('family-tools-messages-9');
      await open('family-tools-approvals');
      await open('family-tools-guide');
      await open('family-tools-circles');
      expect(pushed.skip(1).map((e) => e.$1).toList(), [
        '/guardian-child-messages',
        '/guardian-approvals',
        '/guardian-messaging-guide',
        '/village-circles',
      ]);
      expect(pushed[1].$2, {'childUserId': 9});
      expect(find.text('Who messages learner #7'), findsOneWidget);
    });
  });
}

/// Renders the sheet the way the modal does: bottom-aligned, sized to content.
class _AsSheet extends StatelessWidget {
  const _AsSheet(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: child,
    ),
  );
}
