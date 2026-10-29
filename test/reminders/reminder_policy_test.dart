import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/reminders/reminder_policy.dart';

void main() {
  group('ReminderPolicy', () {
    test('quiet hours default 22:00–07:00', () {
      expect(ReminderPolicy.inQuietHours(22), isTrue);
      expect(ReminderPolicy.inQuietHours(6), isTrue);
      expect(ReminderPolicy.inQuietHours(9), isFalse);
    });

    test('daily cap blocks second schedule same local date', () {
      expect(
        ReminderPolicy.mayScheduleLocalReminder(
          localHour: 9,
          reminderHour: 9,
          remindersEnabled: true,
          lastSentLocalDate: '2026-01-15',
          todayLocalDate: '2026-01-15',
        ),
        isFalse,
      );
    });

    test('milestone copy avoids loss-aversion', () {
      final copy = ReminderPolicy.composeStudyReminder(
        streakDays: 7,
        localHour: 9,
      );
      expect(
        ReminderPolicy.containsLossAversion('${copy.title} ${copy.body}'),
        isFalse,
      );
      expect(copy.title, contains('Milestone'));
    });

    test('sanitizes push copy during quiet hours', () {
      final sanitized = ReminderPolicy.sanitizePushCopy(
        title: 'Streak',
        body: "Don't break your streak!",
        localHour: 23,
      );
      expect(ReminderPolicy.containsLossAversion(sanitized.body), isFalse);
    });
  });

  group('quiet window across midnight (minute precision)', () {
    int hm(int h, int m) => h * 60 + m;

    test('22:00-07:00 boundaries', () {
      expect(ReminderPolicy.inQuietWindow(hm(21, 59)), isFalse);
      expect(ReminderPolicy.inQuietWindow(hm(22, 0)), isTrue);
      expect(ReminderPolicy.inQuietWindow(hm(23, 59)), isTrue);
      expect(ReminderPolicy.inQuietWindow(hm(0, 0)), isTrue);
      expect(ReminderPolicy.inQuietWindow(hm(6, 59)), isTrue);
      expect(ReminderPolicy.inQuietWindow(hm(7, 0)), isFalse);
    });

    test('same-day and empty windows', () {
      final s = hm(13, 30), e = hm(14, 15);
      expect(
        ReminderPolicy.inQuietWindow(hm(13, 29), startMinute: s, endMinute: e),
        isFalse,
      );
      expect(
        ReminderPolicy.inQuietWindow(hm(13, 30), startMinute: s, endMinute: e),
        isTrue,
      );
      expect(
        ReminderPolicy.inQuietWindow(hm(14, 15), startMinute: s, endMinute: e),
        isFalse,
      );
      expect(
        ReminderPolicy.inQuietWindow(hm(3, 0), startMinute: s, endMinute: s),
        isFalse,
      );
    });

    test('a non-hour window is honoured at the minute', () {
      final s = hm(22, 30), e = hm(6, 45);
      expect(
        ReminderPolicy.inQuietWindow(hm(22, 29), startMinute: s, endMinute: e),
        isFalse,
      );
      expect(
        ReminderPolicy.inQuietWindow(hm(6, 44), startMinute: s, endMinute: e),
        isTrue,
      );
      expect(
        ReminderPolicy.inQuietWindow(hm(6, 45), startMinute: s, endMinute: e),
        isFalse,
      );
    });

    test('inQuietAt uses minutes, not just the hour', () {
      expect(ReminderPolicy.inQuietAt(DateTime(2026, 10, 29, 6, 59)), isTrue);
      expect(ReminderPolicy.inQuietAt(DateTime(2026, 10, 29, 7, 1)), isFalse);
    });

    test('changing settings during quiet hours still schedules tomorrow', () {
      final s = ReminderPolicy.nextReminderSlot(
        nowMinute: hm(23, 10),
        reminderMinute: hm(19, 0),
      );
      expect(s.dayOffset, 1);
      expect(s.minuteOfDay, hm(19, 0));
    });

    test('later today stays today; already passed moves to tomorrow', () {
      expect(
        ReminderPolicy.nextReminderSlot(
          nowMinute: hm(9, 0),
          reminderMinute: hm(19, 0),
        ),
        (dayOffset: 0, minuteOfDay: hm(19, 0)),
      );
      expect(
        ReminderPolicy.nextReminderSlot(
          nowMinute: hm(19, 0),
          reminderMinute: hm(19, 0),
        ),
        (dayOffset: 1, minuteOfDay: hm(19, 0)),
      );
    });

    test(
      'early-morning slot moves to quiet end the same morning, not 1h steps',
      () {
        expect(
          ReminderPolicy.nextReminderSlot(
            nowMinute: hm(1, 0),
            reminderMinute: hm(6, 30),
          ),
          (dayOffset: 0, minuteOfDay: hm(7, 0)),
        );
      },
    );

    test('late-evening slot moves past midnight to next morning', () {
      expect(
        ReminderPolicy.nextReminderSlot(
          nowMinute: hm(20, 0),
          reminderMinute: hm(23, 15),
        ),
        (dayOffset: 1, minuteOfDay: hm(7, 0)),
      );
      expect(
        ReminderPolicy.nextReminderSlot(
          nowMinute: hm(23, 30),
          reminderMinute: hm(23, 15),
        ),
        (dayOffset: 2, minuteOfDay: hm(7, 0)),
      );
    });

    test('result is never inside the quiet window', () {
      for (var now = 0; now < 1440; now += 17) {
        for (var r = 0; r < 1440; r += 13) {
          final s = ReminderPolicy.nextReminderSlot(
            nowMinute: now,
            reminderMinute: r,
          );
          expect(ReminderPolicy.inQuietWindow(s.minuteOfDay), isFalse);
          expect(s.dayOffset * 1440 + s.minuteOfDay, greaterThan(now));
        }
      }
    });
  });
}
