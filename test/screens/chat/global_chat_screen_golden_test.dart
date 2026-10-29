import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/features/global_chat/global_chat_policy.dart';
import 'package:lingafriq/features/global_chat/global_chat_repository.dart';
import 'package:lingafriq/screens/chat/global_chat_screen_material3.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/contrast_kit.dart';
import '../../compliance/golden_kit.dart';
import '../../features/global_chat/fakes.dart';

List<ChatMessage> _thread() => [
  msg(
    '1',
    'u1',
    'Adaeze',
    'Ẹ káàárọ̀ everyone! Who is practising Yoruba greetings today?',
    handle: 'ada_ng',
    minsAgo: 50,
  ),
  msg('2', 'me', 'Tope', 'Me! Ẹ káàsán o', minsAgo: 42),
  msg('3', 'u2', 'Kwame', 'spam spam spam', flagged: true, minsAgo: 30),
  msg(
    '4',
    '0',
    'Polie',
    'Tip: “Ẹ káàárọ̀” is for the morning, “Ẹ káàsán” for the afternoon.',
    handle: 'polie_bot',
    minsAgo: 3,
  ),
];

List<Override> _o({
  FakeRepo? repo,
  FakeLive? live,
  GlobalChatAccess access = GlobalChatAccess.allowed,
  ChatMe? who = me,
}) => [
  globalChatAccessProvider.overrideWithValue(access),
  globalChatRepositoryProvider.overrideWithValue(
    repo ?? FakeRepo(server: {'general': _thread()}),
  ),
  globalChatLiveProvider.overrideWithValue(live ?? FakeLive()),
  globalChatMeProvider.overrideWithValue(who),
];

Future<void> _golden(WidgetTester t, String name) => expectLater(
  find.byType(GlobalChatScreenMaterial3),
  matchesGoldenFile('goldens/global_chat_$name.png'),
);

