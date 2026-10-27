/// Study-reminder scheduling rules (P10-906): one nudge per local day, quiet hours, window.
class ReminderPolicy {
  static const int quietHourStart = 22;
  static const int quietHourEnd = 7;

  static const Set<int> milestoneDays = {7, 14, 30, 50, 100, 365};

  static final RegExp _lossAversion = RegExp(
    r"\b(at risk|don't break|do not break|you('ll| will) lose|losing your|before you lose|streak is at risk|keep it alive)\b",
    caseSensitive: false,
  );

  static bool inQuietHours(int hour) => hour >= quietHourStart || hour < quietHourEnd;

  static bool inReminderWindow(int hour, int reminderHour) {
    final diff = (hour - reminderHour).abs();
    return diff <= 1 || (24 - diff) <= 1;
  }

  static bool containsLossAversion(String text) => _lossAversion.hasMatch(text);

  static bool mayScheduleLocalReminder({
    required int localHour,
    required int reminderHour,
    required bool remindersEnabled,
    required String lastSentLocalDate,
    required String todayLocalDate,
    bool hasCustomWindow = false,
  }) {
    if (!remindersEnabled) return false;
    if (lastSentLocalDate == todayLocalDate) return false;
    if (inQuietHours(localHour)) return false;
    if (hasCustomWindow && !inReminderWindow(localHour, reminderHour)) return false;
    if (!hasCustomWindow && !inReminderWindow(localHour, reminderHour)) {
      // Default: nudge near chosen time, still outside quiet hours.
      return false;
    }
    return true;
  }

  static ({String title, String body}) composeStudyReminder({
    required int streakDays,
    required int localHour,
  }) {
    final celebrate = milestoneDays.contains(streakDays);
    late String title;
    late String body;

    if (celebrate) {
      title = 'Milestone day';
      body =
          'You have practised $streakDays days in a row. Enjoy the moment, then keep going with a short lesson.';
    } else if (streakDays > 0) {
      title = 'Your practice rhythm';
      body =
          'You are on a $streakDays-day streak. A few minutes today keeps the momentum you have built.';
    } else {
      title = 'Ready when you are';
      body = 'A short lesson today is a gentle way to begin your practice rhythm.';
    }

    if (inQuietHours(localHour) && containsLossAversion('$title $body')) {
      body = 'Whenever you are ready, a short lesson fits nicely into your day.';
    }

    return (title: title, body: body);
  }

  static ({String title, String body}) sanitizePushCopy({
    required String title,
    required String body,
    required int localHour,
  }) {
    if (!inQuietHours(localHour)) return (title: title, body: body);
    if (!containsLossAversion('$title $body')) return (title: title, body: body);
    return (
      title: 'LingAfriq',
      body: 'Whenever you are ready, a short lesson fits nicely into your day.',
    );
  }
}
