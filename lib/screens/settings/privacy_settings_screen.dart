import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/services/lens/lens_privacy_policy.dart';
import 'package:lingafriq/screens/settings/data_export_screen.dart';

const String voiceStorageConsentApiPath = '/api/v2/voice-storage';
const String trainingContributionConsentApiPath = '/api/v2/training-contribution';

/// Privacy Settings Screen - Pan-African Design System
class PrivacySettingsScreen extends HookConsumerWidget {
  const PrivacySettingsScreen({super.key});

  static const String _prefAnalytics = 'privacy_analytics_enabled';
  static const String _prefDataSharing = 'privacy_data_sharing_enabled';
  static const String _prefPersonalizedAds = 'privacy_personalized_ads_enabled';
  static const String _prefLocationTracking = 'privacy_location_tracking_enabled';
  static const String _prefProfileVisibility = 'privacy_profile_visibility';
  static const String _prefActivityStatus = 'privacy_activity_status_enabled';
  static const String _prefAgeCategory = 'age_category';
  static const String _prefGuardianVoiceStorage =
      'guardian_voice_storage_consent_recorded';

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> _loadPreference(String key, bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final api = ref.read(apiProvider.notifier);

    final analyticsEnabled = useState<bool?>(null);
    final dataSharingEnabled = useState<bool?>(null);
    final personalizedAdsEnabled = useState<bool?>(null);
    final locationTrackingEnabled = useState<bool?>(null);
    final profileVisibility = useState<String>('public');
    final activityStatusEnabled = useState<bool?>(null);
    final voiceStorageEnabled = useState<bool>(false);
    final voiceConsentVersion = useState<String?>(null);
    final voiceConsentCopy = useState<String?>(null);
    final voiceWithdrawing = useState(false);
    final trainingContributionEnabled = useState<bool>(false);
    final trainingConsentVersion = useState<String?>(null);
    final trainingConsentCopy = useState<String?>(null);
    final trainingOffered = useState<bool>(true);
    final trainingWithdrawing = useState(false);
    final isLoading = useState(true);

    Future<void> loadSettings(ApiProvider api) async {
      // Load from backend first; fall back to local
      final remote = await api.getUserPreferences();
      if (remote != null && remote.isNotEmpty) {
        final a = remote['analytics'] as bool? ?? true;
        final d = remote['data_sharing'] as bool? ?? false;
        final p = remote['personalized_ads'] as bool? ?? false;
        final l = remote['location_tracking'] as bool? ?? false;
        final v = remote['profile_visibility'] as String? ?? 'public';
        final s = remote['activity_status'] as bool? ?? true;
        analyticsEnabled.value = a;
        dataSharingEnabled.value = d;
        personalizedAdsEnabled.value = p;
        locationTrackingEnabled.value = l;
        profileVisibility.value = v;
        activityStatusEnabled.value = s;
        await _savePreference(_prefAnalytics, a);
        await _savePreference(_prefDataSharing, d);
        await _savePreference(_prefPersonalizedAds, p);
        await _savePreference(_prefLocationTracking, l);
        await _savePreference(_prefActivityStatus, s);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefProfileVisibility, v);
      } else {
        analyticsEnabled.value = await _loadPreference(_prefAnalytics, true);
        dataSharingEnabled.value = await _loadPreference(_prefDataSharing, false);
        personalizedAdsEnabled.value =
            await _loadPreference(_prefPersonalizedAds, false);
        locationTrackingEnabled.value =
            await _loadPreference(_prefLocationTracking, false);
        activityStatusEnabled.value =
            await _loadPreference(_prefActivityStatus, true);
        final prefs = await SharedPreferences.getInstance();
        profileVisibility.value =
            prefs.getString(_prefProfileVisibility) ?? 'public';
      }
      try {
        final voiceRes = await ApiService.get('$voiceStorageConsentApiPath/status');
        final voiceData = voiceRes.data;
        if (voiceData is Map) {
          final consent = voiceData['consent'];
          if (consent is Map) {
            voiceStorageEnabled.value = consent['store_enabled'] == true;
          }
          voiceConsentVersion.value =
              voiceData['consent_text_version'] as String?;
          voiceConsentCopy.value = voiceData['consent_copy'] as String?;
        }
      } catch (_) {
        // Offline — default remains off (delete-after-scoring).
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        final ageCategory = prefs.getString(_prefAgeCategory) ??
            prefs.getString('onboarding_age_category');
        final privacyCtx = lensPrivacyContextFromPrefs(ageCategory: ageCategory);
        final trainingRes = await ApiService.get(
          trainingContributionConsentApiPath + '/status',
        );
        final trainingData = trainingRes.data;
        if (trainingData is Map) {
          final consent = trainingData['consent'];
          if (consent is Map) {
            trainingContributionEnabled.value =
                consent['contribute_enabled'] == true;
          }
          trainingConsentVersion.value =
              trainingData['consent_text_version'] as String?;
          trainingConsentCopy.value = trainingData['consent_copy'] as String?;
          final offered = trainingData['offered_to_learner'];
          trainingOffered.value =
              offered != false && !privacyCtx.isMinor;
        }
      } catch (_) {
        trainingOffered.value = false;
      }
      isLoading.value = false;
    }

