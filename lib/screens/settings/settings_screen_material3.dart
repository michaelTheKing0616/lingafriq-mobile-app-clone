import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/services/auth/biometric_auth.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart'
    show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/services/offline/selective_sync.dart'
    show SelectiveSyncService, SyncCategory, SyncPreference;
import 'package:lingafriq/services/offline/cache_encryption.dart'
    show CacheEncryptionService;
import 'package:lingafriq/services/offline/offline_service.dart' show OfflineService;
import 'package:lingafriq/screens/settings/edit_profile_screen.dart';
import 'package:lingafriq/screens/settings/change_password_screen.dart';
import 'package:lingafriq/screens/settings/privacy_settings_screen.dart';
import 'package:lingafriq/screens/settings/synthetic_voice_styles_screen.dart';
import 'package:lingafriq/providers/theme_mode_provider.dart';
import 'package:lingafriq/providers/notification_provider.dart';
import 'package:lingafriq/screens/goals/daily_goals_screen.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/staff/micro_mentor_reports_screen.dart';
import 'package:lingafriq/services/auth/biometric_preference_service.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Beautiful Material 3 Settings Screen with Pan-African Design
class SettingsScreenMaterial3 extends HookConsumerWidget {
  const SettingsScreenMaterial3({super.key});

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
    final polieSerifLanguageText = useState(false);
    final currentUser = ref.watch(userProvider);
    final biometricPreferenceService = useMemoized(() => BiometricPreferenceService());

