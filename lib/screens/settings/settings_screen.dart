import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Settings Screen - Pan-African Design System
class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminders = true;
  bool _achievementAlerts = true;
  bool _soundEffects = true;
  bool _darkMode = false;
  String _dailyGoal = '20 minutes';

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage:
          'Unable to load settings. Please check your connection and try again.',
      child: _buildSettings(context),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.forest,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PanAfricanRadius.xl),
                bottomRight: Radius.circular(PanAfricanRadius.xl),
              ),
              boxShadow: PanAfricanShadows.lg,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeaderIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            (widget.onBack ?? () => Navigator.pop(context))();
                          },
                        ),
                        Text(
                          'Settings',
                          style: PanAfricanTypography.headlineSmall(context)
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 40), // Balance the back button
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    // Settings icon
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 48.sp,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: PanAfricanSpacing.sm),

                  // Notifications Section
                  _SettingsSection(
                    title: 'Notifications',
                    isDark: isDark,
                    index: 0,
                    children: [
                      _SettingsSwitchTile(
                        icon: Icons.notifications_rounded,
                        title: 'Daily Reminders',
                        subtitle: 'Get reminded to practice each day',
                        value: _dailyReminders,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _dailyReminders = v);
                        },
                        isDark: isDark,
                      ),
                      _SettingsDivider(isDark: isDark),
                      _SettingsSwitchTile(
                        icon: Icons.emoji_events_rounded,
                        title: 'Achievement Alerts',
                        subtitle: 'Celebrate your milestones',
                        value: _achievementAlerts,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _achievementAlerts = v);
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Learning Section
                  _SettingsSection(
                    title: 'Learning',
                    isDark: isDark,
                    index: 1,
                    children: [
                      _SettingsDropdownTile(
                        icon: Icons.timer_rounded,
                        title: 'Daily Goal',
                        value: _dailyGoal,
                        options: ['10 minutes', '20 minutes', '30 minutes'],
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _dailyGoal = v!);
                        },
                        isDark: isDark,
                      ),
                      _SettingsDivider(isDark: isDark),
                      _SettingsSwitchTile(
                        icon: Icons.volume_up_rounded,
                        title: 'Sound Effects',
                        subtitle: 'Audio feedback during lessons',
                        value: _soundEffects,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _soundEffects = v);
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Appearance Section
                  _SettingsSection(
                    title: 'Appearance',
                    isDark: isDark,
                    index: 2,
                    children: [
                      _SettingsSwitchTile(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Dark Mode',
                        subtitle: 'Switch between light and dark theme',
                        value: _darkMode,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _darkMode = v);
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Icon(icon, color: Colors.white, size: 24.sp),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;
  final int index;

  const _SettingsSection({
    required this.title,
    required this.children,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.sm,
            bottom: PanAfricanSpacing.sm,
          ),
          child: Text(
            title,
            style: PanAfricanTypography.titleMedium(context).copyWith(
              color: PanAfricanColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            boxShadow: PanAfricanShadows.sm,
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.05, end: 0, duration: 300.ms);
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: PanAfricanColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Icon(
              icon,
              color: PanAfricanColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.bodyLarge(context),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: PanAfricanTypography.bodySmall(context),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: PanAfricanColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsDropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: PanAfricanColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Icon(
              icon,
              color: PanAfricanColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Text(
              title,
              style: PanAfricanTypography.bodyLarge(context),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm,
              vertical: PanAfricanSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: PanAfricanColors.primary,
              ),
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: PanAfricanColors.primary,
                fontWeight: FontWeight.w600,
              ),
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final bool isDark;

  const _SettingsDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: Divider(
        height: 1,
        color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
      ),
    );
  }
}
