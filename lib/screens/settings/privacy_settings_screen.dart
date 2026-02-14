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

/// Privacy Settings Screen - Pan-African Design System
class PrivacySettingsScreen extends HookConsumerWidget {
  const PrivacySettingsScreen({super.key});

  static const String _prefAnalytics = 'privacy_analytics_enabled';
  static const String _prefDataSharing = 'privacy_data_sharing_enabled';
  static const String _prefPersonalizedAds = 'privacy_personalized_ads_enabled';
  static const String _prefLocationTracking = 'privacy_location_tracking_enabled';
  static const String _prefProfileVisibility = 'privacy_profile_visibility';
  static const String _prefActivityStatus = 'privacy_activity_status_enabled';

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
      isLoading.value = false;
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
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onPrimary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
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
                        child: Text(
                          'Your privacy is important to us. These settings help you control how your data is used and shared.',
                          style: PanAfricanTypography.bodyMedium(context),
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

  const _PrivacySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                Text(
                  subtitle,
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

    return InkWell(
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
