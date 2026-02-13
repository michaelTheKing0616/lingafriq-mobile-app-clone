import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';

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
  int _downloadedCount = 0;
  int _storageSizeBytes = 0;
  bool _isLoadingStorage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStorageInfo();
    });
  }

  Future<void> _loadStorageInfo() async {
    if (!mounted) return;
    setState(() => _isLoadingStorage = true);
    try {
      final offlineNotifier = ref.read(offlineDownloadProvider.notifier);
      _downloadedCount = offlineNotifier.getDownloadedCount();
      _storageSizeBytes = await offlineNotifier.getStorageSizeBytes();
    } catch (e) {
      debugPrint('Error loading storage info: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStorage = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearOfflineData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Offline Data'),
        content: Text('This will delete all downloaded lessons and cached data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final offlineNotifier = ref.read(offlineDownloadProvider.notifier);
        final offlineState = ref.read(offlineDownloadProvider);
        
        // Delete all downloaded lessons
        for (final lessonId in offlineState.downloadedLessonIds) {
          await offlineNotifier.deleteLesson(lessonId);
        }
        
        // Reload storage info
        await _loadStorageInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Offline data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear offline data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
    final colorScheme = Theme.of(context).colorScheme;

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
                          .copyWith(color: colorScheme.onPrimary),
                        ),
                        const SizedBox(width: 40), // Balance the back button
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    // Settings icon
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                      color: colorScheme.onPrimary,
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
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Offline Storage Section
                  _SettingsSection(
                    title: 'Offline Storage',
                    isDark: isDark,
                    index: 3,
                    children: [
                      _SettingsInfoTile(
                        icon: Icons.cloud_download,
                        title: 'Downloaded Lessons',
                        value: _isLoadingStorage ? 'Loading...' : '$_downloadedCount lessons',
                        isDark: isDark,
                      ),
                      _SettingsDivider(isDark: isDark),
                      _SettingsInfoTile(
                        icon: Icons.storage,
                        title: 'Storage Used',
                        value: _isLoadingStorage ? 'Loading...' : _formatBytes(_storageSizeBytes),
                        isDark: isDark,
                      ),
                      _SettingsDivider(isDark: isDark),
                      _SettingsActionTile(
                        icon: Icons.delete_outline,
                        title: 'Clear Offline Data',
                        subtitle: 'Delete all downloaded lessons and cache',
                        onTap: () => _clearOfflineData(context),
                        isDark: isDark,
                        isDestructive: true,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.onPrimary.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Icon(icon, color: colorScheme.onPrimary, size: 24.sp),
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

class _SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
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
              ],
            ),
          ),
          Text(
            value,
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: PanAfricanColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : PanAfricanColors.primary;
    
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
              child: Icon(
                icon,
                color: color,
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
                    style: PanAfricanTypography.bodyLarge(context).copyWith(
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
