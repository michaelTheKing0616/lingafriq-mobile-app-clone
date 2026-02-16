import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'gamification_provider.dart';
import '../utils/structured_logger.dart';

/// Time class for notification scheduling
/// Represents a time of day with hour, minute, and second
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

/// Provider for managing push notifications
class NotificationNotifier extends Notifier<NotificationState> {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  NotificationState build() {
    _initializeNotifications();
    return NotificationState(
      streakRemindersEnabled: true,
      dailyGoalRemindersEnabled: true,
      achievementAlertsEnabled: true,
      reminderTime: const Time(9, 0, 0), // 9 AM default
    );
  }

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

    // Load saved notification preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHour = prefs.getInt('notif_reminder_hour');
      final savedMinute = prefs.getInt('notif_reminder_minute');
      final streakEnabled = prefs.getBool('notif_streak_enabled');
      final goalEnabled = prefs.getBool('notif_goal_enabled');
      
      if (savedHour != null && savedMinute != null) {
        state = state.copyWith(
          reminderTime: Time(savedHour, savedMinute),
          streakRemindersEnabled: streakEnabled ?? true,
          dailyGoalRemindersEnabled: goalEnabled ?? true,
        );
      }
    } catch (e) {
      logger.warn('Failed to load notification preferences', tag: 'notifications', error: e);
    }

    // Auto-schedule reminders on initialization.
    // Idempotent: zonedSchedule with the same notification ID replaces any existing schedule.
    // Uses saved reminder time if available, otherwise defaults to 9:00 AM.
    try {
      final time = state.reminderTime;
      if (state.streakRemindersEnabled) {
        await scheduleStreakReminder(time);
      }
      if (state.dailyGoalRemindersEnabled) {
        await scheduleDailyGoalReminder(time);
      }
    } catch (e) {
      // Non-fatal: notification permission may not be granted yet on first launch,
      // or timezone data may not be initialized. Scheduling will succeed when
      // user enables reminders in settings.
      logger.warn('Auto-schedule reminders failed', tag: 'notifications', error: e);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> scheduleStreakReminder(Time time) async {
    final streak = _getCurrentStreak();
    final body = streak > 0
        ? 'Don\'t break your $streak day streak!'
        : 'Start your streak today — learn something new!';
    await _notifications.zonedSchedule(
      0,
      'Keep your streak alive! 🔥',
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Streak Reminders',
          channelDescription: 'Reminders to maintain your learning streak',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyGoalReminder(Time time) async {
    await _notifications.zonedSchedule(
      1,
      'Time to learn! 📚',
      'Complete your daily goal and earn rewards!',
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_goal_reminder',
          'Daily Goal Reminders',
          channelDescription: 'Reminders to complete your daily learning goal',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showAchievementAlert(String title, String body) async {
    await _notifications.show(
      2,
      title,
      body,
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

  tz.TZDateTime _nextInstanceOfTime(Time time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  int _getCurrentStreak() {
    // Get current streak from gamification provider
    try {
      final gamification = ref.read(gamificationProvider.notifier).gamification;
      return gamification.dailyStreak;
    } catch (e) {
      // Fallback to 0 if gamification provider is not available
      return 0;
    }
  }

  void updateReminderTime(Time time) {
    state = state.copyWith(reminderTime: time);
    // Persist reminder time
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('notif_reminder_hour', time.hour);
      prefs.setInt('notif_reminder_minute', time.minute);
    }).catchError((e) {
      logger.warn('Failed to persist reminder time', tag: 'notifications', error: e);
    });
    if (state.streakRemindersEnabled) {
      scheduleStreakReminder(time).catchError((e) {
        logger.warn('Failed to reschedule streak reminder', tag: 'notifications', error: e);
      });
    }
    if (state.dailyGoalRemindersEnabled) {
      scheduleDailyGoalReminder(time).catchError((e) {
        logger.warn('Failed to reschedule daily goal reminder', tag: 'notifications', error: e);
      });
    }
  }

  void toggleStreakReminders(bool enabled) {
    state = state.copyWith(streakRemindersEnabled: enabled);
    // Persist toggle state
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('notif_streak_enabled', enabled);
    }).catchError((e) {
      logger.warn('Failed to persist streak reminder preference', tag: 'notifications', error: e);
    });
    if (enabled) {
      scheduleStreakReminder(state.reminderTime).catchError((e) {
        logger.warn('Failed to schedule streak reminder', tag: 'notifications', error: e);
      });
    } else {
      _notifications.cancel(0);
    }
  }

  void toggleDailyGoalReminders(bool enabled) {
    state = state.copyWith(dailyGoalRemindersEnabled: enabled);
    // Persist toggle state
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('notif_goal_enabled', enabled);
    }).catchError((e) {
      logger.warn('Failed to persist daily goal reminder preference', tag: 'notifications', error: e);
    });
    if (enabled) {
      scheduleDailyGoalReminder(state.reminderTime).catchError((e) {
        logger.warn('Failed to schedule daily goal reminder', tag: 'notifications', error: e);
      });
    } else {
      _notifications.cancel(1);
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});

class NotificationState {
  final bool streakRemindersEnabled;
  final bool dailyGoalRemindersEnabled;
  final bool achievementAlertsEnabled;
  final Time reminderTime;

  NotificationState({
    required this.streakRemindersEnabled,
    required this.dailyGoalRemindersEnabled,
    required this.achievementAlertsEnabled,
    required this.reminderTime,
  });

  NotificationState copyWith({
    bool? streakRemindersEnabled,
    bool? dailyGoalRemindersEnabled,
    bool? achievementAlertsEnabled,
    Time? reminderTime,
  }) {
    return NotificationState(
      streakRemindersEnabled: streakRemindersEnabled ?? this.streakRemindersEnabled,
      dailyGoalRemindersEnabled: dailyGoalRemindersEnabled ?? this.dailyGoalRemindersEnabled,
      achievementAlertsEnabled: achievementAlertsEnabled ?? this.achievementAlertsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

