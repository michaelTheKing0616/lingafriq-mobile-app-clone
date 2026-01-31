import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/services/auth/biometric_auth.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/services/offline/selective_sync.dart' show SelectiveSyncService, SyncCategory, SyncPreference;
import 'package:lingafriq/services/offline/cache_encryption.dart' show CacheEncryptionService;
import 'package:lingafriq/services/offline/offline_service.dart' show OfflineService, CacheStats;
import 'package:lingafriq/screens/settings/edit_profile_screen.dart';
import 'package:lingafriq/screens/settings/change_password_screen.dart';
import 'package:lingafriq/screens/settings/privacy_settings_screen.dart';
import 'package:lingafriq/providers/theme_mode_provider.dart';
import 'package:lingafriq/providers/notification_provider.dart';
import 'package:lingafriq/screens/goals/daily_goals_screen.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Beautiful Material 3 Settings Screen with Pan-African Design
class SettingsScreenMaterial3 extends HookConsumerWidget {
  const SettingsScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = useState(Theme.of(context).brightness == Brightness.dark);
    final notificationsEnabled = useState(true);
    final soundEffectsEnabled = useState(true);
    final dailyRemindersEnabled = useState(true);
    final selectedLanguage = useState('english');
    final biometricEnabled = useState<bool?>(null);
    final biometricAvailable = useState<bool>(false);
    final biometricType = useState<String?>(null);
    final cacheEncryptionEnabled = useState<bool?>(null);
    