    // Check biometric availability and load Polie serif preference
    useEffect(() {
      _checkBiometricAvailability(
        biometricAvailable,
        biometricType,
        biometricEnabled,
        currentUser?.email,
        biometricPreferenceService,
      );
      _loadCacheEncryptionSetting(cacheEncryptionEnabled);
      _loadPolieSerifPreference(polieSerifLanguageText);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: PanAfricanTypography.titleLarge(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: isDark.value
            ? PanAfricanColors.surfaceDark
            : PanAfricanColors.surfaceLight,
        child: ResponsiveSafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSection(
                  context,
                  'Appearance',
                  [
                    _SettingsTile(
                      icon: isDark.value
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark theme',
                      toggleValue: isDark.value,
                      trailing: Switch.adaptive(
                        value: isDark.value,
                        onChanged: (value) async {
                          HapticFeedback.mediumImpact();
                          await safeAsync(
                            context: context,
                            operation: () async {
                              await ref.read(themeModeProvider.notifier).setThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light);
                            },
                            errorContext: 'toggleDarkMode',
                          );
                          isDark.value = value;
                          if (context.mounted) {
                            showLingAfriqInfo(context,
                                'Dark mode ${value ? 'enabled' : 'disabled'}');
                          }
                        },
                        activeColor: PanAfricanColors.primary,
                      ),
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  0,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Notifications Section
                _buildSection(
                  context,
                  'Notifications',
                  [
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications',
                      toggleValue: notificationsEnabled.value,
                      trailing: Switch.adaptive(
                        value: notificationsEnabled.value,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          notificationsEnabled.value = value;
                        },
                        activeColor: PanAfricanColors.primary,
                      ),
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.access_alarm_rounded,
                      title: 'Daily Reminders',
                      subtitle: 'Get reminded to practice daily',
                      toggleValue: dailyRemindersEnabled.value,
                      trailing: Switch.adaptive(
                        value: dailyRemindersEnabled.value,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          dailyRemindersEnabled.value = value;
                        },
                        activeColor: PanAfricanColors.primary,
                      ),
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  1,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Audio Section
                _buildSection(
                  context,
                  'Audio',
                  [
                    _SettingsTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound Effects',
                      subtitle: 'Play sound effects during lessons',
                      toggleValue: soundEffectsEnabled.value,
                      trailing: Switch.adaptive(
                        value: soundEffectsEnabled.value,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          soundEffectsEnabled.value = value;
                        },
                        activeColor: PanAfricanColors.primary,
                      ),
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Tutor voice styles',
                      subtitle: 'Synthetic, non-identifying voices (opt-in)',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SyntheticVoiceStylesScreen(language: 'yoruba'),
                          ),
                        );
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'App Language',
                      subtitle: selectedLanguage.value,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showLanguagePicker(context, selectedLanguage, ref);
                      },
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  2,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Security Section
                _buildSection(
                  context,
                  'Security',
                  [
                    if (biometricAvailable.value)
                      _SettingsTile(
                        icon: biometricType.value?.toLowerCase().contains('finger') ==
                                true
                            ? Icons.fingerprint_rounded
                            : Icons.face_rounded,
                        title: 'Biometric Authentication',
                        subtitle: biometricType.value != null
                            ? 'Sign in with ${biometricType.value}'
                            : 'Use biometric to sign in quickly',
                        toggleValue: biometricEnabled.value ?? false,
                        trailing: Switch.adaptive(
                          value: biometricEnabled.value ?? false,
                          onChanged: (value) async {
                            HapticFeedback.mediumImpact();
                            if (value) {
                              try {
                                final result = await BiometricAuth.authenticateWithResult(
                                  localizedReason: 'Enable biometric authentication',
                                );
                                if (result.success) {
                                  if (currentUser?.email == null ||
                                      currentUser!.email.trim().isEmpty) {
                                    if (context.mounted) {
                                      showLingAfriqError(
                                        context,
                                        'Unable to enable biometrics: missing account identity.',
                                      );
                                    }
                                    return;
                                  }
                                  await biometricPreferenceService.enableForEmail(currentUser.email);
                                  biometricEnabled.value = true;
                                  if (context.mounted) {
                                    showLingAfriqSuccess(
                                        context, 'Biometric authentication enabled');
                                  }
                                } else if (context.mounted) {
                                  showLingAfriqError(
                                    context,
                                    result.errorMessage ??
                                        'Biometric authentication failed. Please try again or check your device settings.',
                                  );
                                }
                              } catch (e) {
                                logger.error(
                                  'Biometric auth failed',
                                  tag: 'biometric',
                                  error: e,
                                );
                                if (context.mounted) {
                                  final errorMsg = e.toString().replaceAll('Exception: ', '');
                                  showLingAfriqError(
                                      context, errorMsg.contains('NotEnrolled')
                                          ? 'Please set up Face ID or fingerprint in your device settings first.'
                                          : errorMsg.contains('LockedOut')
                                              ? 'Too many failed attempts. Please wait and try again.'
                                              : 'Biometric not available: $errorMsg');
                                }
                              }
                            } else {
                              await biometricPreferenceService.disable();
                              biometricEnabled.value = false;
                            }
                          },
                          activeColor: PanAfricanColors.primary,
                        ),
                        isDark: isDark.value,
                      ),
                    if (biometricAvailable.value) _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.lock_rounded,
                      title: 'Encrypt Cached Data',
                      subtitle: 'Encrypt sensitive data stored on device',
                      toggleValue: cacheEncryptionEnabled.value ?? false,
                      trailing: Switch.adaptive(
                        value: cacheEncryptionEnabled.value ?? false,
                        onChanged: (value) async {
                          HapticFeedback.mediumImpact();
                          final encryption = CacheEncryptionService();
                          await encryption.initialize();
                          await encryption.setEncryptionEnabled(value);
                          cacheEncryptionEnabled.value = value;
                          if (context.mounted) {
                            showLingAfriqSuccess(
                              context,
                              value
                                  ? 'Cache encryption enabled'
                                  : 'Cache encryption disabled',
                            );
                          }
                        },
                        activeColor: PanAfricanColors.primary,
                      ),
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  3,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Account Section
                _buildSection(
                  context,
                  'Account',
                  [
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Settings',
                      subtitle: 'Manage your privacy preferences',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                      isDark: isDark.value,
                    ),
                    if (currentUser?.isStaffOrAdmin == true) ...[
                      _SettingsDivider(isDark: isDark.value),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        title: 'Micro-mentor reports',
                        subtitle: 'Review safety reports (staff)',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: PanAfricanColors.neutralMedium,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const StaffMicroMentorReportsScreen(),
                            ),
                          );
                        },
                        isDark: isDark.value,
                      ),
                    ],
                  ],
                  isDark.value,
                  4,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Learning Section
                _buildSection(
                  context,
                  'Learning',
                  [
                    _SettingsTile(
                      icon: Icons.school_rounded,
                      title: 'Learning Goals',
                      subtitle: 'Set your daily learning goals',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DailyGoalsScreen()),
                        );
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.timer_rounded,
                      title: 'Study Reminders',
                      subtitle: 'Configure when to be reminded',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showStudyReminderSettings(context, ref);
                      },
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  5,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Offline & Sync Section
                _buildSection(
                  context,
                  'Offline & Sync',
                  [
                    _SettingsTile(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Sync Settings',
                      subtitle: 'Configure what to sync',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showSyncSettings(context, ref);
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.storage_rounded,
                      title: 'Cache Management',
                      subtitle: 'View and manage cached data',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showCacheManagement(context, ref);
                      },
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  6,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // About Section
                _buildSection(
                  context,
                  'About',
                  [
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      title: 'App Version',
                      subtitle: '1.6.0',
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.description_rounded,
                      title: 'Terms of Service',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await kLaunchUrl(UrlConstants.termsUrl);
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await kLaunchUrl('${EnvConfig.appWebUrl}/privacy');
                      },
                      isDark: isDark.value,
                    ),
                    _SettingsDivider(isDark: isDark.value),
                    _SettingsTile(
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await kLaunchUrl(UrlConstants.supportEmail);
                      },
                      isDark: isDark.value,
                    ),
                  ],
                  isDark.value,
                  7,
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Logout Button
                _LogoutButton(onTap: () => _showLogoutDialog(context, ref)),
                SizedBox(height: PanAfricanSpacing.xl),
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
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.sm,
            bottom: PanAfricanSpacing.sm,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: PanAfricanTypography.titleMedium(context).copyWith(
                color: isDark
                    ? PanAfricanColors.textPrimaryDark
                    : PanAfricanColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
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
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.03, end: 0, duration: 300.ms);
  }

