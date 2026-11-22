import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/reminder_service.dart';

void main() {
  test('shipped reminder copy stays plain', () {
    const String copy = '$kInactivityReminderTitle $kInactivityReminderBody';
    expect(copy.contains('\u2014'), isFalse);
    expect(copy.toLowerCase().contains('world-class'), isFalse);
    expect(copy.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(copy), isFalse);
    expect(
      RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(copy),
      isFalse,
    );
    expect(copy.toLowerCase().contains('confidence'), isFalse);
    expect(kInactivitySessionMinutes, 2);
  });

  group('P3-050 AC4 inactivity reminder', () {
    test(
      'one episode with no sender records one pending 2-minute reminder',
      () async {
        final ReminderService service = ReminderService();
        final InactivityReminder? reminder = await service.considerInactivity(
          inactive: true,
          episodeId: 'episode-1',
        );
        expect(reminder, isNotNull);
        expect(reminder!.episodeId, 'episode-1');
        expect(reminder.sessionMinutes, 2);
        expect(reminder.opensSessionOf(2), isTrue);
        expect(reminder.title, kInactivityReminderTitle);
        expect(reminder.body, kInactivityReminderBody);
        expect(reminder.delivered, isFalse);
        expect(reminder.pending, isTrue);
        expect(service.reminders, hasLength(1));
        expect(service.reminders.single.pending, isTrue);
      },
    );

    test('a second run in the same episode sends nothing', () async {
      final ReminderService service = ReminderService();
      final InactivityReminder? first = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      final InactivityReminder? second = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      final InactivityReminder? trimmed = await service.considerInactivity(
        inactive: true,
        episodeId: ' episode-1 ',
      );
      expect(second, isNull);
      expect(trimmed, isNull);
      expect(service.reminders, hasLength(1));
      expect(service.reminders.single.episodeId, first!.episodeId);
      expect(service.reminders.single.delivered, isFalse);
    });

    test('a new episode may record one more', () async {
      final ReminderService service = ReminderService();
      await service.considerInactivity(inactive: true, episodeId: 'episode-1');
      final InactivityReminder? next = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-2',
      );
      expect(next, isNotNull);
      expect(next!.episodeId, 'episode-2');
      expect(next.opensSessionOf(2), isTrue);
      expect(next.pending, isTrue);
      expect(service.reminders, hasLength(2));
      expect(
        service.reminders.map((InactivityReminder item) => item.episodeId),
        <String>['episode-1', 'episode-2'],
      );
    });

    test('an active learner and a blank episode record nothing', () async {
      final ReminderService service = ReminderService();
      expect(
        await service.considerInactivity(
          inactive: false,
          episodeId: 'episode-1',
        ),
        isNull,
      );
      expect(
        await service.considerInactivity(inactive: true, episodeId: '   '),
        isNull,
      );
      expect(service.reminders, isEmpty);
    });

    test('a sender that accepts is the only delivered reminder', () async {
      final List<InactivityReminderRequest> sent =
          <InactivityReminderRequest>[];
      final ReminderService service = ReminderService(
        sender: (InactivityReminderRequest request) async {
          sent.add(request);
          return true;
        },
      );
      final InactivityReminder? reminder = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      await service.considerInactivity(inactive: true, episodeId: 'episode-1');
      expect(sent, hasLength(1));
      expect(sent.single.episodeId, 'episode-1');
      expect(sent.single.sessionMinutes, 2);
      expect(sent.single.opensSessionOf(2), isTrue);
      expect(sent.single.title, kInactivityReminderTitle);
      expect(reminder!.delivered, isTrue);
      expect(reminder.pending, isFalse);
      expect(reminder.opensSessionOf(2), isTrue);
    });

    test('a sender that declines leaves one pending reminder', () async {
      var calls = 0;
      final ReminderService service = ReminderService(
        sender: (InactivityReminderRequest request) async {
          calls += 1;
          return false;
        },
      );
      final InactivityReminder? reminder = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      final InactivityReminder? again = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      expect(calls, 1);
      expect(again, isNull);
      expect(reminder!.delivered, isFalse);
      expect(reminder.pending, isTrue);
      expect(reminder.opensSessionOf(2), isTrue);
      expect(service.reminders, hasLength(1));
    });

    test('a sender that throws records one pending reminder', () async {
      var calls = 0;
      final ReminderService service = ReminderService(
        sender: (InactivityReminderRequest request) async {
          calls += 1;
          throw StateError('channel unavailable');
        },
      );
      final InactivityReminder? reminder = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      await service.considerInactivity(inactive: true, episodeId: 'episode-1');
      expect(calls, 1);
      expect(reminder!.delivered, isFalse);
      expect(reminder.pending, isTrue);
      expect(service.reminders, hasLength(1));
    });

    test('each episode is delivered or pending on its own', () async {
      var calls = 0;
      final ReminderService service = ReminderService(
        sender: (InactivityReminderRequest request) async {
          calls += 1;
          return request.episodeId == 'episode-1';
        },
      );
      final InactivityReminder? first = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-1',
      );
      final InactivityReminder? second = await service.considerInactivity(
        inactive: true,
        episodeId: 'episode-2',
      );
      expect(calls, 2);
      expect(first!.delivered, isTrue);
      expect(first.pending, isFalse);
      expect(second!.delivered, isFalse);
      expect(second.pending, isTrue);
      expect(first.opensSessionOf(2), isTrue);
      expect(second.opensSessionOf(2), isTrue);
      expect(service.reminders, hasLength(2));
    });
  });
}
