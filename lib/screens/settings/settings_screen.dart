import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                    // Always show back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onBack ?? () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: const CircleBorder(),
                        ),
                      ),
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
  
  const _SettingsCard({
    required this.title,
    required this.children,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          ...children,
        ],
      ),
    );
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
            onChanged: onChanged,
            activeColor: AfricanTheme.primaryGreen,
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              items: options.map((opt) => DropdownMenuItem(
                value: opt,
                child: Text(opt),
              )).toList(),
              onChanged: onChanged,
              underline: const SizedBox(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

