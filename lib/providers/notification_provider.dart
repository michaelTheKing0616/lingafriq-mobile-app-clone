import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/learning/reminders/reminder_policy.dart';
import 'package:lingafriq/services/reminder_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'gamification_provider.dart';
import '../utils/structured_logger.dart';

/// Time class for notification scheduling
class Time {
  final int hour;
  final int minute;
  final int second;

  const Time(this.hour, this.minute, [this.second = 0]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Time &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute &&
          second == other.second;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode ^ second.hashCode;
}

const int _studyReminderNotificationId = 0;

class NotificationNotifier extends Notifier<NotificationState> {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  NotificationState build() {
    _initializeNotifications();
    return NotificationState(
      studyRemindersEnabled: true,
      streakRemindersEnabled: true,
      dailyGoalRemindersEnabled: true,
      achievementAlertsEnabled: true,
      reminderTime: const Time(9, 0, 0),
      timezone: tz.local.name,
      hasCustomWindow: false,
    );
  }

  bool get _anyReminderChannelEnabled =>
      state.studyRemindersEnabled &&
      (state.streakRemindersEnabled || state.dailyGoalRemindersEnabled);

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHour = prefs.getInt('notif_reminder_hour');
      final savedMinute = prefs.getInt('notif_reminder_minute');
      final studyEnabled = prefs.getBool('notif_study_enabled');
      final streakEnabled = prefs.getBool('notif_streak_enabled');
      final goalEnabled = prefs.getBool('notif_goal_enabled');
      final tzName = prefs.getString('notif_timezone');
      final customWindow = prefs.getBool('notif_custom_window');

      if (savedHour != null && savedMinute != null) {
        state = state.copyWith(
          reminderTime: Time(savedHour, savedMinute),
          studyRemindersEnabled: studyEnabled ?? true,
          streakRemindersEnabled: streakEnabled ?? true,
          dailyGoalRemindersEnabled: goalEnabled ?? true,
          timezone: tzName ?? tz.local.name,
          hasCustomWindow: customWindow ?? false,
        );
      }