  void _showLanguagePicker(
    BuildContext context,
    ValueNotifier<String> selectedLanguage,
    WidgetRef ref,
  ) async {
    await DynamicLocalizationService.initialize();

    final languages = AppLanguage.values.map((lang) => lang.name).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(PanAfricanRadius.xl),
            ),
          ),
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: PanAfricanColors.neutralLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
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
                        style: PanAfricanTypography.bodyLarge(context),
                      ),
                      value: lang,
                      groupValue: selectedLanguage.value,
                      activeColor: PanAfricanColors.primary,
                      onChanged: (value) async {
                        HapticFeedback.selectionClick();
                        if (value != null) {
                          selectedLanguage.value = value;
                          final appLang = AppLanguage.values.firstWhere(
                            (e) => e.name == value,
                            orElse: () => AppLanguage.english,
                          );
                          await DynamicLocalizationService.setLanguage(appLang.code);
                          Navigator.pop(context);
                          if (context.mounted) {
                            showLingAfriqSuccess(context, 'Language changed to $value');
                          }
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
    String? email,
    BiometricPreferenceService biometricPreferenceService,
  ) async {
    final isAvailable = await BiometricAuth.isAvailable();
    available.value = isAvailable;

    if (isAvailable) {
      final biometrics = await BiometricAuth.getAvailableBiometrics();
      if (biometrics.isNotEmpty) {
        type.value = BiometricAuth.getBiometricTypeName(biometrics.first);
      }

      if (email != null && email.trim().isNotEmpty) {
        enabled.value = await biometricPreferenceService.isEnabledForEmail(email);
      } else {
        enabled.value = false;
      }
    }
  }

  Future<void> _loadCacheEncryptionSetting(ValueNotifier<bool?> enabled) async {
    final encryption = CacheEncryptionService();
    await encryption.initialize();
    enabled.value = await encryption.isEncryptionEnabled();
  }

  Future<void> _loadPolieSerifPreference(ValueNotifier<bool> value) async {
    final prefs = await SharedPreferences.getInstance();
    final useSerif = prefs.getBool('polie_serif_language_text') ?? false;
    value.value = useSerif;
    PolieTypography.setUseSerifForLanguageText(useSerif);
  }

  void _showSyncSettings(BuildContext context, WidgetRef ref) async {
    final selectiveSync = SelectiveSyncService();
    await selectiveSync.initialize();
    final preferences = await selectiveSync.getAllPreferences();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(PanAfricanRadius.xl),
            ),
          ),
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: PanAfricanColors.neutralLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              Text(
                'Sync Settings',
                style: PanAfricanTypography.titleLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              ...preferences.entries.map((entry) {
                return SwitchListTile(
                  title: Text(
                    _getCategoryName(entry.key),
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                  subtitle: Text(
                    'Sync ${_getCategoryName(entry.key).toLowerCase()} data',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                  value: entry.value.enabled,
                  activeColor: PanAfricanColors.primary,
                  onChanged: (value) async {
                    HapticFeedback.selectionClick();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          ),
          title: Text(
            'Cache Management',
            style: PanAfricanTypography.titleLarge(context),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CacheStatRow(
                label: 'Total Files',
                value: '${stats['fileCount'] ?? 0}',
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              _CacheStatRow(
                label: 'Total Size',
                value: stats['formattedSize'] ?? '0 B',
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              _CacheStatRow(
                label: 'Pending Sync',
                value: '${stats['queueSize'] ?? 0} operations',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Text(
                'Close',
                style: PanAfricanTypography.labelLarge(context),
              ),
            ),
            TextButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await offlineService.clearCache(null);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  showLingAfriqSuccess(context, 'Cache cleared');
                }
              },
              child: Text(
                'Clear Cache',
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: PanAfricanColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStudyReminderSettings(BuildContext context, WidgetRef ref) {
    final state = ref.read(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var streakEnabled = state.streakRemindersEnabled;
        var dailyEnabled = state.dailyGoalRemindersEnabled;
        var timeOfDay =
            TimeOfDay(hour: state.reminderTime.hour, minute: state.reminderTime.minute);

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color:
                    isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(PanAfricanRadius.xl),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: PanAfricanSpacing.md,
                    right: PanAfricanSpacing.md,
                    top: PanAfricanSpacing.md,
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        PanAfricanSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: PanAfricanColors.neutralLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Study Reminders',
                              style: PanAfricanTypography.titleLarge(context),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: PanAfricanSpacing.md),
                      SwitchListTile(
                        title: Text(
                          'Daily goal reminder',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        subtitle: Text(
                          'Get a daily nudge to hit your learning goal',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        value: dailyEnabled,
                        activeColor: PanAfricanColors.primary,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => dailyEnabled = v);
                          notifier.toggleDailyGoalReminders(v);
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          'Streak reminder',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        subtitle: Text(
                          'Get a reminder to keep your streak alive',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        value: streakEnabled,
                        activeColor: PanAfricanColors.primary,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => streakEnabled = v);
                          notifier.toggleStreakReminders(v);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.schedule_rounded,
                          color: PanAfricanColors.primary,
                        ),
                        title: Text(
                          'Reminder time',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        subtitle: Text(
                          timeOfDay.format(context),
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: PanAfricanColors.neutralMedium,
                        ),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: timeOfDay,
                          );
                          if (picked == null) return;
                          setState(() => timeOfDay = picked);
                          notifier.updateReminderTime(
                              Time(picked.hour, picked.minute));
                        },
                      ),
                      SizedBox(height: PanAfricanSpacing.md),
                    ],
                  ),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          ),
          title: Text(
            'Log Out',
            style: PanAfricanTypography.titleLarge(dialogContext),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: PanAfricanTypography.bodyMedium(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: PanAfricanTypography.labelLarge(dialogContext),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(dialogContext);
                ref.read(authProvider.notifier).signOut();
              },
              child: Text(
                'Log Out',
                style: PanAfricanTypography.labelLarge(dialogContext).copyWith(
                  color: PanAfricanColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;
  final bool? toggleValue;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
    this.toggleValue,
  });

  @override
  Widget build(BuildContext context) {
    String semanticLabel;
    if (toggleValue != null) {
      semanticLabel = '$title, currently ${toggleValue! ? 'on' : 'off'}';
    } else if (subtitle != null) {
      semanticLabel = '$title. $subtitle';
    } else {
      semanticLabel = title;
    }
    final isButton = onTap != null;
    return Semantics(
      label: semanticLabel,
      button: isButton,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.sm,
            vertical: PanAfricanSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: PanAfricanColors.primary,
                size: 24.sp,
                semanticLabel: title,
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
            if (trailing != null) trailing!,
            ],
          ),
        ),
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

class _CacheStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _CacheStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: PanAfricanTypography.bodyMedium(context),
        ),
        Text(
          value,
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Log out',
      button: true,
      child: Material(
        color: PanAfricanColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 20.sp,
                color: PanAfricanColors.error,
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Text(
                'Log Out',
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  color: PanAfricanColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
