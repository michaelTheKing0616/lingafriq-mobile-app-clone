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
      final copy = ReminderPolicy.composeStudyReminder(streakDays: 7, localHour: 9);
      expect(ReminderPolicy.containsLossAversion('${copy.title} ${copy.body}'), isFalse);
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
}
