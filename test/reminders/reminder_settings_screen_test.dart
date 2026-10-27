import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/notification_provider.dart';
import 'package:lingafriq/screens/settings/reminder_settings_screen.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class _StubNotificationNotifier extends NotificationNotifier {
  @override
  NotificationState build() {
    return NotificationState(
      studyRemindersEnabled: true,
      streakRemindersEnabled: true,
      dailyGoalRemindersEnabled: true,
      achievementAlertsEnabled: true,
      reminderTime: const Time(9, 0),
      timezone: 'UTC',
      hasCustomWindow: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  testWidgets('reminder settings shows master toggle and quiet-hours copy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationProvider.overrideWith(() => _StubNotificationNotifier()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: ReminderSettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Study reminders'), findsOneWidget);
    expect(find.textContaining('quiet hours'), findsOneWidget);
    expect(find.bySemanticsLabel('Study reminders master switch'), findsOneWidget);
  });
}
