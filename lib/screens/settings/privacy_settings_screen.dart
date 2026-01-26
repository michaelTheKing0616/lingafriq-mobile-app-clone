import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/providers/api_provider.dart';

/// Privacy Settings Screen - Full production implementation
class PrivacySettingsScreen extends HookConsumerWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

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
        personalizedAdsEnabled.value = await _loadPreference(_prefPersonalizedAds, false);
        locationTrackingEnabled.value = await _loadPreference(_prefLocationTracking, false);
        activityStatusEnabled.value = await _loadPreference(_prefActivityStatus, true);
        final prefs = await SharedPreferences.getInstance();
        profileVisibility.value = prefs.getString(_prefProfileVisibility) ?? 'public';
      }
      isLoading.value = false;
    }

    useEffect(() {
      loadSettings(api);
      return null;
    }, []);

    Future<void> _syncToBackend(ApiProvider api) async {
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

    Future<void> _updateAnalytics(bool value) async {
      analyticsEnabled.value = value;
      await _savePreference(_prefAnalytics, value);
      _syncToBackend(api);
    }

    Future<void> _updateDataSharing(bool value) async {
      dataSharingEnabled.value = value;
      await _savePreference(_prefDataSharing, value);
      _syncToBackend(api);
    }

    Future<void> _updatePersonalizedAds(bool value) async {
      personalizedAdsEnabled.value = value;
      await _savePreference(_prefPersonalizedAds, value);
      _syncToBackend(api);
    }

    Future<void> _updateLocationTracking(bool value) async {
      locationTrackingEnabled.value = value;
      await _savePreference(_prefLocationTracking, value);
      _syncToBackend(api);
    }

    Future<void> _updateActivityStatus(bool value) async {
      activityStatusEnabled.value = value;
      await _savePreference(_prefActivityStatus, value);
      _syncToBackend(api);
    }

    Future<void> _updateProfileVisibility(String value) async {
      profileVisibility.value = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefProfileVisibility, value);
      _syncToBackend(api);
    }

    if (isLoading.value) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Settings'),
          backgroundColor: PanAfricanColors.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: PanAfricanColors.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.h),
                
                // Analytics & Data Collection
                _buildSectionHeader('Analytics & Data Collection'),
                SizedBox(height: 12.h),
                _buildSwitchTile(
                  title: 'Analytics',
                  subtitle: 'Help us improve the app by sharing usage data',
                  value: analyticsEnabled.value ?? true,
                  onChanged: _updateAnalytics,
                  icon: Icons.analytics_outlined,
                ),
                SizedBox(height: 8.h),
                _buildSwitchTile(
                  title: 'Data Sharing',
                  subtitle: 'Share anonymized data with partners for research',
                  value: dataSharingEnabled.value ?? false,
                  onChanged: _updateDataSharing,
                  icon: Icons.share_outlined,
                ),
                
                SizedBox(height: 24.h),
                
                // Advertising
                _buildSectionHeader('Advertising'),
                SizedBox(height: 12.h),
                _buildSwitchTile(
                  title: 'Personalized Ads',
                  subtitle: 'Show ads based on your interests',
                  value: personalizedAdsEnabled.value ?? false,
                  onChanged: _updatePersonalizedAds,
                  icon: Icons.ads_click_outlined,
                ),
                
                SizedBox(height: 24.h),
                
                // Location & Tracking
                _buildSectionHeader('Location & Tracking'),
                SizedBox(height: 12.h),
                _buildSwitchTile(
                  title: 'Location Tracking',
                  subtitle: 'Allow app to access your location',
                  value: locationTrackingEnabled.value ?? false,
                  onChanged: _updateLocationTracking,
                  icon: Icons.location_on_outlined,
                ),
                
                SizedBox(height: 24.h),
                
                // Profile Visibility
                _buildSectionHeader('Profile Visibility'),
                SizedBox(height: 12.h),
                _buildRadioTile(
                  title: 'Public',
                  subtitle: 'Anyone can see your profile',
                  value: 'public',
                  groupValue: profileVisibility.value,
                  onChanged: _updateProfileVisibility,
                  icon: Icons.public,
                ),
                SizedBox(height: 8.h),
                _buildRadioTile(
                  title: 'Friends Only',
                  subtitle: 'Only your friends can see your profile',
                  value: 'friends',
                  groupValue: profileVisibility.value,
                  onChanged: _updateProfileVisibility,
                  icon: Icons.people_outline,
                ),
                SizedBox(height: 8.h),
                _buildRadioTile(
                  title: 'Private',
                  subtitle: 'Only you can see your profile',
                  value: 'private',
                  groupValue: profileVisibility.value,
                  onChanged: _updateProfileVisibility,
                  icon: Icons.lock_outline,
                ),
                
                SizedBox(height: 24.h),
                
                // Activity Status
                _buildSectionHeader('Activity Status'),
                SizedBox(height: 12.h),
                _buildSwitchTile(
                  title: 'Show Activity Status',
                  subtitle: 'Let others see when you\'re online',
                  value: activityStatusEnabled.value ?? true,
                  onChanged: _updateActivityStatus,
                  icon: Icons.circle_outlined,
                ),
                
                SizedBox(height: 32.h),
                
                // Info Card
                Container(
                  padding: EdgeInsets.all(16.sp),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: PanAfricanColors.primary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Your privacy is important to us. These settings help you control how your data is used and shared.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: PanAfricanColors.primary,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: PanAfricanColors.primary),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
    required IconData icon,
  }) {
    return Card(
      child: RadioListTile<String>(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        groupValue: groupValue,
        onChanged: (val) => onChanged(val!),
        secondary: Icon(icon, color: PanAfricanColors.primary),
      ),
    );
  }
}
