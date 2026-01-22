import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'placement_test_screen.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/providers/backend_sync_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Enhanced 9-Step Onboarding Flow with Beautiful Material 3 + Pan-African Design
class EnhancedOnboardingFlowScreen extends HookConsumerWidget {
  const EnhancedOnboardingFlowScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentStep = useState(0);
    final onboardingData = useState<Map<String, dynamic>>({});

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = [
      _Step1ProficiencyLanguage(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step2LearningLanguage(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step3AgeCategory(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step4LearningReasons(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step5PrimaryGoal(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step6LearningStyle(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step7PacePreference(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step8AppTone(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step9SchedulePreferences(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step10ProfileSetup(
        onboardingData: onboardingData.value,
        onComplete: () async {
          await _completeOnboarding(onboardingData.value);
          Navigator.pushReplacement(
            context,
            SmoothPageRoute(child: const TabsView()),
          );
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(context, currentStep.value, steps.length, isDark),
              
              // Step Content
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    currentStep.value = index;
                    HapticFeedback.lightImpact();
                  },
                  itemCount: steps.length,
                  itemBuilder: (context, index) => steps[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    int currentStep,
    int totalSteps,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: PanAfricanTypography.labelMedium(context)
                    .copyWith(color: Colors.white),
              ),
              Text(
                '${((currentStep + 1) / totalSteps * 100).toInt()}%',
                style: PanAfricanTypography.labelMedium(context)
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4.h,
          ),
        ],
      ),
    );
  }

  void _goToNext(PageController controller, ValueNotifier<int> currentStep) {
    currentStep.value++;
    controller.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Helper function to save onboarding data with offline support
  static Future<void> _saveOnboardingDataOffline(
    String key,
    dynamic value,
    Map<String, dynamic>? apiData,
    String? apiEndpoint,
  ) async {
    // Always save locally first
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.cast<String>());
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is Map) {
        await prefs.setString(key, value.toString());
      }
    } catch (e) {
      logger.error('Error saving $key locally', error: e);
    }

    // Try to sync with backend, but don't block if it fails
    if (apiEndpoint != null && apiData != null) {
      try {
        await ApiService.post(
          apiEndpoint,
          data: apiData,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Backend sync timeout');
          },
        );
      } catch (e) {
        // Log but continue - user can proceed even if backend is unavailable
        logger.warn('Backend sync failed for $key, continuing locally', error: e);
      }
    }
  }

  Future<void> _completeOnboarding(Map<String, dynamic> data) async {
    // Save all onboarding data locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_complete', 'true');
      await prefs.setString('onboarding_data', data.toString());
    } catch (e) {
      logger.error('Error saving onboarding completion locally', error: e);
    }

    // Try to sync with backend, but don't block if it fails
    try {
      await ApiService.post(
        '/onboarding/complete',
        data: data,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Backend sync timeout');
        },
      );
    } catch (e) {
      // Log but continue - user can proceed even if backend is unavailable
      logger.warn('Backend sync failed for onboarding completion, continuing locally', error: e);
    }
  }
}

// Step 1: Proficiency Language
class _Step1ProficiencyLanguage extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _Step1ProficiencyLanguage({required this.onNext});

  // Comprehensive language list: Major languages with flags + all African languages
  static List<Map<String, String>> get _majorLanguages => [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'category': 'major'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷', 'category': 'major'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹', 'category': 'major'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸', 'category': 'major'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'category': 'major'},
    {'code': 'yo', 'name': 'Yoruba', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'ha', 'name': 'Hausa', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'ig', 'name': 'Igbo', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'sw', 'name': 'Swahili', 'flag': '🇰🇪', 'category': 'african'},
    {'code': 'zu', 'name': 'Zulu', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'xh', 'name': 'Xhosa', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹', 'category': 'african'},
    {'code': 'pcm', 'name': 'Nigerian Pidgin', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'wo', 'name': 'Wolof', 'flag': '🇸🇳', 'category': 'african'},
    {'code': 'so', 'name': 'Somali', 'flag': '🇸🇴', 'category': 'african'},
    {'code': 'tw', 'name': 'Twi', 'flag': '🇬🇭', 'category': 'african'},
    {'code': 'af', 'name': 'Afrikaans', 'flag': '🇿🇦', 'category': 'african'},
  ];

  static List<Map<String, String>> get _allAfricanLanguages => [
    // West African
    {'code': 'yo', 'name': 'Yoruba', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'ha', 'name': 'Hausa', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'ig', 'name': 'Igbo', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'pcm', 'name': 'Nigerian Pidgin', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'wo', 'name': 'Wolof', 'flag': '🇸🇳', 'category': 'african'},
    {'code': 'tw', 'name': 'Twi', 'flag': '🇬🇭', 'category': 'african'},
    {'code': 'ff', 'name': 'Fulfulde', 'flag': '🇳🇬', 'category': 'african'},
    {'code': 'bm', 'name': 'Bambara', 'flag': '🇲🇱', 'category': 'african'},
    {'code': 'ak', 'name': 'Akan', 'flag': '🇬🇭', 'category': 'african'},
    {'code': 'ee', 'name': 'Ewe', 'flag': '🇬🇭', 'category': 'african'},
    {'code': 'fon', 'name': 'Fon', 'flag': '🇧🇯', 'category': 'african'},
    {'code': 'kik', 'name': 'Kikuyu', 'flag': '🇰🇪', 'category': 'african'},
    {'code': 'luo', 'name': 'Luo', 'flag': '🇰🇪', 'category': 'african'},
    {'code': 'lug', 'name': 'Luganda', 'flag': '🇺🇬', 'category': 'african'},
    {'code': 'rw', 'name': 'Kinyarwanda', 'flag': '🇷🇼', 'category': 'african'},
    {'code': 'rn', 'name': 'Kirundi', 'flag': '🇧🇮', 'category': 'african'},
    // East African
    {'code': 'sw', 'name': 'Swahili', 'flag': '🇰🇪', 'category': 'african'},
    {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹', 'category': 'african'},
    {'code': 'ti', 'name': 'Tigrinya', 'flag': '🇪🇷', 'category': 'african'},
    {'code': 'om', 'name': 'Oromo', 'flag': '🇪🇹', 'category': 'african'},
    {'code': 'so', 'name': 'Somali', 'flag': '🇸🇴', 'category': 'african'},
    // Southern African
    {'code': 'zu', 'name': 'Zulu', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'xh', 'name': 'Xhosa', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'af', 'name': 'Afrikaans', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'st', 'name': 'Sesotho', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'tn', 'name': 'Setswana', 'flag': '🇧🇼', 'category': 'african'},
    {'code': 've', 'name': 'Venda', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'ts', 'name': 'Tsonga', 'flag': '🇿🇦', 'category': 'african'},
    {'code': 'ss', 'name': 'Swati', 'flag': '🇸🇿', 'category': 'african'},
    {'code': 'nr', 'name': 'Ndebele', 'flag': '🇿🇼', 'category': 'african'},
    {'code': 'ny', 'name': 'Chichewa', 'flag': '🇲🇼', 'category': 'african'},
    // Central African
    {'code': 'ln', 'name': 'Lingala', 'flag': '🇨🇩', 'category': 'african'},
    {'code': 'kg', 'name': 'Kongo', 'flag': '🇨🇩', 'category': 'african'},
    {'code': 'sg', 'name': 'Sango', 'flag': '🇨🇫', 'category': 'african'},
    // North African
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇪🇬', 'category': 'african'},
    {'code': 'ber', 'name': 'Berber', 'flag': '🇲🇦', 'category': 'african'},
  ];

  static List<Map<String, String>> get _otherForeignLanguages => [
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪', 'category': 'foreign'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹', 'category': 'foreign'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳', 'category': 'foreign'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵', 'category': 'foreign'},
    {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷', 'category': 'foreign'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳', 'category': 'foreign'},
    {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺', 'category': 'foreign'},
    {'code': 'tr', 'name': 'Turkish', 'flag': '🇹🇷', 'category': 'foreign'},
    {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱', 'category': 'foreign'},
    {'code': 'pl', 'name': 'Polish', 'flag': '🇵🇱', 'category': 'foreign'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);
    final showOtherLanguages = useState(false);
    final searchQuery = useState('');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Combine all languages for search
    final allLanguages = [
      ..._majorLanguages,
      ..._allAfricanLanguages.where((lang) => 
        !_majorLanguages.any((m) => m['code'] == lang['code'])
      ),
      ..._otherForeignLanguages,
    ];

    // Filter languages based on search
    final filteredLanguages = searchQuery.value.isEmpty
        ? allLanguages
        : allLanguages.where((lang) =>
            lang['name']!.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            lang['code']!.toLowerCase().contains(searchQuery.value.toLowerCase())
          ).toList();

    Future<void> saveAndNext() async {
      if (selectedLanguage.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a language')),
        );
        return;
      }

      // Set the language in DynamicLocalizationService immediately
      try {
        await DynamicLocalizationService.setLanguage(selectedLanguage.value!);
      } catch (e) {
        // Log but don't block - translation will work on next app restart
        logger.error('Error setting language', error: e);
      }

      // Save to local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('proficiency_language', selectedLanguage.value!);
      } catch (e) {
        logger.error('Error saving language preference', error: e);
      }

      // Queue sync with backend (will retry automatically)
      try {
        final syncProvider = ref.read(backendSyncProvider.notifier);
        await syncProvider.queueSync(SyncTask(
          type: SyncType.onboarding,
          data: {
            'step': 'proficiency_language',
            'proficiency_language': selectedLanguage.value,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        // Also try immediate sync (non-blocking)
        try {
          await ApiService.post(
            '/onboarding/proficiency-language',
            data: {'proficiency_language': selectedLanguage.value},
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('Backend sync timeout');
            },
          );
        } catch (e) {
          // Silent fail - already queued for retry
          logger.debug('Immediate sync failed, will retry via queue', error: e);
        }
      } catch (e) {
        // Log but continue - user can proceed even if backend is unavailable
        logger.warn('Failed to queue sync for proficiency language, continuing locally', error: e);
      }

      // Always proceed to next step
      onNext({'proficiency_language': selectedLanguage.value});
    }

    return _OnboardingStepTemplate(
      title: 'What language do you speak?',
      description: 'We\'ll translate all in-app content to this language',
      isDark: isDark,
      child: Column(
        children: [
          // Major languages grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Languages',
                  style: PanAfricanTypography.titleMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                children: [
                  // Major languages grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: PanAfricanSpacing.md,
                      mainAxisSpacing: PanAfricanSpacing.md,
                    ),
                    itemCount: _majorLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = _majorLanguages[index];
                      final isSelected = selectedLanguage.value == lang['code'];

                      return GestureDetector(
                        onTap: () {
                          selectedLanguage.value = lang['code'];
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? PanAfricanColors.primary
                                : (isDark
                                    ? PanAfricanColors.cardDark
                                    : PanAfricanColors.cardLight),
                            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                            border: Border.all(
                              color: isSelected
                                  ? PanAfricanColors.secondary
                                  : PanAfricanColors.borderLight,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(lang['flag'] ?? '🌍', style: TextStyle(fontSize: 48.sp)),
                              SizedBox(height: PanAfricanSpacing.sm),
                              Text(
                                lang['name'] ?? '',
                                style: PanAfricanTypography.titleMedium(context).copyWith(
                                  color: isSelected ? Colors.white : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  
                  // "Other Languages" button
                  if (!showOtherLanguages.value)
                    OutlinedButton.icon(
                      onPressed: () => showOtherLanguages.value = true,
                      icon: Icon(Icons.language),
                      label: Text('Show All Languages (${allLanguages.length - _majorLanguages.length} more)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50.h),
                      ),
                    ),
                  
                  // Other languages section
                  if (showOtherLanguages.value) ...[
                    SizedBox(height: PanAfricanSpacing.md),
                    Text(
                      'All Languages',
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    
                    // Search field
                    TextField(
                      onChanged: (value) => searchQuery.value = value,
                      decoration: InputDecoration(
                        hintText: 'Search languages...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? PanAfricanColors.surfaceContainerDark
                            : PanAfricanColors.surfaceContainerLight,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    
                    // Language list
                    ...filteredLanguages.map((lang) {
                      final isSelected = selectedLanguage.value == lang['code'];
                      final isMajor = _majorLanguages.any((m) => m['code'] == lang['code']);
                      
                      if (isMajor) return SizedBox.shrink(); // Skip major languages already shown
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                        color: isSelected
                            ? PanAfricanColors.primary
                            : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                        child: ListTile(
                          leading: Text(lang['flag'] ?? '🌍', style: TextStyle(fontSize: 24.sp)),
                          title: Text(
                            lang['name'] ?? '',
                            style: PanAfricanTypography.bodyLarge(context).copyWith(
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.white)
                              : null,
                          onTap: () {
                            selectedLanguage.value = lang['code'];
                            HapticFeedback.mediumImpact();
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: selectedLanguage.value != null ? saveAndNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                disabledBackgroundColor: PanAfricanColors.borderLight,
              ),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: Learning Language (triggers placement test)
class _Step2LearningLanguage extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _Step2LearningLanguage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      {'code': 'yoruba', 'name': 'Yoruba', 'flag': '🇳🇬'},
      {'code': 'hausa', 'name': 'Hausa', 'flag': '🇳🇬'},
      {'code': 'igbo', 'name': 'Igbo', 'flag': '🇳🇬'},
      {'code': 'pidgin', 'name': 'Nigerian Pidgin English', 'flag': '🇳🇬'},
      {'code': 'swahili', 'name': 'Swahili', 'flag': '🇰🇪'},
      {'code': 'zulu', 'name': 'Zulu', 'flag': '🇿🇦'},
      {'code': 'xhosa', 'name': 'Xhosa', 'flag': '🇿🇦'},
    ];

    Future<void> saveAndNext() async {
      if (selectedLanguage.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a language')),
        );
        return;
      }

      // Save to local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('learning_language', selectedLanguage.value!);
      } catch (e) {
        logger.error('Error saving learning language preference', error: e);
      }

      // Queue sync with backend (will retry automatically)
      try {
        final syncProvider = ref.read(backendSyncProvider.notifier);
        await syncProvider.queueSync(SyncTask(
          type: SyncType.onboarding,
          data: {
            'step': 'learning_language',
            'learning_language': selectedLanguage.value,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        // Also try immediate sync (non-blocking)
        try {
          await ApiService.post(
            '/onboarding/learning-language',
            data: {'learning_language': selectedLanguage.value},
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Backend sync timeout'),
          );
        } catch (e) {
          // Silent fail - already queued for retry
          logger.debug('Immediate sync failed, will retry via queue', error: e);
        }
      } catch (e) {
        logger.warn('Failed to queue sync for learning language, continuing locally', error: e);
      }

      // Always proceed to next step
      onNext({'learning_language': selectedLanguage.value});

      // Navigate to placement test (optional - can be skipped if backend unavailable)
      // Only show placement test if we have internet connection
      if (context.mounted) {
        try {
          // Check connectivity before showing placement test
          // If backend is unavailable, skip placement test and continue
          final hasConnection = await Connectivity().checkConnectivity();
          if (hasConnection != ConnectivityResult.none) {
            Navigator.push(
              context,
              SmoothPageRoute(
                child: PlacementTestScreen(
                  language: selectedLanguage.value!,
                ),
              ),
            ).catchError((e) {
              logger.warn('Placement test navigation failed, continuing without it', error: e);
            });
          } else {
            logger.info('No internet connection, skipping placement test');
          }
        } catch (e) {
          logger.warn('Error checking connectivity for placement test, continuing without it', error: e);
          // Continue to next step if placement test fails
        }
      }
    }

    return _OnboardingStepTemplate(
      title: 'What language do you wish to learn first?',
      description: 'This will trigger your placement test',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: PanAfricanSpacing.md,
                mainAxisSpacing: PanAfricanSpacing.md,
              ),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguage.value == lang['code'];

                return GestureDetector(
                  onTap: () {
                    selectedLanguage.value = lang['code'];
                    HapticFeedback.mediumImpact();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? PanAfricanGradients.sunset
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? PanAfricanColors.cardDark
                              : PanAfricanColors.cardLight),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? PanAfricanColors.secondary
                            : PanAfricanColors.borderLight,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang['flag'] ?? '🌍', style: TextStyle(fontSize: 48.sp)),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Text(
                          lang['name'] ?? '',
                          style: PanAfricanTypography.titleMedium(context).copyWith(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified step templates for remaining steps
class _Step3AgeCategory extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _Step3AgeCategory({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = ['child', 'teen', 'adult', 'senior'];

    return _OnboardingStepTemplate(
      title: 'What\'s your age category?',
      description: 'This helps us personalize your experience',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        options,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          
          // Save locally first
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('onboarding_age_category', selected.value!);
          } catch (e) {
            logger.error('Error saving age category locally', error: e);
          }

          // Queue sync with backend (will retry automatically)
          try {
            final syncProvider = ref.read(backendSyncProvider.notifier);
            await syncProvider.queueSync(SyncTask(
              type: SyncType.onboarding,
              data: {
                'step': 'age_category',
                'age_category': selected.value,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ));
            // Also try immediate sync (non-blocking)
            try {
              await ApiService.post(
                '/onboarding/age-category',
                data: {'age_category': selected.value},
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw TimeoutException('Backend sync timeout'),
              );
            } catch (e) {
              logger.debug('Immediate sync failed, will retry via queue', error: e);
            }
          } catch (e) {
            logger.warn('Failed to queue sync for age category, continuing locally', error: e);
          }

          // Always proceed
          onNext({'age_category': selected.value});
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

// Similar simplified templates for steps 4-9
class _Step4LearningReasons extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step4LearningReasons({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<Set<String>>({});
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = ['heritage', 'travel', 'school', 'business', 'curiosity', 'family', 'culture'];

    return _OnboardingStepTemplate(
      title: 'Why are you learning?',
      description: 'Select all that apply',
      isDark: isDark,
      child: _buildMultiSelect(
        context,
        reasons,
        selected.value,
        (value) {
          final newSet = Set<String>.from(selected.value);
          if (newSet.contains(value)) {
            newSet.remove(value);
          } else {
            newSet.add(value);
          }
          selected.value = newSet;
        },
        isDark,
        () async {
          if (selected.value.isEmpty) return;
          
          // Save locally first
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('onboarding_learning_reasons', selected.value.toList());
          } catch (e) {
            logger.error('Error saving learning reasons locally', error: e);
          }

          // Queue sync with backend (will retry automatically)
          try {
            final syncProvider = ref.read(backendSyncProvider.notifier);
            await syncProvider.queueSync(SyncTask(
              type: SyncType.onboarding,
              data: {
                'step': 'learning_reasons',
                'learning_reasons': selected.value.toList(),
                'timestamp': DateTime.now().toIso8601String(),
              },
            ));
            // Also try immediate sync (non-blocking)
            try {
              await ApiService.post(
                '/onboarding/learning-reasons',
                data: {'learning_reasons': selected.value.toList()},
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw TimeoutException('Backend sync timeout'),
              );
            } catch (e) {
              logger.debug('Immediate sync failed, will retry via queue', error: e);
            }
          } catch (e) {
            logger.warn('Failed to queue sync for learning reasons, continuing locally', error: e);
          }

          // Always proceed
          onNext({'learning_reasons': selected.value.toList()});
        },
      ),
    );
  }

  Widget _buildMultiSelect(
    BuildContext context,
    List<String> options,
    Set<String> selected,
    Function(String) onToggle,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected.contains(option);

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primaryContainer
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: CheckboxListTile(
                  title: Text(option.toUpperCase()),
                  value: isSelected,
                  onChanged: (_) {
                    onToggle(option);
                    HapticFeedback.lightImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected.isNotEmpty ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

// Steps 5-9 follow similar pattern - creating simplified versions
class _Step5PrimaryGoal extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step5PrimaryGoal({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = ['travel', 'heritage', 'business', 'academic', 'confidence', 'brain_training', 'culture'];

    return _OnboardingStepTemplate(
      title: 'What\'s your primary goal?',
      description: 'Choose your main learning objective',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        goals,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          
          // Save locally first
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('onboarding_primary_goal', selected.value!);
          } catch (e) {
            logger.error('Error saving primary goal locally', error: e);
          }

          // Queue sync with backend (will retry automatically)
          try {
            final syncProvider = ref.read(backendSyncProvider.notifier);
            await syncProvider.queueSync(SyncTask(
              type: SyncType.onboarding,
              data: {
                'step': 'primary_goal',
                'primary_goal': selected.value,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ));
            // Also try immediate sync (non-blocking)
            try {
              await ApiService.post(
                '/onboarding/primary-goal',
                data: {'primary_goal': selected.value},
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw TimeoutException('Backend sync timeout'),
              );
            } catch (e) {
              logger.debug('Immediate sync failed, will retry via queue', error: e);
            }
          } catch (e) {
            logger.warn('Failed to queue sync for primary goal, continuing locally', error: e);
          }

          // Always proceed
          onNext({'primary_goal': selected.value});
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.replaceAll('_', ' ').toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step6LearningStyle extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step6LearningStyle({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styles = ['audio', 'visual', 'stories', 'drills', 'conversation', 'mixed'];

    return _OnboardingStepTemplate(
      title: 'How do you learn best?',
      description: 'Select your preferred learning style',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        styles,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          
          // Save locally first
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('onboarding_learning_style', selected.value!);
          } catch (e) {
            logger.error('Error saving learning style locally', error: e);
          }

          // Queue sync with backend (will retry automatically)
          try {
            final syncProvider = ref.read(backendSyncProvider.notifier);
            await syncProvider.queueSync(SyncTask(
              type: SyncType.onboarding,
              data: {
                'step': 'learning_style',
                'learning_style': selected.value,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ));
            // Also try immediate sync (non-blocking)
            try {
              await ApiService.post(
                '/onboarding/learning-style',
                data: {'learning_style': selected.value},
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw TimeoutException('Backend sync timeout'),
              );
            } catch (e) {
              logger.debug('Immediate sync failed, will retry via queue', error: e);
            }
          } catch (e) {
            logger.warn('Failed to queue sync for learning style, continuing locally', error: e);
          }

          // Always proceed
          onNext({'learning_style': selected.value});
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step7PacePreference extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step7PacePreference({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paces = ['slow', 'steady', 'fast', 'surprise'];

    return _OnboardingStepTemplate(
      title: 'What pace do you prefer?',
      description: 'How fast do you want to learn?',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        paces,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          
          // Save locally first
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('onboarding_pace_preference', selected.value!);
          } catch (e) {
            logger.error('Error saving pace preference locally', error: e);
          }

          // Queue sync with backend (will retry automatically)
          try {
            final syncProvider = ref.read(backendSyncProvider.notifier);
            await syncProvider.queueSync(SyncTask(
              type: SyncType.onboarding,
              data: {
                'step': 'pace_preference',
                'pace_preference': selected.value,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ));
            // Also try immediate sync (non-blocking)
            try {
              await ApiService.post(
                '/onboarding/pace-preference',
                data: {'pace_preference': selected.value},
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw TimeoutException('Backend sync timeout'),
              );
            } catch (e) {
              logger.debug('Immediate sync failed, will retry via queue', error: e);
            }
          } catch (e) {
            logger.warn('Failed to queue sync for pace preference, continuing locally', error: e);
          }

          // Always proceed
          onNext({'pace_preference': selected.value});
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step8AppTone extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step8AppTone({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tones = ['playful', 'encouraging', 'serious', 'friendly'];

    return _OnboardingStepTemplate(
      title: 'What tone do you prefer?',
      description: 'How should Polie communicate with you?',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        tones,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          
          // Save locally first
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('onboarding_app_tone', selected.value!);
          } catch (e) {
            logger.error('Error saving app tone locally', error: e);
          }

          // Queue sync with backend (will retry automatically)
          try {
            final syncProvider = ref.read(backendSyncProvider.notifier);
            await syncProvider.queueSync(SyncTask(
              type: SyncType.onboarding,
              data: {
                'step': 'app_tone',
                'app_tone': selected.value,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ));
            // Also try immediate sync (non-blocking)
            try {
              await ApiService.post(
                '/onboarding/app-tone',
                data: {'app_tone': selected.value},
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw TimeoutException('Backend sync timeout'),
              );
            } catch (e) {
              logger.debug('Immediate sync failed, will retry via queue', error: e);
            }
          } catch (e) {
            logger.warn('Failed to queue sync for app tone, continuing locally', error: e);
          }

          // Always proceed
          onNext({'app_tone': selected.value});
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step9SchedulePreferences extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step9SchedulePreferences({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = useState(15);
    final timeOfDay = useState<String?>(null);
    final remindersEnabled = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final times = ['sunrise', 'midday', 'sunset', 'night'];

    return _OnboardingStepTemplate(
      title: 'Set your learning schedule',
      description: 'When and how long do you want to learn?',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Duration (minutes)',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Slider(
                    value: duration.value.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${duration.value} minutes',
                    onChanged: (value) => duration.value = value.toInt(),
                  ),
                  Text(
                    '${duration.value} minutes per day',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),
                  Text(
                    'Preferred Time of Day',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  ...times.map((time) {
                    final isSelected = timeOfDay.value == time;
                    return Card(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      color: isSelected
                          ? PanAfricanColors.primary
                          : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                      child: ListTile(
                        title: Text(
                          time.toUpperCase(),
                          style: PanAfricanTypography.titleMedium(context).copyWith(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.white)
                            : null,
                        onTap: () {
                          timeOfDay.value = time;
                          HapticFeedback.mediumImpact();
                        },
                      ),
                    );
                  }),
                  SizedBox(height: PanAfricanSpacing.md),
                  SwitchListTile(
                    title: Text('Enable Reminders'),
                    value: remindersEnabled.value,
                    onChanged: (value) => remindersEnabled.value = value,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: timeOfDay.value != null
                  ? () async {
                      // Save locally first
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('onboarding_daily_duration', duration.value);
                        await prefs.setString('onboarding_time_of_day', timeOfDay.value!);
                        await prefs.setBool('onboarding_reminders_enabled', remindersEnabled.value);
                      } catch (e) {
                        logger.error('Error saving schedule preferences locally', error: e);
                      }

                      // Queue sync with backend (will retry automatically)
                      try {
                        final syncProvider = ref.read(backendSyncProvider.notifier);
                        await syncProvider.queueSync(SyncTask(
                          type: SyncType.onboarding,
                          data: {
                            'step': 'schedule_preferences',
                            'daily_duration_minutes': duration.value,
                            'preferred_time_of_day': timeOfDay.value,
                            'reminders_enabled': remindersEnabled.value,
                            'timestamp': DateTime.now().toIso8601String(),
                          },
                        ));
                        // Also try immediate sync (non-blocking)
                        try {
                          await ApiService.post(
                            '/onboarding/schedule-preferences',
                            data: {
                              'daily_duration_minutes': duration.value,
                              'preferred_time_of_day': timeOfDay.value,
                              'reminders_enabled': remindersEnabled.value,
                            },
                          ).timeout(
                            const Duration(seconds: 3),
                            onTimeout: () => throw TimeoutException('Backend sync timeout'),
                          );
                        } catch (e) {
                          logger.debug('Immediate sync failed, will retry via queue', error: e);
                        }
                      } catch (e) {
                        logger.warn('Failed to queue sync for schedule preferences, continuing locally', error: e);
                      }

                      // Always proceed
                      onNext({
                        'daily_duration_minutes': duration.value,
                        'preferred_time_of_day': timeOfDay.value,
                        'reminders_enabled': remindersEnabled.value,
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step10ProfileSetup extends HookConsumerWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onComplete;

  const _Step10ProfileSetup({
    required this.onboardingData,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _OnboardingStepTemplate(
      title: 'Complete Your Profile',
      description: 'Set your username and avatar',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                children: [
                  // Avatar Selection
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: PanAfricanColors.primary,
                    child: Icon(Icons.person, size: 60.sp, color: Colors.white),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  TextButton(
                    onPressed: () {
                      // Avatar picker
                    },
                    child: Text('Change Avatar'),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Username Input
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                    ),
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: usernameController.text.isEmpty
                  ? null
                  : () async {
                      // Save locally first
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('onboarding_username', usernameController.text);
                      } catch (e) {
                        logger.error('Error saving username locally', error: e);
                      }

                      // Queue sync with backend (will retry automatically)
                      try {
                        final syncProvider = ref.read(backendSyncProvider.notifier);
                        await syncProvider.queueSync(SyncTask(
                          type: SyncType.onboarding,
                          data: {
                            'step': 'profile_setup',
                            'username': usernameController.text,
                            'timestamp': DateTime.now().toIso8601String(),
                          },
                        ));
                        // Also try immediate sync (non-blocking)
                        try {
                          await ApiService.post(
                            '/onboarding/profile-setup',
                            data: {'username': usernameController.text},
                          ).timeout(
                            const Duration(seconds: 3),
                            onTimeout: () => throw TimeoutException('Backend sync timeout'),
                          );
                        } catch (e) {
                          logger.debug('Immediate sync failed, will retry via queue', error: e);
                        }
                      } catch (e) {
                        logger.warn('Failed to queue sync for profile setup, continuing locally', error: e);
                      }

                      // Always complete onboarding
                      onComplete();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: Text('Complete Onboarding'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepTemplate extends ConsumerWidget {
  final String title;
  final String description;
  final Widget child;
  final bool isDark;

  const _OnboardingStepTemplate({
    required this.title,
    required this.description,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sync status to show progress indicator
    final syncState = ref.watch(backendSyncProvider);
    final isSyncing = syncState.isSyncing;
    final pendingSyncs = syncState.pendingSyncs;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.headlineMedium(context),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  description,
                  style: PanAfricanTypography.bodyMedium(context),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                // Sync status indicator
                if (isSyncing || pendingSyncs > 0)
                  Padding(
                    padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PanAfricanColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Text(
                          isSyncing 
                              ? 'Syncing...' 
                              : '$pendingSyncs pending sync${pendingSyncs > 1 ? 's' : ''}',
                          style: PanAfricanTypography.bodySmall(context).copyWith(
                            color: PanAfricanColors.primary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

