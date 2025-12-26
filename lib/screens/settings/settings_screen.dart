import 'package:flutter/material.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/utils/haptic_feedback_helper.dart';
import 'package:lingafriq/widgets/material3/material3_migration_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Settings Screen - Based on Figma Make Design
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
      errorMessage: 'Settings temporarily unavailable',
      child: _buildSettings(context),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF007A3D), // Green
                  Color(0xFF00A8E8), // Blue
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    // Always show back button and menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: widget.onBack ?? () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: 22.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Notifications Card
                  _SettingsCard(
                    title: 'Notifications',
                    isDark: isDark,
                    index: 0,
                    children: [
                      _SwitchSetting(
                        icon: Icons.notifications_rounded,
                        label: 'Daily Reminders',
                        value: _dailyReminders,
                        onChanged: (v) => setState(() => _dailyReminders = v),
                        isDark: isDark,
                      ),
                      _SwitchSetting(
                        icon: Icons.emoji_events_rounded,
                        label: 'Achievement Alerts',
                        value: _achievementAlerts,
                        onChanged: (v) => setState(() => _achievementAlerts = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // Learning Card
                  _SettingsCard(
                    title: 'Learning',
                    isDark: isDark,
                    index: 1,
                    children: [
                      _DropdownSetting(
                        label: 'Daily Goal',
                        value: _dailyGoal,
                        options: ['10 minutes', '20 minutes', '30 minutes'],
                        onChanged: (v) => setState(() => _dailyGoal = v!),
                        isDark: isDark,
                      ),
                      _SwitchSetting(
                        icon: Icons.volume_up_rounded,
                        label: 'Sound Effects',
                        value: _soundEffects,
                        onChanged: (v) => setState(() => _soundEffects = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // Appearance Card
                  _SettingsCard(
                    title: 'Appearance',
                    isDark: isDark,
                    index: 2,
                    children: [
                      _SwitchSetting(
                        icon: Icons.palette_rounded,
                        label: 'Dark Mode',
                        value: _darkMode,
                        onChanged: (v) => setState(() => _darkMode = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;
  final int index;
  
  const _SettingsCard({
    required this.title,
    required this.children,
    required this.isDark,
    required this.index,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material3Helper.enhancedCard(
      elevation: isDark ? 2 : 4,
      color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          ...children,
        ],
      ),
    ).animate(delay: (index * 100).ms)
      .fadeIn(duration: 300.ms)
      .slideX(begin: -0.1, end: 0, duration: 300.ms);
  }
}

class _SwitchSetting extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  
  const _SwitchSetting({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AfricanTheme.primaryGreen,
                size: 20,
              ),
              SizedBox(width: 3.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticHelper.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isDark;
  
  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          MenuButtonTheme(
            data: MenuButtonThemeData(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
            ),
            child: MenuAnchor(
              builder: (context, controller, child) {
                return FilledButton.tonal(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_drop_down, size: 20.sp),
                    ],
                  ),
                );
              },
              menuChildren: options.map((opt) {
                return MenuItemButton(
                  onPressed: () {
                    onChanged(opt);
                  },
                  child: Text(opt),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