    // Check biometric availability
    useEffect(() {
      _checkBiometricAvailability(biometricAvailable, biometricType, biometricEnabled);
      _loadCacheEncryptionSetting(cacheEncryptionEnabled);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark.value
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSection(
                  context,
                  'Appearance',
                  [
                    SwitchListTile(
                      title: Text('Dark Mode', style: PanAfricanTypography.bodyLarge(context)),
                      subtitle: Text('Switch between light and dark theme',
                          style: PanAfricanTypography.bodySmall(context)),
                      value: isDark.value,
                      onChanged: (value) async {
                        await safeAsync(
                          context: context,
                          operation: () async {
                            await ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                          },
                          errorContext: 'toggleDarkMode',
                        );
                        isDark.value = value;
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dark mode ${value ? 'enabled' : 'disabled'}'),
                            duration: Duration(seconds: 2),
                            backgroundColor: PanAfricanColors.primary,
                          ),
                        );
                      },
                      secondary: Icon(
                        isDark.value ? Icons.dark_mode : Icons.light_mode,
                        color: PanAfricanColors.primary,
                      ),
                      activeColor: PanAfricanColors.primary,
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Notifications Section
                _buildSection(
                  context,
                  'Notifications',
                  [
                    SwitchListTile(
                      title: Text('Push Notifications'),
                      subtitle: Text('Receive push notifications'),
                      value: notificationsEnabled.value,
                      onChanged: (value) {
                        notificationsEnabled.value = value;
                      },
                      secondary: Icon(Icons.notifications),
                    ),
                    SwitchListTile(
                      title: Text('Daily Reminders'),
                      subtitle: Text('Get reminded to practice daily'),
                      value: dailyRemindersEnabled.value,
                      onChanged: (value) {
                        dailyRemindersEnabled.value = value;
                      },
                      secondary: Icon(Icons.access_alarm),
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Audio Section
                _buildSection(
                  context,
                  'Audio',
                  [
                    SwitchListTile(
                      title: Text('Sound Effects'),
                      subtitle: Text('Play sound effects during lessons'),
                      value: soundEffectsEnabled.value,
                      onChanged: (value) {
                        soundEffectsEnabled.value = value;
                      },
                      secondary: Icon(Icons.volume_up),
                    ),
                    ListTile(
                      leading: Icon(Icons.language),
                      title: Text('App Language'),
                      subtitle: Text(selectedLanguage.value),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        _showLanguagePicker(context, selectedLanguage, ref);
                      },
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Security Section
                _buildSection(
                  context,
                  'Security',
                  [
                    if (biometricAvailable.value)
                      SwitchListTile(
                        title: Text('Biometric Authentication', style: PanAfricanTypography.bodyLarge(context)),
                        subtitle: Text(
                          biometricType.value != null
                              ? 'Sign in with ${biometricType.value}'
                              : 'Use biometric to sign in quickly',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        value: biometricEnabled.value ?? false,
                        onChanged: (value) async {
                          HapticFeedback.mediumImpact();
                          if (value) {
                            // Test biometric
                            final authenticated = await BiometricAuth.authenticate(
                              localizedReason: 'Enable biometric authentication',
                            );
                            if (authenticated) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('biometric_enabled', true);
                              biometricEnabled.value = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Biometric authentication enabled'),
                                  backgroundColor: PanAfricanColors.primary,
                                ),
                              );
                            }
                          } else {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('biometric_enabled', false);
                            biometricEnabled.value = false;
                          }
                        },
                        secondary: Icon(
                          biometricType.value?.toLowerCase().contains('finger') == true
                              ? Icons.fingerprint
                              : Icons.face,
                          color: PanAfricanColors.primary,
                        ),
                        activeColor: PanAfricanColors.primary,
                      ),
                    SwitchListTile(
                      title: Text('Encrypt Cached Data', style: PanAfricanTypography.bodyLarge(context)),
                      subtitle: Text(
                        'Encrypt sensitive data stored on device',
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                      value: cacheEncryptionEnabled.value ?? false,
                      onChanged: (value) async {
                        HapticFeedback.mediumImpact();
                        final encryption = CacheEncryptionService();
                        await encryption.initialize();
                        await encryption.setEncryptionEnabled(value);
                        cacheEncryptionEnabled.value = value;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Cache encryption enabled'
                                  : 'Cache encryption disabled',
                            ),
                            backgroundColor: PanAfricanColors.primary,
                          ),
                        );
                      },
                      secondary: Icon(Icons.lock, color: PanAfricanColors.primary),
                      activeColor: PanAfricanColors.primary,
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Account Section
                _buildSection(
                  context,
                  'Account',
                  [
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Edit Profile'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.lock),
                      title: Text('Change Password'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.privacy_tip),
                      title: Text('Privacy Settings'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Learning Section
                _buildSection(
                  context,
                  'Learning',
                  [
                    ListTile(
                      leading: Icon(Icons.school),
                      title: Text('Learning Goals'),
                      subtitle: Text('Set your daily learning goals'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DailyGoalsScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.timer),
                      title: Text('Study Reminders'),
                      subtitle: Text('Configure when to be reminded'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        _showStudyReminderSettings(context, ref);
                      },
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Offline & Sync Section
                _buildSection(
                  context,
                  'Offline & Sync',
                  [
                    ListTile(
                      leading: Icon(Icons.cloud_sync),
                      title: Text('Sync Settings'),
                      subtitle: Text('Configure what to sync'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        _showSyncSettings(context, ref);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.storage),
                      title: Text('Cache Management'),
                      subtitle: Text('View and manage cached data'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () {
                        _showCacheManagement(context, ref);
                      },
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // About Section
                _buildSection(
                  context,
                  'About',
                  [
                    ListTile(
                      leading: Icon(Icons.info),
                      title: Text('App Version'),
                      subtitle: Text('1.6.0'),
                    ),
                    ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Terms of Service'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () async {
                        await kLaunchUrl('https://lingafriq.com/terms');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.privacy_tip),
                      title: Text('Privacy Policy'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () async {
                        await kLaunchUrl('https://lingafriq.com/privacy');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.help),
                      title: Text('Help & Support'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                      onTap: () async {
                        await kLaunchUrl('mailto:contact@lingafriq.com?subject=LingAfriq%20Support');
                      },
                    ),
                  ],
                  isDark.value,
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Card(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    ValueNotifier<String> selectedLanguage,
    WidgetRef ref,
  ) async {
    final localizationService = DynamicLocalizationService();
    await DynamicLocalizationService.initialize();
    
    final languages = AppLanguage.values.map((lang) => lang.name).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language',
                style: PanAfricanTypography.titleLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Expanded(
                child: OptimizedListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return RadioListTile<String>(
                      title: Text(
                        lang.substring(0, 1).toUpperCase() + lang.substring(1),
                      ),
                      value: lang,
                      groupValue: selectedLanguage.value,
                      onChanged: (value) async {
                        if (value != null) {
                          selectedLanguage.value = value;
                          final appLang = AppLanguage.values.firstWhere(
                            (e) => e.name == value,
                            orElse: () => AppLanguage.english,
                          );
                          await DynamicLocalizationService.setLanguage(appLang.code);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language changed to ${value}'),
                              backgroundColor: PanAfricanColors.primary,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkBiometricAvailability(
    ValueNotifier<bool> available,
    ValueNotifier<String?> type,
    ValueNotifier<bool?> enabled,
  ) async {
    final isAvailable = await BiometricAuth.isAvailable();
    available.value = isAvailable;
    
    if (isAvailable) {
      final biometrics = await BiometricAuth.getAvailableBiometrics();
      if (biometrics.isNotEmpty) {
        type.value = BiometricAuth.getBiometricTypeName(biometrics.first);
      }
      
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool('biometric_enabled') ?? false;
    }
  }

  Future<void> _loadCacheEncryptionSetting(ValueNotifier<bool?> enabled) async {
    final encryption = CacheEncryptionService();
    await encryption.initialize();
    enabled.value = await encryption.isEncryptionEnabled();
  }

  void _showSyncSettings(BuildContext context, WidgetRef ref) async {
    final selectiveSync = SelectiveSyncService();
    await selectiveSync.initialize();
    final preferences = await selectiveSync.getAllPreferences();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sync Settings',
                style: PanAfricanTypography.titleLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              ...preferences.entries.map((entry) {
                return SwitchListTile(
                  title: Text(_getCategoryName(entry.key)),
                  subtitle: Text('Sync ${_getCategoryName(entry.key).toLowerCase()} data'),
                  value: entry.value.enabled,
                  onChanged: (value) async {
                    await selectiveSync.setPreference(
                      SyncPreference(
                        category: entry.key,
                        enabled: value,
                        syncOnWifiOnly: entry.value.syncOnWifiOnly,
                        maxSize: entry.value.maxSize,
                      ),
                    );
                    Navigator.pop(context);
                    _showSyncSettings(context, ref);
                  },
                );
              }),
              SizedBox(height: PanAfricanSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _showCacheManagement(BuildContext context, WidgetRef ref) async {
    final offlineService = OfflineService();
    await offlineService.initialize();
    final stats = await offlineService.getCacheStats();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cache Management'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Files: ${stats['fileCount'] ?? 0}'),
              SizedBox(height: 8.h),
              Text('Total Size: ${stats['formattedSize'] ?? '0 B'}'),
              SizedBox(height: 8.h),
              Text('Pending Sync: ${stats['queueSize'] ?? 0} operations'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await offlineService.clearCache(null);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cache cleared'),
                    backgroundColor: PanAfricanColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text('Clear Cache'),
            ),
          ],
        );
      },
    );
  }

  void _showStudyReminderSettings(BuildContext context, WidgetRef ref) {
    final state = ref.read(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var streakEnabled = state.streakRemindersEnabled;
        var dailyEnabled = state.dailyGoalRemindersEnabled;
        var timeOfDay = TimeOfDay(hour: state.reminderTime.hour, minute: state.reminderTime.minute);

        return StatefulBuilder(
            return ResponsiveSafeArea(
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 16.h,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Study reminders',
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SwitchListTile(
                      title: const Text('Daily goal reminder'),
                      subtitle: const Text('Get a daily nudge to hit your learning goal'),
                      value: dailyEnabled,
                      onChanged: (v) {
                        setState(() => dailyEnabled = v);
                        notifier.toggleDailyGoalReminders(v);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Streak reminder'),
                      subtitle: const Text('Get a reminder to keep your streak alive'),
                      value: streakEnabled,
                      onChanged: (v) {
                        setState(() => streakEnabled = v);
                        notifier.toggleStreakReminders(v);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Reminder time'),
                      subtitle: Text(timeOfDay.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: timeOfDay,
                        );
                        if (picked == null) return;
                        setState(() => timeOfDay = picked);
                        notifier.updateReminderTime(Time(picked.hour, picked.minute));
                      },
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryName(SyncCategory category) {
    switch (category) {
      case SyncCategory.profile:
        return 'Profile';
      case SyncCategory.lessons:
        return 'Lessons';
      case SyncCategory.quizzes:
        return 'Quizzes';
      case SyncCategory.progress:
        return 'Progress';
      case SyncCategory.media:
        return 'Media';
      case SyncCategory.cultureMagazine:
        return 'Culture Magazine';
      case SyncCategory.games:
        return 'Games';
      case SyncCategory.chat:
        return 'Chat';
      case SyncCategory.achievements:
        return 'Achievements';
      case SyncCategory.content:
        return 'Content';
      case SyncCategory.settings:
        return 'Settings';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Logout logic
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}

