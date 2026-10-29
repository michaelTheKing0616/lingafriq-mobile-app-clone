/// Study-reminder scheduling rules (P10-906): one nudge per local day, quiet hours, window.
class ReminderPolicy {
  static const int quietHourStart = 22;
  static const int quietHourEnd = 7;

  static const Set<int> milestoneDays = {7, 14, 30, 50, 100, 365};

  static final RegExp _lossAversion = RegExp(
    r"\b(at risk|don't break|do not break|you('ll| will) lose|losing your|before you lose|streak is at risk|keep it alive)\b",
    caseSensitive: false,
  );

  static const int minutesPerDay = 24 * 60;

  /// Whether [minuteOfDay] (0..1439) is inside the quiet window
  /// [startMinute, endMinute). Handles windows that cross midnight
  /// (22:00-07:00) as well as same-day ones; equal bounds mean no quiet time.
  static bool inQuietWindow(
    int minuteOfDay, {
    int startMinute = quietHourStart * 60,
    int endMinute = quietHourEnd * 60,
  }) {
    final m = minuteOfDay % minutesPerDay;
    if (startMinute == endMinute) return false;
    if (startMinute < endMinute) return m >= startMinute && m < endMinute;
    return m >= startMinute || m < endMinute;
  }

  /// Quiet check for a wall-clock time, at minute precision.
  static bool inQuietAt(DateTime t) => inQuietWindow(t.hour * 60 + t.minute);

  static bool inQuietHours(int hour) => inQuietWindow(hour * 60);

  /// Next slot to fire a daily reminder chosen for [reminderMinute], given the
  /// local time now ([nowMinute]). Returns the day offset (0 today, 1 tomorrow)
  /// and the minute of day. A slot that falls in quiet hours moves to the end
  /// of the quiet window, on the next day when the window crosses midnight.
  /// The decision depends on when the reminder fires, never on the current hour.
  static ({int dayOffset, int minuteOfDay}) nextReminderSlot({
    required int nowMinute,
    required int reminderMinute,
    int startMinute = quietHourStart * 60,
    int endMinute = quietHourEnd * 60,
  }) {
    var minute = reminderMinute % minutesPerDay;
    if (inQuietWindow(minute, startMinute: startMinute, endMinute: endMinute)) {
      // The first allowed moment is the next quiet-window end after now.
      minute = endMinute;
    }
    final day = minute > nowMinute ? 0 : 1;
    return (dayOffset: day, minuteOfDay: minute);
  }

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
    if (hasCustomWindow && !inReminderWindow(localHour, reminderHour)) {
      return false;
    }
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
      body =
          'A short lesson today is a gentle way to begin your practice rhythm.';
    }

    if (inQuietHours(localHour) && containsLossAversion('$title $body')) {
      body =
          'Whenever you are ready, a short lesson fits nicely into your day.';
    }

    return (title: title, body: body);
  }

  static ({String title, String body}) sanitizePushCopy({
    required String title,
    required String body,
    required int localHour,
  }) {
    if (!inQuietHours(localHour)) return (title: title, body: body);
    if (!containsLossAversion('$title $body')) {
      return (title: title, body: body);
    }
    return (
      title: 'LingAfriq',
      body: 'Whenever you are ready, a short lesson fits nicely into your day.',
    );
  }
}