      await _syncFromServer();
      await _rescheduleStudyReminder();
    } catch (e) {
      logger.warn('Failed to load notification preferences', tag: 'notifications', error: e);
    }
  }

  Future<void> _syncFromServer() async {
    try {
      final remote = await ReminderSettingsService.fetchRemote();
      if (remote == null) return;
      final hour = (remote['reminderTime'] as Map?)?['hour'] as int? ?? state.reminderTime.hour;
      final minute = (remote['reminderTime'] as Map?)?['minute'] as int? ?? state.reminderTime.minute;
      final streak = remote['streakRemindersEnabled'] as bool? ?? state.streakRemindersEnabled;
      final daily = remote['dailyGoalRemindersEnabled'] as bool? ?? state.dailyGoalRemindersEnabled;
      final achievements = remote['achievementAlertsEnabled'] as bool? ?? state.achievementAlertsEnabled;
      final timezone = remote['timezone'] as String? ?? state.timezone;
      final studyOn = streak || daily;

      state = state.copyWith(
        studyRemindersEnabled: studyOn,
        streakRemindersEnabled: streak,
        dailyGoalRemindersEnabled: daily,
        achievementAlertsEnabled: achievements,
        reminderTime: Time(hour, minute),
        timezone: timezone,
        hasCustomWindow: timezone.isNotEmpty,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_reminder_hour', hour);
      await prefs.setInt('notif_reminder_minute', minute);
      await prefs.setBool('notif_study_enabled', studyOn);
      await prefs.setBool('notif_streak_enabled', streak);
      await prefs.setBool('notif_goal_enabled', daily);
      await prefs.setString('notif_timezone', timezone);
      await prefs.setBool('notif_custom_window', timezone.isNotEmpty);
    } catch (e) {
      logger.warn('Failed to sync reminder settings', tag: 'notifications', error: e);
    }
  }

  Future<void> _persistAndPush() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_reminder_hour', state.reminderTime.hour);
    await prefs.setInt('notif_reminder_minute', state.reminderTime.minute);
    await prefs.setBool('notif_study_enabled', state.studyRemindersEnabled);
    await prefs.setBool('notif_streak_enabled', state.streakRemindersEnabled);
    await prefs.setBool('notif_goal_enabled', state.dailyGoalRemindersEnabled);
    await prefs.setString('notif_timezone', state.timezone);
    await prefs.setBool('notif_custom_window', state.hasCustomWindow);

    await ReminderSettingsService.pushRemote({
      'streakRemindersEnabled': state.studyRemindersEnabled && state.streakRemindersEnabled,
      'dailyGoalRemindersEnabled': state.studyRemindersEnabled && state.dailyGoalRemindersEnabled,
      'achievementAlertsEnabled': state.achievementAlertsEnabled,
      'reminderTime': {
        'hour': state.reminderTime.hour,
        'minute': state.reminderTime.minute,
      },
      'timezone': state.timezone,
    });
  }

  void _onNotificationTapped(NotificationResponse response) {}

  int _localHourNow() {
    try {
      final location = tz.getLocation(state.timezone);
      return tz.TZDateTime.now(location).hour;
    } catch (_) {
      return DateTime.now().hour;
    }
  }

  Future<void> _rescheduleStudyReminder() async {
    await _notifications.cancel(_studyReminderNotificationId);
    await _notifications.cancel(1);

    if (!_anyReminderChannelEnabled) return;

    // Quiet hours are judged at the time the reminder fires (minute precision,
    // across midnight), not at the moment settings change: changing the time
    // at 23:00 must still schedule tomorrow's reminder.
    final time = state.reminderTime;
    tz.Location location;
    try {
      location = tz.getLocation(state.timezone);
    } catch (_) {
      location = tz.local;
    }
    final fireAt = _nextInstanceOfTime(time, location);
    final streak = _getCurrentStreak();
    final copy = ReminderPolicy.composeStudyReminder(streakDays: streak, localHour: fireAt.hour);

    await _notifications.zonedSchedule(
      _studyReminderNotificationId,
      copy.title,
      copy.body,
      fireAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminder',
          'Study Reminders',
          channelDescription: 'At most one gentle nudge per day to practise',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showAchievementAlert(String title, String body) async {
    final sanitized = ReminderPolicy.sanitizePushCopy(
      title: title,
      body: body,
      localHour: _localHourNow(),
    );
    await _notifications.show(
      2,
      sanitized.title,
      sanitized.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievement_alert',
          'Achievement Alerts',
          channelDescription: 'Notifications for unlocked achievements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(Time time, tz.Location location) {
    final now = tz.TZDateTime.now(location);
    final slot = ReminderPolicy.nextReminderSlot(
      nowMinute: now.hour * 60 + now.minute,
      reminderMinute: time.hour * 60 + time.minute,
    );
    // Calendar-day arithmetic so DST changes do not shift the wall-clock time.
    return tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day + slot.dayOffset,
      slot.minuteOfDay ~/ 60,
      slot.minuteOfDay % 60,
    );
  }

  int _getCurrentStreak() {
    try {
      final gamification = ref.read(gamificationProvider.notifier).gamification;
      return gamification.dailyStreak;
    } catch (e) {
      return 0;
    }
  }

  Future<void> updateReminderTime(Time time) async {
    state = state.copyWith(reminderTime: time, hasCustomWindow: true);
    await _persistAndPush();
    await _rescheduleStudyReminder();
  }

  Future<void> updateTimezone(String timezone) async {
    state = state.copyWith(timezone: timezone, hasCustomWindow: true);
    await _persistAndPush();
    await _rescheduleStudyReminder();
  }

  Future<void> setStudyRemindersEnabled(bool enabled) async {
    state = state.copyWith(studyRemindersEnabled: enabled);
    await _persistAndPush();
    await _rescheduleStudyReminder();
  }

  void toggleStreakReminders(bool enabled) {
    state = state.copyWith(streakRemindersEnabled: enabled);
    _persistAndPush().then((_) => _rescheduleStudyReminder()).catchError((e) {
      logger.warn('Failed to update streak reminders', tag: 'notifications', error: e);
    });
  }

  void toggleDailyGoalReminders(bool enabled) {
    state = state.copyWith(dailyGoalRemindersEnabled: enabled);
    _persistAndPush().then((_) => _rescheduleStudyReminder()).catchError((e) {
      logger.warn('Failed to update daily goal reminders', tag: 'notifications', error: e);
    });
  }

}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});

class NotificationState {
  final bool studyRemindersEnabled;
  final bool streakRemindersEnabled;
  final bool dailyGoalRemindersEnabled;
  final bool achievementAlertsEnabled;
  final Time reminderTime;
  final String timezone;
  final bool hasCustomWindow;

  NotificationState({
    required this.studyRemindersEnabled,
    required this.streakRemindersEnabled,
    required this.dailyGoalRemindersEnabled,
    required this.achievementAlertsEnabled,
    required this.reminderTime,
    required this.timezone,
    required this.hasCustomWindow,
  });

  NotificationState copyWith({
    bool? studyRemindersEnabled,
    bool? streakRemindersEnabled,
    bool? dailyGoalRemindersEnabled,
    bool? achievementAlertsEnabled,
    Time? reminderTime,
    String? timezone,
    bool? hasCustomWindow,
  }) {
    return NotificationState(
      studyRemindersEnabled: studyRemindersEnabled ?? this.studyRemindersEnabled,
      streakRemindersEnabled: streakRemindersEnabled ?? this.streakRemindersEnabled,
      dailyGoalRemindersEnabled: dailyGoalRemindersEnabled ?? this.dailyGoalRemindersEnabled,
      achievementAlertsEnabled: achievementAlertsEnabled ?? this.achievementAlertsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      timezone: timezone ?? this.timezone,
      hasCustomWindow: hasCustomWindow ?? this.hasCustomWindow,
    );
  }
}