const _fr = GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr'));
const _tablet = GoldenVariant('tablet_820', Size(820, 1180));

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/chat/global_chat_screen_golden_test.dart',
    ),
  );
  final base = goldenVariants.first;
  final rtl = goldenVariants[1];

  for (final v in [...goldenVariants, _fr, _tablet]) {
    testWidgets('global chat golden ${v.name}', (t) async {
      await pumpVariant(
        t,
        v,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expectNoLayoutErrors(t);
      expect(find.byKey(const Key('gc-list')), findsOneWidget);
      await _golden(t, v.name);
    });
  }

  group('identity, layout and motion', () {
    double opacityOf(WidgetTester t, String id) => t
        .widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(ValueKey('gc-enter-$id')),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    Future<FakeLive> pumpLive(WidgetTester t, {required bool reduce}) async {
      final live = FakeLive();
      await pumpVariant(
        t,
        base,
        Builder(
          builder: (c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
            child: const GlobalChatScreenMaterial3(),
          ),
        ),
        overrides: _o(live: live),
      );
      return live;
    }

    testWidgets('existing messages do not animate; a new arrival fades in', (
      t,
    ) async {
      final live = await pumpLive(t, reduce: false);
      expect(opacityOf(t, '1'), 1);
      live.push('general', msg('9', 'u9', 'Bisi', 'Ẹ n lẹ́ o!'));
      await t.pump();
      await t.pump();
      expect(opacityOf(t, '9'), lessThan(0.05));
      await t.pump(const Duration(milliseconds: 90));
      expect(opacityOf(t, '9'), inExclusiveRange(0, 1));
      await t.pumpAndSettle();
      expect(opacityOf(t, '9'), 1);
    });

    testWidgets('reduce motion: a new arrival appears at once', (t) async {
      final live = await pumpLive(t, reduce: true);
      live.push('general', msg('9', 'u9', 'Bisi', 'Ẹ n lẹ́ o!'));
      await t.pump();
      await t.pump();
      expect(opacityOf(t, '9'), 1);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('channel hero shows identity, welcome and greeting', (t) async {
      await pumpVariant(
        t,
        goldenVariants.first,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      await t.scrollUntilVisible(
        find.byKey(const Key('gc-hero')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Welcome to #\u2068General\u2069'), findsOneWidget);
      expect(
        find.text('Say it like a local: \u2068Hello · Bonjour · مرحبا\u2069'),
        findsOneWidget,
      );
    });

    testWidgets('tablet: conversation and banners are capped and centred', (
      t,
    ) async {
      await pumpVariant(
        t,
        _tablet,
        const GlobalChatScreenMaterial3(),
        overrides: _o(
          repo: FakeRepo(cache: {'general': _thread()})..fetchFails = true,
        ),
      );
      final col = t.getRect(find.byKey(const Key('gc-column')));
      expect(col.width, kGlobalChatMaxWidth);
      expect(col.center.dx, closeTo(410, 0.5));
      final banner = t.getRect(find.byKey(const Key('gc-offline')));
      expect(banner.left, greaterThanOrEqualTo(col.left));
      expect(banner.right, lessThanOrEqualTo(col.right));
      final input = t.getRect(find.byKey(const Key('gc-input')));
      expect(input.left, greaterThanOrEqualTo(col.left));
    });

    testWidgets('composer has no shadow bar (flat with a hairline)', (t) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      final mats = find.ancestor(
        of: find.byKey(const Key('gc-input')),
        matching: find.byType(Material),
      );
      for (final m in t.widgetList<Material>(mats)) {
        expect(m.elevation, 0);
      }
    });

    testWidgets('large-text Arabic hint is short, not cut off', (t) async {
      await pumpVariant(
        t,
        goldenVariants[4],
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      final field = t.widget<TextField>(find.byKey(const Key('gc-input')));
      expect(field.decoration!.hintText, 'رسالة');
      final hint = find.descendant(
        of: find.byKey(const Key('gc-input')),
        matching: find.text('رسالة'),
      );
      final para = t.renderObject<RenderParagraph>(hint);
      expect(para.didExceedMaxLines, isFalse);
    });
  });

  group('states', () {
    testWidgets('loading', (t) async {
      final repo = FakeRepo()..fetchGate = Completer();
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
        settle: false,
      );
      await t.pump();
      await t.pump();
      expect(find.byKey(const Key('gc-loading')), findsOneWidget);
      await _golden(t, 'loading');
      repo.fetchGate!.complete(const []);
    });

    testWidgets('error with retry that recovers', (t) async {
      final repo = FakeRepo(server: {'general': _thread()})..fetchFails = true;
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      expect(find.byKey(const Key('gc-error')), findsOneWidget);
      await _golden(t, 'error');
      repo.fetchFails = false;
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gc-list')), findsOneWidget);
    });

    testWidgets('offline shows saved messages with a banner', (t) async {
      final repo = FakeRepo(cache: {'general': _thread()})..fetchFails = true;
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      expect(find.byKey(const Key('gc-offline')), findsOneWidget);
      await _golden(t, 'offline');
    });

    testWidgets('empty; Say hello sends a greeting', (t) async {
      final repo = FakeRepo();
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      expect(find.byKey(const Key('gc-empty')), findsOneWidget);
      await _golden(t, 'empty');
      await t.tap(find.text('Say hello'));
      await t.pumpAndSettle();
      expect(
        repo.posts.single.$2,
        'Hello everyone! Excited to learn together.',
      );
    });

    testWidgets('empty rtl', (t) async {
      await pumpVariant(
        t,
        rtl,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: FakeRepo()),
      );
      expectNoLayoutErrors(t);
      await _golden(t, 'empty_rtl');
    });

    for (final (access, name) in [
      (GlobalChatAccess.deniedTeen, 'locked_teen'),
      (GlobalChatAccess.deniedChild, 'locked_child'),
      (GlobalChatAccess.deniedUnknown, 'locked_unknown'),
    ]) {
      for (final v in [base, rtl, goldenVariants[4]]) {
        testWidgets('$name ${v.name}: no chat, no network', (t) async {
          final repo = FakeRepo(server: {'general': _thread()});
          final live = FakeLive();
          await pumpVariant(
            t,
            v,
            const GlobalChatScreenMaterial3(),
            overrides: _o(access: access, repo: repo, live: live),
          );
          expectNoLayoutErrors(t);
          expect(find.byKey(const Key('gc-locked')), findsOneWidget);
          expect(find.byKey(const Key('gc-input')), findsNothing);
          expect(repo.fetchCount, 0);
          expect(live.joined, isEmpty);
          expect(live.connectedAs, isNull);
          await _golden(t, '${name}_${v.name}');
        });
      }
    }

    testWidgets('checking access shows a spinner, not chat', (t) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(access: GlobalChatAccess.checking),
        settle: false,
      );
      await t.pump();
      expect(find.byKey(const Key('gc-checking')), findsOneWidget);
      expect(find.byKey(const Key('gc-input')), findsNothing);
    });
  });

  group('behaviour', () {
    testWidgets('own message has no actions; others and Polie differ', (
      t,
    ) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expect(find.byKey(const Key('gc-actions-1')), findsOneWidget);
      expect(find.byKey(const Key('gc-actions-2')), findsNothing);
      expect(find.byKey(const Key('gc-actions-4')), findsNothing);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('flagged message is hidden until revealed', (t) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expect(find.text('spam spam spam'), findsNothing);
      expect(find.byKey(const Key('gc-flagged')), findsOneWidget);
      await t.tap(find.text('Show'));
      await t.pump();
      expect(find.text('spam spam spam'), findsOneWidget);
    });

    testWidgets('send: input clears and message posts', (t) async {
      final repo = FakeRepo(server: {'general': _thread()});
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      await t.enterText(find.byKey(const Key('gc-input')), 'Ẹ ṣé o!');
      await t.tap(find.byKey(const Key('gc-send')));
      await t.pumpAndSettle();
      expect(repo.posts.single, ('general', 'Ẹ ṣé o!'));
      expect(find.text('Ẹ ṣé o!'), findsOneWidget);
      final field = t.widget<TextField>(find.byKey(const Key('gc-input')));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('send failure restores text and offers Retry', (t) async {
      final repo = FakeRepo(server: {'general': _thread()})..postFails = true;
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      await t.enterText(find.byKey(const Key('gc-input')), 'hello');
      await t.tap(find.byKey(const Key('gc-send')));
      await t.pumpAndSettle();
      expect(
        find.text('Message not sent. Check your connection.'),
        findsOneWidget,
      );
      final field = t.widget<TextField>(find.byKey(const Key('gc-input')));
      expect(field.controller!.text, 'hello');
      repo.postFails = false;
      await t.tap(find.text('Retry').last);
      await t.pumpAndSettle();
      expect(repo.posts, hasLength(2));
    });

    testWidgets('signed out: nothing posted, explained', (t) async {
      final repo = FakeRepo(server: {'general': _thread()});
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo, who: null),
      );
      await t.enterText(find.byKey(const Key('gc-input')), 'hi');
      await t.tap(find.byKey(const Key('gc-send')));
      await t.pumpAndSettle();
      expect(find.text('Sign in to send messages.'), findsOneWidget);
      expect(repo.posts, isEmpty);
    });

    testWidgets('mute hides the sender and shows a manage banner', (t) async {
      final repo = FakeRepo(server: {'general': _thread()});
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      await t.tap(find.byKey(const Key('gc-actions-1')));
      await t.pumpAndSettle();
      // Sheets live on the navigator overlay, so capture the whole app.
      await expectLater(
        find.byType(Navigator).first,
        matchesGoldenFile('goldens/global_chat_actions_sheet.png'),
      );
      await t.tap(find.byKey(const Key('gc-act-mute')));
      await t.pumpAndSettle();
      expect(repo.mutedStore, {'u1'});
      expect(find.textContaining('Who is practising'), findsNothing);
      expect(
        find.text('1 message hidden from muted or blocked people'),
        findsOneWidget,
      );
      await t.tap(find.text('Manage'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gc-unmute-u1')));
      await t.pumpAndSettle();
      expect(repo.mutedStore, isEmpty);
    });

    testWidgets('report: reason goes to the server, reference shown', (
      t,
    ) async {
      final repo = FakeRepo(server: {'general': _thread()});
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      await t.tap(find.byKey(const Key('gc-actions-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gc-act-report')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gc-reason-harassment')));
      await t.pumpAndSettle();
      expect(repo.reports.single, ('1', 'harassment'));
      expect(find.textContaining('R-42'), findsOneWidget);
    });

    testWidgets('block needs confirmation, then hides the sender', (t) async {
      final repo = FakeRepo(server: {'general': _thread()});
      final live = FakeLive();
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo, live: live),
      );
      await t.tap(find.byKey(const Key('gc-actions-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gc-act-block')));
      await t.pumpAndSettle();
      expect(repo.blockedIds, isEmpty);
      await t.tap(find.byKey(const Key('gc-block-confirm')));
      await t.pumpAndSettle();
      expect(repo.blockedIds, ['u1']);
      expect(live.marked, ['u1']);
      expect(find.textContaining('Who is practising'), findsNothing);
    });

    testWidgets('channel picker switches channel and remembers it', (t) async {
      final repo = FakeRepo(
        server: {
          'general': _thread(),
          'swahili': [msg('s', 'u9', 'Juma', 'Habari!')],
        },
      );
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(repo: repo),
      );
      await t.tap(find.byKey(const Key('gc-channel')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gc-ch-swahili')));
      await t.pumpAndSettle();
      expect(find.text('Swahili'), findsOneWidget);
      expect(find.text('Habari!'), findsOneWidget);
      expect(repo.last, 'swahili');
    });

    testWidgets('Arabic copy, no hard-coded English chrome', (t) async {
      await pumpVariant(
        t,
        rtl,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expect(find.text('الدردشة العامة'), findsOneWidget);
      expect(find.text('عام'), findsOneWidget);
      for (final en in [
        'Global chat',
        'General',
        'You',
        'Send',
        'Hidden by moderation',
      ]) {
        expect(find.text(en), findsNothing, reason: en);
      }
    });

    testWidgets('French copy, no hard-coded English chrome', (t) async {
      await pumpVariant(
        t,
        _fr,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expect(find.text('Chat mondial'), findsOneWidget);
      for (final en in [
        'Global chat',
        'General',
        'You',
        'Hidden by moderation',
      ]) {
        expect(find.text(en), findsNothing, reason: en);
      }
    });

    testWidgets('header is navy with a back arrow', (t) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      final bar = t.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, const Color(0xFF2E3A87));
      expect(find.byKey(const Key('gc-back')), findsOneWidget);
    });

    testWidgets('text contrast is at least 4.5:1', (t) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expect(
        lowContrastTexts(t, find.byType(GlobalChatScreenMaterial3)),
        isEmpty,
      );
    });

    testWidgets('no hearts and no paywall on chat', (t) async {
      await pumpVariant(
        t,
        base,
        const GlobalChatScreenMaterial3(),
        overrides: _o(),
      );
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(
        find.textContaining(
          RegExp('premium|subscribe|upgrade', caseSensitive: false),
        ),
        findsNothing,
      );
    });
  });
}
