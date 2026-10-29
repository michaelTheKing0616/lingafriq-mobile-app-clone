import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/global_chat/global_chat_controller.dart';
import 'package:lingafriq/features/global_chat/global_chat_repository.dart';

import 'fakes.dart';

Future<(ProviderContainer, FakeRepo, FakeLive)> _start({
  FakeRepo? repo,
  FakeLive? live,
  ChatMe? who = me,
}) async {
  final r = repo ?? FakeRepo();
  final l = live ?? FakeLive();
  final c = ProviderContainer(
    overrides: [
      globalChatRepositoryProvider.overrideWithValue(r),
      globalChatLiveProvider.overrideWithValue(l),
      globalChatMeProvider.overrideWithValue(who),
    ],
  );
  addTearDown(c.dispose);
  c.listen(globalChatControllerProvider, (_, _) {});
  await _idle();
  return (c, r, l);
}

Future<void> _idle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

GlobalChatState _s(ProviderContainer c) => c.read(globalChatControllerProvider);
GlobalChatController _n(ProviderContainer c) =>
    c.read(globalChatControllerProvider.notifier);

void main() {
  test('restores the last channel, connects, joins and loads it', () async {
    final (c, _, live) = await _start(
      repo: FakeRepo(
        last: 'yoruba',
        server: {
          'yoruba': [msg('1', 'u1', 'Ada', 'Ẹ káàárọ̀')],
        },
      ),
    );
    expect(_s(c).channel, 'yoruba');
    expect(_s(c).load, ChatLoad.ready);
    expect(_s(c).messages.single.text, 'Ẹ káàárọ̀');
    expect(live.connectedAs?.id, 'me');
    expect(live.joined, ['yoruba']);
  });

  test('ignores an unknown saved channel', () async {
    final (c, _, _) = await _start(repo: FakeRepo(last: 'hacked'));
    expect(_s(c).channel, 'general');
  });

  test('network failure shows saved messages, flagged as cache', () async {
    final repo = FakeRepo(
      cache: {
        'general': [msg('c1', 'u1', 'Ada', 'saved')],
      },
    )..fetchFails = true;
    final (c, _, _) = await _start(repo: repo);
    expect(_s(c).load, ChatLoad.ready);
    expect(_s(c).fromCache, isTrue);
    expect(_s(c).messages.single.text, 'saved');
  });

  test('network failure with no cache is an error; retry recovers', () async {
    final repo = FakeRepo(
      server: {
        'general': [msg('1', 'u1', 'Ada', 'hi')],
      },
    )..fetchFails = true;
    final (c, _, _) = await _start(repo: repo);
    expect(_s(c).load, ChatLoad.error);
    repo.fetchFails = false;
    await _n(c).refresh();
    expect(_s(c).load, ChatLoad.ready);
    expect(_s(c).fromCache, isFalse);
  });

  test('send: optimistic pending, then sent, cached, socket + REST', () async {
    final (c, repo, live) = await _start();
    repo.postGate = Completer<void>();
    final f = _n(c).send('  Hello  ');
    await _idle();
    expect(_s(c).sending, isTrue);
    expect(_s(c).messages.single.sendState, ChatSendState.pending);
    expect(_s(c).messages.single.text, 'Hello');
    repo.postGate!.complete();
    expect(await f, SendResult.sent);
    expect(_s(c).messages.single.sendState, ChatSendState.sent);
    expect(_s(c).sending, isFalse);
    expect(repo.posts, [('general', 'Hello')]);
    expect(live.sent, [('general', 'Hello')]);
    expect(repo.cacheStore['general']!.single.text, 'Hello');
  });

  test('send failure removes the optimistic message', () async {
    final (c, repo, _) = await _start();
    repo.postFails = true;
    expect(await _n(c).send('Hello'), SendResult.failed);
    expect(_s(c).messages, isEmpty);
    expect(_s(c).sending, isFalse);
  });

  test('blank text and signed-out are rejected without network', () async {
    final (c, repo, _) = await _start();
    expect(await _n(c).send('   '), SendResult.empty);
    final (c2, repo2, _) = await _start(who: null);
    expect(await _n(c2).send('hi'), SendResult.signedOut);
    expect(repo.posts, isEmpty);
    expect(repo2.posts, isEmpty);
  });

  test('Polie replies are appended; rate limit is reported', () async {
    final live = FakeLive()
      ..polie = PolieOutcome(
        local: [msg('p1', '0', 'Polie', 'Bawo!', handle: 'polie_bot')],
      );
    final (c, _, _) = await _start(live: live);
    expect(await _n(c).send('@Polie how do I greet?'), SendResult.sent);
    expect(_s(c).messages.last.isPolie, isTrue);

    live.polie = const PolieOutcome(rateLimited: true);
    expect(await _n(c).send('@polie again'), SendResult.polieBusy);
  });

  test('socket echo replaces the pending copy; duplicates ignored', () async {
    final (c, repo, live) = await _start();
    repo.postGate = Completer<void>();
    unawaited(_n(c).send('Hello'));
    await _idle();
    final echo = ChatMessage(
      id: 'srv1',
      senderId: 'me',
      senderName: 'Tope',
      text: 'Hello',
      createdAt: DateTime.now(),
    );
    live.push('general', echo);
    live.push('general', echo);
    live.push('general', msg('x', 'u2', 'Bayo', 'new'));
    await _idle();
    expect(_s(c).messages.map((m) => m.id), ['srv1', 'x']);
    repo.postGate!.complete();
  });

  test('mute hides a sender, persists, and unmute restores', () async {
    final (c, repo, _) = await _start(
      repo: FakeRepo(
        server: {
          'general': [msg('1', 'u1', 'Ada', 'a'), msg('2', 'u2', 'Bayo', 'b')],
        },
      ),
    );
    await _n(c).mute('u1');
    expect(_s(c).visible.map((m) => m.id), ['2']);
    expect(_s(c).hiddenCount, 1);
    expect(repo.mutedStore, {'u1'});
    await _n(c).unmute('u1');
    expect(_s(c).visible, hasLength(2));
    expect(repo.mutedStore, isEmpty);
  });

  test('mutes survive a restart', () async {
    final (c, _, _) = await _start(
      repo: FakeRepo(
        muted: {'u1'},
        server: {
          'general': [msg('1', 'u1', 'Ada', 'a')],
        },
      ),
    );
    expect(_s(c).visible, isEmpty);
  });

  test('block goes to server and socket and hides the sender', () async {
    final (c, repo, live) = await _start(
      repo: FakeRepo(
        server: {
          'general': [msg('1', 'u1', 'Ada', 'a')],
        },
      ),
    );
    await _n(c).block('u1');
    expect(repo.blockedIds, ['u1']);
    expect(live.marked, ['u1']);
    expect(_s(c).visible, isEmpty);
    await _n(c).unblock('u1');
    expect(repo.unblockedIds, ['u1']);
    expect(live.unmarked, ['u1']);
    expect(_s(c).visible, hasLength(1));
  });

  test('report returns the server reference', () async {
    final (c, repo, _) = await _start();
    expect(await _n(c).report('m1', 'spam'), 'R-42');
    expect(repo.reports, [('m1', 'spam')]);
  });

  test('switching channel leaves, saves, joins and reloads', () async {
    final (c, repo, live) = await _start(
      repo: FakeRepo(
        server: {
          'hausa': [msg('h', 'u1', 'Musa', 'Sannu')],
        },
      ),
    );
    await _n(c).selectChannel('hausa');
    expect(live.left, ['general']);
    expect(live.joined, ['general', 'hausa']);
    expect(repo.last, 'hausa');
    expect(_s(c).messages.single.text, 'Sannu');
  });

  test('a slow response for an old channel is discarded', () async {
    final repo = FakeRepo(
      server: {
        'igbo': [msg('i', 'u1', 'Ngozi', 'Ndewo')],
      },
    );
    final (c, _, _) = await _start(repo: repo);
    repo.fetchGate = Completer();
    final stale = repo.fetchGate!;
    unawaited(_n(c).refresh());
    repo.fetchGate = null;
    await _n(c).selectChannel('igbo');
    stale.complete([msg('g', 'u2', 'Old', 'general msg')]);
    await _idle();
    expect(_s(c).channel, 'igbo');
    expect(_s(c).messages.single.text, 'Ndewo');
  });

  test('disposing leaves the joined room', () async {
    final (c, _, live) = await _start();
    c.dispose();
    expect(live.left, contains('general'));
  });

  test('parses REST payload shapes', () {
    final m = ChatMessage.fromJson({
      '_id': 'a',
      'message': 'hi',
      'sender_id': {
        'id': 7,
        'username': 'Ada',
        'global_id': 'ada',
        'avatar': 'https://x/a.png',
      },
      'createdAt': '2026-10-29T10:00:00Z',
      'flagged_toxic': true,
    })!;
    expect(
      (m.id, m.senderId, m.senderName, m.handle, m.avatarUrl, m.flagged),
      ('a', '7', 'Ada', 'ada', 'https://x/a.png', true),
    );
    expect(ChatMessage.fromJson({'message': '  '}), isNull);
    final round = ChatMessage.fromJson(m.toJson())!;
    expect((round.id, round.text, round.handle), ('a', 'hi', 'ada'));
  });
}