    Future<bool> guardianVoiceStorageApproved(BuildContext context) async {
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Guardian approval needed'),
          content: const Text(
            'Learners under 18 need a parent or guardian to approve storing practice recordings. '
            'Only turn this on if your guardian has agreed in the Family hub.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardian approved'),
            ),
          ],
        ),
      );
      if (approved == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefGuardianVoiceStorage, true);
      }
      return approved == true;
    }

    Future<void> updateTrainingContribution(bool value, BuildContext context) async {
      HapticFeedback.selectionClick();
      if (!trainingOffered.value) return;
      if (!voiceStorageEnabled.value && value) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Turn on practice recording storage first, then you can choose to help train our speech models.',
              ),
            ),
          );
        }
        return;
      }
      if (!value) {
        trainingWithdrawing.value = true;
        try {
          await ApiService.post('$trainingContributionConsentApiPath/withdraw');
          trainingContributionEnabled.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'We removed your clips from future training runs and queued any saved ones for removal.',
                ),
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'We could not update training contribution right now. Try again when you are online.',
                ),
              ),
            );
          }
        } finally {
          trainingWithdrawing.value = false;
        }
        return;
      }

      final version = trainingConsentVersion.value;
      if (version == null || version.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Training contribution settings need a connection. Try again when you are online.',
              ),
            ),
          );
        }
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Help improve speech models?'),
          content: Text(
            trainingConsentCopy.value ??
                'Your stored practice recordings may be used to train speech models. You can turn this off anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('I agree'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        await ApiService.post(
          '$trainingContributionConsentApiPath/opt-in',
          data: {'consent_text_version': version},
        );
        trainingContributionEnabled.value = true;
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not save your choice. Check your connection and try again.',
              ),
            ),
          );
        }
      }
    }

    Future<void> updateVoiceStorage(bool value, BuildContext context) async {
      HapticFeedback.selectionClick();
      if (!value) {
        voiceWithdrawing.value = true;
        try {
          await ApiService.post('$voiceStorageConsentApiPath/withdraw');
          voiceStorageEnabled.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'We turned off recording storage. Any saved clips will be removed within 30 days.',
                ),
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'We could not update voice storage right now. Try again when you are online.',
                ),
              ),
            );
          }
        } finally {
          voiceWithdrawing.value = false;
        }
        if (trainingContributionEnabled.value) {
          await updateTrainingContribution(false, context);
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final ageCategory = prefs.getString(_prefAgeCategory) ??
          prefs.getString('onboarding_age_category');
      final privacyCtx = lensPrivacyContextFromPrefs(
        ageCategory: ageCategory,
        guardianPhotoConsentRecorded:
            prefs.getBool(_prefGuardianVoiceStorage) ?? false,
      );
      if (privacyCtx.isMinor) {
        final ok = await guardianVoiceStorageApproved(context);
        if (!ok) return;
      }

      final version = voiceConsentVersion.value;
      if (version == null || version.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Voice storage settings are not available offline yet. Connect and try again.',
              ),
            ),
          );
        }
        return;
      }

      try {
        await ApiService.post(
          '$voiceStorageConsentApiPath/opt-in',
          data: {
            'consent_text_version': version,
            'guardian_consent_recorded': privacyCtx.isMinor,
          },
        );
        voiceStorageEnabled.value = true;
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not save your choice. Check your connection and try again.',
              ),
            ),
          );
        }
      }
    }

    useEffect(() {
      loadSettings(api);
      return null;
    }, []);

    Future<void> syncToBackend(ApiProvider api) async {
      final prefs = {
        'analytics': analyticsEnabled.value ?? true,
        'data_sharing': dataSharingEnabled.value ?? false,
        'personalized_ads': personalizedAdsEnabled.value ?? false,
        'location_tracking': locationTrackingEnabled.value ?? false,
        'profile_visibility': profileVisibility.value,
        'activity_status': activityStatusEnabled.value ?? true,
      };
      await api.updateUserPreferences(prefs);
    }

    Future<void> updateAnalytics(bool value) async {
      HapticFeedback.selectionClick();
      analyticsEnabled.value = value;
      await _savePreference(_prefAnalytics, value);
      syncToBackend(api);
    }

    Future<void> updateDataSharing(bool value) async {
      HapticFeedback.selectionClick();
      dataSharingEnabled.value = value;
      await _savePreference(_prefDataSharing, value);
      syncToBackend(api);
    }

    Future<void> updatePersonalizedAds(bool value) async {
      HapticFeedback.selectionClick();
      personalizedAdsEnabled.value = value;
      await _savePreference(_prefPersonalizedAds, value);
      syncToBackend(api);
    }

    Future<void> updateLocationTracking(bool value) async {
      HapticFeedback.selectionClick();
      locationTrackingEnabled.value = value;
      await _savePreference(_prefLocationTracking, value);
      syncToBackend(api);
    }

    Future<void> updateActivityStatus(bool value) async {
      HapticFeedback.selectionClick();
      activityStatusEnabled.value = value;
      await _savePreference(_prefActivityStatus, value);
      syncToBackend(api);
    }

    Future<void> updateProfileVisibility(String value) async {
      HapticFeedback.selectionClick();
      profileVisibility.value = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefProfileVisibility, value);
      syncToBackend(api);
    }

    if (isLoading.value) {
      return Scaffold(
        appBar: AppBar(
          leading: Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onPrimary,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          title: Text(
            'Privacy Settings',
            style: PanAfricanTypography.titleLarge(context)
                .copyWith(color: colorScheme.onPrimary),
          ),
          backgroundColor: PanAfricanColors.primary,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: PanAfricanColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Privacy Settings',
          style: PanAfricanTypography.titleLarge(context)
              .copyWith(color: colorScheme.onPrimary),
        ),
        backgroundColor: PanAfricanColors.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.primary.withOpacity(0.05),
                    PanAfricanColors.surfaceLight,
                  ],
                ),
        ),
        child: ResponsiveSafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: PanAfricanSpacing.sm),
                ListTile(
                  title: const Text('Passkeys'),
                  subtitle: const Text('Add or remove a passkey for this account'),
                  onTap: () {
                    Navigator.of(context).pushNamed('/passkey-manage');
                  },
                ),

                // Analytics & Data Collection
                _PrivacySection(
                  title: 'Analytics & Data Collection',
                  isDark: isDark,
                  index: 0,
                  children: [
                    _PrivacySwitchTile(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      subtitle: 'Help us improve the app by sharing usage data',
                      value: analyticsEnabled.value ?? true,
                      onChanged: updateAnalytics,
                      isDark: isDark,
                    ),
                    _PrivacyDivider(isDark: isDark),
                    _PrivacySwitchTile(
                      icon: Icons.share_outlined,
                      title: 'Data Sharing',
                      subtitle: 'Share anonymized data with partners for research',
                      value: dataSharingEnabled.value ?? false,
                      onChanged: updateDataSharing,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Advertising
                _PrivacySection(
                  title: 'Advertising',
                  isDark: isDark,
                  index: 1,
                  children: [
                    _PrivacySwitchTile(
                      icon: Icons.ads_click_outlined,
                      title: 'Personalized Ads',
                      subtitle: 'Show ads based on your interests',
                      value: personalizedAdsEnabled.value ?? false,
                      onChanged: updatePersonalizedAds,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Location & Tracking
                _PrivacySection(
                  title: 'Location & Tracking',
                  isDark: isDark,
                  index: 2,
                  children: [
                    _PrivacySwitchTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location Tracking',
                      subtitle: 'Allow app to access your location',
                      value: locationTrackingEnabled.value ?? false,
                      onChanged: updateLocationTracking,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Profile Visibility
                _PrivacySection(
                  title: 'Profile Visibility',
                  isDark: isDark,
                  index: 3,
                  children: [
                    _PrivacyRadioTile(
                      icon: Icons.public_rounded,
                      title: 'Public',
                      subtitle: 'Anyone can see your profile',
                      value: 'public',
                      groupValue: profileVisibility.value,
                      onChanged: updateProfileVisibility,
                      isDark: isDark,
                    ),
                    _PrivacyDivider(isDark: isDark),
                    _PrivacyRadioTile(
                      icon: Icons.people_outline_rounded,
                      title: 'Friends Only',
                      subtitle: 'Only your friends can see your profile',
                      value: 'friends',
                      groupValue: profileVisibility.value,
                      onChanged: updateProfileVisibility,
                      isDark: isDark,
                    ),
                    _PrivacyDivider(isDark: isDark),
                    _PrivacyRadioTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Private',
                      subtitle: 'Only you can see your profile',
                      value: 'private',
                      groupValue: profileVisibility.value,
                      onChanged: updateProfileVisibility,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Activity Status
                _PrivacySection(
                  title: 'Activity Status',
                  isDark: isDark,
                  index: 4,
                  children: [
                    _PrivacySwitchTile(
                      icon: Icons.circle_outlined,
                      title: 'Show Activity Status',
                      subtitle: "Let others see when you're online",
                      value: activityStatusEnabled.value ?? true,
                      onChanged: updateActivityStatus,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                _PrivacySection(
                  title: 'Practice recordings',
                  isDark: isDark,
                  index: 5,
                  children: [
                    _PrivacySwitchTile(
                      icon: Icons.mic_none_rounded,
                      title: 'Save my practice recordings',
                      subtitle: voiceConsentCopy.value ??
                          'Off by default. We delete audio after scoring unless you turn this on. '
                          'Stored clips are kept up to one year, or removed within 30 days after you turn this off.',
                      value: voiceStorageEnabled.value,
                      onChanged: voiceWithdrawing.value
                          ? (_) {}
                          : (v) => updateVoiceStorage(v, context),
                      isDark: isDark,
                      semanticsLabel:
                          'Save my practice recordings. ${voiceStorageEnabled.value ? 'On' : 'Off'}.',
                    ),
                  ],
                ),
                if (trainingOffered.value && voiceStorageEnabled.value) ...[
                  SizedBox(height: PanAfricanSpacing.lg),
                  _PrivacySection(
                    title: 'Model training',
                    isDark: isDark,
                    index: 6,
                    children: [
                      _PrivacySwitchTile(
                        icon: Icons.model_training_outlined,
                        title: 'Contribute recordings to model training',
                        subtitle: trainingConsentCopy.value ??
                            'Separate from saving recordings. Off by default. Withdraw anytime.',
                        value: trainingContributionEnabled.value,
                        onChanged: trainingWithdrawing.value
                            ? (_) {}
                            : (v) => updateTrainingContribution(v, context),
                        isDark: isDark,
                        semanticsLabel:
                            'Contribute recordings to model training. '
                            '${trainingContributionEnabled.value ? 'On' : 'Off'}.',
                      ),
                    ],
                  ),
                ],
                SizedBox(height: PanAfricanSpacing.lg),

                _PrivacySection(
                  title: 'Your data',
                  isDark: isDark,
                  index: 7,
                  children: [
                    Semantics(
                      label: 'Export my data and delete account',
                      button: true,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.sm,
                          vertical: PanAfricanSpacing.xs,
                        ),
                        leading: Icon(
                          Icons.folder_zip_outlined,
                          color: PanAfricanColors.primary,
                        ),
                        title: Text(
                          'Export my data',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        subtitle: Text(
                          'Download your learning data or delete your account',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? PanAfricanColors.textSecondaryDark
                              : PanAfricanColors.textSecondaryLight,
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DataExportScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Info Card
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(PanAfricanSpacing.sm),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: PanAfricanColors.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.md),
                      Expanded(
                        child: Semantics(
                          label: 'Your privacy is important to us. These settings help you control how your data is used and shared.',
                          child: Text(
                            'Your privacy is important to us. These settings help you control how your data is used and shared.',
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                SizedBox(height: PanAfricanSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;
  final int index;

  const _PrivacySection({
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
          child: Semantics(
            header: true,
            child: Text(
            title,
            style: PanAfricanTypography.titleMedium(context).copyWith(
              color: PanAfricanColors.primary,
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
}

class _PrivacySwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final String? semanticsLabel;

  const _PrivacySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.semanticsLabel,
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
                Text(
                  subtitle,
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ],
            ),
          ),
          Semantics(
            label: semanticsLabel ?? '$title. ${value ? 'On' : 'Off'}.',
            toggled: value,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: PanAfricanColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRadioTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _PrivacyRadioTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Semantics(
      label: '$title. ${isSelected ? 'Selected' : 'Not selected'}.',
      button: true,
      child: InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
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
                color: isSelected
                    ? PanAfricanColors.primary.withOpacity(0.2)
                    : PanAfricanColors.primary.withOpacity(0.1),
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
                  Text(
                    subtitle,
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
              activeColor: PanAfricanColors.primary,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _PrivacyDivider extends StatelessWidget {
  final bool isDark;

  const _PrivacyDivider({required this.isDark});

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
