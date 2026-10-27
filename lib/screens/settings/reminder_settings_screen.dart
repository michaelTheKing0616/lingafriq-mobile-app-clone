import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/learning/reminders/reminder_policy.dart';
import 'package:lingafriq/providers/notification_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:timezone/timezone.dart' as tz;

/// Study reminder preferences — reference: Calm notification settings (single daily nudge, quiet hours).
class ReminderSettingsScreen extends HookConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final timeOfDay = useState(
      TimeOfDay(hour: state.reminderTime.hour, minute: state.reminderTime.minute),
    );

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Study reminders', style: PanAfricanTypography.titleLarge(context)),
        centerTitle: false,
      ),
      body: ResponsiveSafeArea(
        child: ListView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: [
            Semantics(
              label: 'Study reminders master switch',
              child: SwitchListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
                title: Text('Daily practice nudge', style: PanAfricanTypography.bodyLarge(context)),
                subtitle: Text(
                  'At most one gentle reminder per day, never during quiet hours (10pm–7am).',
                  style: PanAfricanTypography.bodySmall(context),
                ),
                value: state.studyRemindersEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  notifier.setStudyRemindersEnabled(v);
                },
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            _SectionHeader(title: 'Your window', context: context),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
              leading: Icon(Icons.schedule_rounded, color: PanAfricanColors.primary),
              title: Text('Reminder time', style: PanAfricanTypography.bodyLarge(context)),
              subtitle: Text(timeOfDay.value.format(context), style: PanAfricanTypography.bodySmall(context)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                HapticFeedback.lightImpact();
                final picked = await showTimePicker(context: context, initialTime: timeOfDay.value);
                if (picked == null) return;
                timeOfDay.value = picked;
                await notifier.updateReminderTime(Time(picked.hour, picked.minute));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
              leading: Icon(Icons.public_rounded, color: PanAfricanColors.primary),
              title: Text('Timezone', style: PanAfricanTypography.bodyLarge(context)),
              subtitle: Text(state.timezone, style: PanAfricanTypography.bodySmall(context)),
              trailing: TextButton(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await notifier.updateTimezone(tz.local.name);
                },
                child: const Text('Use device'),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            _SectionHeader(title: 'What we remind you about', context: context),
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
              title: Text('Daily goal', style: PanAfricanTypography.bodyLarge(context)),
              subtitle: Text(
                'A warm nudge to finish today’s learning goal',
                style: PanAfricanTypography.bodySmall(context),
              ),
              value: state.dailyGoalRemindersEnabled,
              onChanged: state.studyRemindersEnabled
                  ? (v) {
                      HapticFeedback.selectionClick();
                      notifier.toggleDailyGoalReminders(v);
                    }
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
              title: Text('Practice rhythm', style: PanAfricanTypography.bodyLarge(context)),
              subtitle: Text(
                'Celebrate milestones — we never use loss-aversion copy',
                style: PanAfricanTypography.bodySmall(context),
              ),
              value: state.streakRemindersEnabled,
              onChanged: state.studyRemindersEnabled
                  ? (v) {
                      HapticFeedback.selectionClick();
                      notifier.toggleStreakReminders(v);
                    }
                  : null,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              ),
              child: Text(
                'Quiet hours run from ${ReminderPolicy.quietHourStart}:00 to '
                '${ReminderPolicy.quietHourEnd}:00 in your timezone. '
                'Settings sync to your account so they return after reinstall.',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.context});

  final String title;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: PanAfricanSpacing.sm,
        bottom: PanAfricanSpacing.xs,
      ),
      child: Text(title, style: PanAfricanTypography.titleSmall(this.context)),
    );
  }
}
