import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/backend_sync_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/services/games_learning_language_preload.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'placement_test_screen.dart';

/// Unified Onboarding: "Kijiji cha Lugha" - The Language Village
/// 
/// Combines the best of both worlds:
/// - Story-driven African narrative with cultural characters
/// - Material 3 UI with Pan-African design system
/// - Comprehensive personalization questions
/// - Backend sync and offline-first data persistence
class UnifiedOnboardingScreen extends HookConsumerWidget {
  const UnifiedOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentStep = useState(0);
    final onboardingData = useState<Map<String, dynamic>>({});
    final isCompleting = useState(false);

    // Animation controller for character entrances
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    // Village characters guide the journey
    final steps = [
      // Step 0: Welcome to the Village
      _VillageWelcomeStep(
        onNext: () => _goToNext(pageController, currentStep, animationController),
      ),
      // Step 1: Meet the Elder (What language do you speak?)
      _ElderStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 2: The Weaver (What language to learn?)
      _WeaverStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 3: The Elder's Question (Age & Why learning?)
      _ElderQuestionStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 4: The Path Chooser (Primary goal)
      _PathChooserStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 5: The Rhythm Master (Learning style)
      _RhythmMasterStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 6: The Timekeeper (Schedule)
      _TimekeeperStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 7: The Griot (Tone & gamification)
      _GriotStep(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep, animationController);
        },
      ),
      // Step 8: The Naming Ceremony (Profile setup)
      _NamingCeremonyStep(
        onboardingData: onboardingData.value,
        onComplete: () async {
          if (isCompleting.value) return;
          isCompleting.value = true;
          try {
            await _completeOnboarding(onboardingData.value, context, ref);
          } finally {
            isCompleting.value = false;
          }
        },
      ),
    ];

    final totalSteps = steps.length;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                currentStep.value = index;
                HapticFeedback.lightImpact();
                animationController.reset();
                animationController.forward();
              },
              itemCount: totalSteps,
              itemBuilder: (context, index) => steps[index],
            ),
            // Progress indicator
            _buildProgressIndicator(context, ref, currentStep.value, totalSteps,
              onBack: currentStep.value > 0 
                ? () => _goToPrevious(pageController, currentStep, animationController)
                : null,
              onSkip: () => _skipOnboarding(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    WidgetRef ref,
    int current,
    int total, {
    VoidCallback? onBack,
    VoidCallback? onSkip,
  }) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            // Back button
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20.sp),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
                ),
              )
            else
              SizedBox(width: 48.w),
            
            // Progress bar
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
                  border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final progress = total == 0
                                ? 0.0
                                : ((current + 1) / total).clamp(0.0, 1.0);
                            return Stack(
                              children: [
                                Container(
                                  height: 6.h,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 6.h,
                                  width: constraints.maxWidth * progress,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '${current + 1}/$total',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Skip button (only on early steps)
            if (current < 3)
              Semantics(
                label: 'Skip onboarding',
                button: true,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: 48.w),
          ],
        ),
      ),
    );
  }

  void _goToNext(PageController controller, ValueNotifier<int> step, AnimationController anim) {
    step.value++;
    controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevious(PageController controller, ValueNotifier<int> step, AnimationController anim) {
    if (step.value <= 0) return;
    step.value--;
    controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  static Future<void> _skipOnboarding(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider).prefs;
      await prefs.setString('onboarding_complete', 'true');
      await prefs.setBool('onboarding_seen', true);
      if (context.mounted) {
        ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
      }
    } catch (e) {
      logger.warn('Skip onboarding failed', error: e);
      if (context.mounted) {
        ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
      }
    }
  }

  static Future<void> _completeOnboarding(
    Map<String, dynamic> data,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final prefs = ref.read(sharedPreferencesProvider).prefs;

    // Save all onboarding data locally
    try {
      await prefs.setString('onboarding_complete', 'true');
      await prefs.setString('onboarding_data', data.toString());
      await prefs.setBool('onboarding_seen', true);
    } catch (e) {
      logger.error('Error saving onboarding completion locally', error: e);
    }

    // Queue backend sync
    try {
      final syncProvider = ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.onboarding,
        data: {
          ...data,
          'completed_at': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      logger.warn('Backend sync failed for onboarding completion', error: e);
    }

    // Offer placement test
    final learningLanguage = data['learning_language'] as String?;
    if (learningLanguage != null && context.mounted) {
      try {
        final alreadyPrompted = prefs.getBool('placement_test_prompt_shown') ?? false;
        if (!alreadyPrompted) {
          final shouldTakeTest = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: PanAfricanColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
              ),
              title: Text(
                'Take Placement Test?',
                style: PanAfricanTypography.titleLarge(context),
              ),
              content: Text(
                'Would you like to take a quick placement test to assess your current level in $learningLanguage?\n\nYou can skip this and take it later.',
                style: PanAfricanTypography.bodyMedium(context),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Skip', style: TextStyle(color: PanAfricanColors.textSecondary)),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                  ),
                  child: const Text('Take Test'),
                ),
              ],
            ),
          );

          await prefs.setBool('placement_test_prompt_shown', true);
          
          if (shouldTakeTest == true && context.mounted) {
            await Navigator.push(
              context,
              SmoothPageRoute(
                child: PlacementTestScreen(language: learningLanguage),
              ),
            );
          }
        }
      } catch (e) {
        logger.warn('Error showing placement test option', error: e);
      }
    }

    // Navigate to appropriate screen
    if (context.mounted) {
      final currentUser = ref.read(userProvider);
      final token = ref.read(apiProvider.notifier).token;
      final isLoggedIn = currentUser != null && (token?.isNotEmpty ?? false);

      final nextScreen = isLoggedIn ? const TabsViewMaterial3() : const WorldClassLoginScreen();
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute(child: nextScreen),
        (route) => false,
      );
    }
  }
}

// =============================================================================
// STEP 0: Village Welcome
// =============================================================================
class _VillageWelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _VillageWelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PanAfricanColors.primary,
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            SizedBox(height: 80.h),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200.w,
                      height: 200.w,
                      child: OnboardingAvatarWidget(
                        step: OnboardingStep.welcome,
                        size: 200.w,
                        animate: true,
                      ),
                    )
                        .animate()
                        .scale(delay: 200.ms, duration: 700.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 500.ms),
                    SizedBox(height: 48.h),
                    Text(
                      'Welcome to',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                        letterSpacing: 1,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    SizedBox(height: 8.h),
                    Text(
                      'Kijiji cha Lugha',
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.displaySmall(context, color: Theme.of(context).colorScheme.onPrimary)
                          .copyWith(height: 1.1, letterSpacing: -1),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    SizedBox(height: 12.h),
                    Text(
                      'The Language Village',
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        color: PanAfricanColors.secondary,
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    SizedBox(height: 24.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48.w),
                      child: Text(
                        'Your journey to mastering African languages begins here.',
                        textAlign: TextAlign.center,
                        style: PanAfricanTypography.bodyMedium(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: SizedBox(
                width: double.infinity,
                child:                 PanAfricanButton(
                  label: 'Begin Your Journey',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onNext();
                  },
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  height: 56.h,
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 1: Meet the Elder (What language do you speak?)
// =============================================================================
class _ElderStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _ElderStep({required this.onNext});

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦'},
    {'code': 'sw', 'name': 'Swahili', 'flag': '🇰🇪'},
    {'code': 'yo', 'name': 'Yoruba', 'flag': '🇳🇬'},
    {'code': 'ha', 'name': 'Hausa', 'flag': '🇳🇬'},
    {'code': 'zu', 'name': 'Zulu', 'flag': '🇿🇦'},
    {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.earth,
      characterIcon: Icons.elderly_rounded,
      characterName: 'Pa LingAfriq',
      dialogue: 'Karibu, traveler! I am Pa LingAfriq,\nkeeper of the village memory.',
      question: 'Tell me — what language flows from your tongue?',
      avatarStep: OnboardingStep.welcome,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = selectedLanguage.value == lang['code'];
                return _LanguageCard(
                  flag: lang['flag']!,
                  name: lang['name']!,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedLanguage.value = lang['code'];
                  },
                );
              },
            ),
          ),
          _ContinueButton(
            enabled: selectedLanguage.value != null,
            onPressed: () async {
              // Set app language
              try {
                await DynamicLocalizationService.setLanguage(selectedLanguage.value!);
              } catch (e) {
                logger.error('Error setting language', error: e);
              }
              // Save to prefs
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('proficiency_language', selectedLanguage.value!);
              } catch (e) {
                logger.error('Error saving language', error: e);
              }
              onNext({'proficiency_language': selectedLanguage.value});
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 2: The Weaver (What language to learn?)
// =============================================================================
class _WeaverStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _WeaverStep({required this.onNext});

  static const _africanLanguages = [
    {'code': 'sw', 'name': 'Swahili', 'flag': '🇰🇪', 'region': 'East Africa'},
    {'code': 'yo', 'name': 'Yoruba', 'flag': '🇳🇬', 'region': 'West Africa'},
    {'code': 'ha', 'name': 'Hausa', 'flag': '🇳🇬', 'region': 'West Africa'},
    {'code': 'ig', 'name': 'Igbo', 'flag': '🇳🇬', 'region': 'West Africa'},
    {'code': 'zu', 'name': 'Zulu', 'flag': '🇿🇦', 'region': 'Southern Africa'},
    {'code': 'xh', 'name': 'Xhosa', 'flag': '🇿🇦', 'region': 'Southern Africa'},
    {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹', 'region': 'East Africa'},
    {'code': 'pcm', 'name': 'Nigerian Pidgin', 'flag': '🇳🇬', 'region': 'West Africa'},
    {'code': 'wo', 'name': 'Wolof', 'flag': '🇸🇳', 'region': 'West Africa'},
    {'code': 'tw', 'name': 'Twi', 'flag': '🇬🇭', 'region': 'West Africa'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.sunset,
      characterIcon: Icons.auto_fix_high_rounded,
      characterName: 'Adisa the Weaver',
      dialogue: 'I weave the threads of languages\ninto patterns of understanding.',
      question: 'Which African tongue calls to your spirit?',
      avatarStep: OnboardingStep.languageSelection,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _africanLanguages.length,
              itemBuilder: (context, index) {
                final lang = _africanLanguages[index];
                final isSelected = selectedLanguage.value == lang['code'];
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _LanguageListTile(
                    flag: lang['flag']!,
                    name: lang['name']!,
                    region: lang['region']!,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      selectedLanguage.value = lang['code'];
                    },
                  ),
                );
              },
            ),
          ),
          _ContinueButton(
            enabled: selectedLanguage.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('learning_language', selectedLanguage.value!);
                scheduleGamesPreloadAfterLearningLanguageSaved(ref);
              } catch (e) {
                logger.error('Error saving learning language', error: e);
              }
              onNext({'learning_language': selectedLanguage.value});
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 3: Elder's Question (Age & Why learning?)
// =============================================================================
class _ElderQuestionStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _ElderQuestionStep({required this.onNext});

  static const _ageCategories = ['child', 'teen', 'adult', 'senior'];
  static const _reasons = [
    {'id': 'heritage', 'icon': Icons.family_restroom_rounded, 'label': 'Heritage'},
    {'id': 'travel', 'icon': Icons.flight_rounded, 'label': 'Travel'},
    {'id': 'school', 'icon': Icons.school_rounded, 'label': 'School'},
    {'id': 'business', 'icon': Icons.business_center_rounded, 'label': 'Business'},
    {'id': 'curiosity', 'icon': Icons.lightbulb_rounded, 'label': 'Curiosity'},
    {'id': 'family', 'icon': Icons.favorite_rounded, 'label': 'Family'},
    {'id': 'culture', 'icon': Icons.music_note_rounded, 'label': 'Culture'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAge = useState<String?>(null);
    final selectedReasons = useState<Set<String>>({});

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.earth,
      characterIcon: Icons.elderly_rounded,
      characterName: 'Pa LingAfriq',
      dialogue: 'Every learner has a story.\nShare yours with me.',
      question: 'Who are you, and why do you seek knowledge?',
      avatarStep: OnboardingStep.welcome,
      child: Column(
        children: [
          // Age selection
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Season of Life',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 10.w,
                  children: _ageCategories.map((age) {
                    final isSelected = selectedAge.value == age;
                    return ChoiceChip(
                      label: Text(age.toUpperCase()),
                      selected: isSelected,
                      onSelected: (sel) {
                        HapticFeedback.selectionClick();
                        selectedAge.value = sel ? age : null;
                      },
                      backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
                      selectedColor: PanAfricanColors.secondary,
                      side: BorderSide(
                        color: isSelected
                            ? PanAfricanColors.secondary
                            : Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
                        width: 1.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Reasons grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you learning? (Select all that apply)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
              ),
              itemCount: _reasons.length,
              itemBuilder: (context, index) {
                final reason = _reasons[index];
                final isSelected = selectedReasons.value.contains(reason['id']);
                return _ReasonCard(
                  icon: reason['icon'] as IconData,
                  label: reason['label'] as String,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final newSet = Set<String>.from(selectedReasons.value);
                    if (isSelected) {
                      newSet.remove(reason['id']);
                    } else {
                      newSet.add(reason['id'] as String);
                    }
                    selectedReasons.value = newSet;
                  },
                );
              },
            ),
          ),
          _ContinueButton(
            enabled: selectedAge.value != null && selectedReasons.value.isNotEmpty,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('age_category', selectedAge.value!);
                await prefs.setStringList('learning_reasons', selectedReasons.value.toList());
              } catch (e) {
                logger.error('Error saving age/reasons', error: e);
              }
              onNext({
                'age_category': selectedAge.value,
                'learning_reasons': selectedReasons.value.toList(),
              });
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 4: Path Chooser (Primary goal)
// =============================================================================
class _PathChooserStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _PathChooserStep({required this.onNext});

  static const _goals = [
    {'id': 'travel', 'icon': Icons.explore_rounded, 'title': 'Travel', 'desc': 'Navigate confidently'},
    {'id': 'heritage', 'icon': Icons.favorite_rounded, 'title': 'Heritage', 'desc': 'Connect with roots'},
    {'id': 'business', 'icon': Icons.business_center_rounded, 'title': 'Business', 'desc': 'Professional growth'},
    {'id': 'academic', 'icon': Icons.school_rounded, 'title': 'Academic', 'desc': 'Educational success'},
    {'id': 'confidence', 'icon': Icons.mic_rounded, 'title': 'Confidence', 'desc': 'Speak boldly'},
    {'id': 'brain', 'icon': Icons.psychology_rounded, 'title': 'Brain Training', 'desc': 'Sharpen your mind'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.forest,
      characterIcon: Icons.fork_right_rounded,
      characterName: 'Zuri the Pathfinder',
      dialogue: 'Many paths lead through our village.\nEach offers different wisdom.',
      question: 'Which path calls to you?',
      avatarStep: OnboardingStep.goals,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = selectedGoal.value == goal['id'];
                return _GoalCard(
                  icon: goal['icon'] as IconData,
                  title: goal['title'] as String,
                  description: goal['desc'] as String,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedGoal.value = goal['id'] as String;
                  },
                );
              },
            ),
          ),
          _ContinueButton(
            enabled: selectedGoal.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('primary_goal', selectedGoal.value!);
              } catch (e) {
                logger.error('Error saving goal', error: e);
              }
              onNext({'primary_goal': selectedGoal.value});
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 5: Rhythm Master (Learning style)
// =============================================================================
class _RhythmMasterStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _RhythmMasterStep({required this.onNext});

  static const _styles = [
    {'id': 'audio', 'icon': Icons.headphones_rounded, 'title': 'Listening', 'desc': 'Learn by ear'},
    {'id': 'visual', 'icon': Icons.visibility_rounded, 'title': 'Visual', 'desc': 'See to remember'},
    {'id': 'stories', 'icon': Icons.auto_stories_rounded, 'title': 'Stories', 'desc': 'Narrative learning'},
    {'id': 'drills', 'icon': Icons.repeat_rounded, 'title': 'Practice', 'desc': 'Repetition & drills'},
    {'id': 'conversation', 'icon': Icons.chat_rounded, 'title': 'Conversation', 'desc': 'Talk to learn'},
    {'id': 'mixed', 'icon': Icons.shuffle_rounded, 'title': 'Mixed', 'desc': 'Variety of methods'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStyle = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.sunset,
      characterIcon: Icons.music_note_rounded,
      characterName: 'Nuru the Rhythm Master',
      dialogue: 'Language is music, traveler.\nEach soul dances differently.',
      question: 'How does your spirit best receive knowledge?',
      avatarStep: OnboardingStep.learningStyle,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: _styles.length,
              itemBuilder: (context, index) {
                final style = _styles[index];
                final isSelected = selectedStyle.value == style['id'];
                return _StyleCard(
                  icon: style['icon'] as IconData,
                  title: style['title'] as String,
                  description: style['desc'] as String,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedStyle.value = style['id'] as String;
                  },
                );
              },
            ),
          ),
          _ContinueButton(
            enabled: selectedStyle.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('learning_style', selectedStyle.value!);
              } catch (e) {
                logger.error('Error saving learning style', error: e);
              }
              onNext({'learning_style': selectedStyle.value});
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 6: Timekeeper (Schedule)
// =============================================================================
class _TimekeeperStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _TimekeeperStep({required this.onNext});

  static const _times = [
    {'id': 'sunrise', 'icon': Icons.wb_twilight_rounded, 'label': 'Sunrise', 'time': '6-9 AM'},
    {'id': 'midday', 'icon': Icons.wb_sunny_rounded, 'label': 'Midday', 'time': '12-2 PM'},
    {'id': 'sunset', 'icon': Icons.nights_stay_rounded, 'label': 'Sunset', 'time': '5-7 PM'},
    {'id': 'night', 'icon': Icons.bedtime_rounded, 'label': 'Night', 'time': '8-10 PM'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = useState(15);
    final selectedTime = useState<String?>(null);
    final remindersEnabled = useState(true);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.earth,
      characterIcon: Icons.schedule_rounded,
      characterName: 'Kofi the Timekeeper',
      dialogue: 'Time is the gift we give ourselves.\nHow much will you invest?',
      question: 'When and how long shall we train?',
      avatarStep: OnboardingStep.schedule,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Duration slider
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${duration.value} minutes',
                            style: TextStyle(
                              color: PanAfricanColors.secondary,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: PanAfricanColors.secondary,
                          inactiveTrackColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                          thumbColor: PanAfricanColors.secondary,
                          overlayColor: PanAfricanColors.secondary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: duration.value.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '${duration.value} min',
                          onChanged: (v) => duration.value = v.toInt(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('5 min', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.54), fontSize: 12.sp)),
                          Text('60 min', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.54), fontSize: 12.sp)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                // Time of day
                Text(
                  'Best Time to Learn',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemCount: _times.length,
            itemBuilder: (context, index) {
              final time = _times[index];
              final isSelected = selectedTime.value == time['id'];
              return _TimeCard(
                icon: time['icon'] as IconData,
                label: time['label'] as String,
                time: time['time'] as String,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  selectedTime.value = time['id'] as String;
                },
              );
            },
          ),
          SizedBox(height: 8.h),
          // Reminders toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SwitchListTile(
              title: Text(
                'Enable Daily Reminders',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14.sp),
              ),
              value: remindersEnabled.value,
              onChanged: (v) => remindersEnabled.value = v,
              activeColor: PanAfricanColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          _ContinueButton(
            enabled: selectedTime.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('daily_duration', duration.value);
                await prefs.setString('preferred_time', selectedTime.value!);
                await prefs.setBool('reminders_enabled', remindersEnabled.value);
              } catch (e) {
                logger.error('Error saving schedule', error: e);
              }
              onNext({
                'daily_duration_minutes': duration.value,
                'preferred_time_of_day': selectedTime.value,
                'reminders_enabled': remindersEnabled.value,
              });
            },
          ),
        ],
      ),
      ),
    );
  }
}

// =============================================================================
// STEP 7: The Griot (Tone & gamification)
// =============================================================================
class _GriotStep extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _GriotStep({required this.onNext});

  static const _tones = [
    {'id': 'playful', 'icon': Icons.sentiment_very_satisfied_rounded, 'label': 'Playful', 'desc': 'Fun & light'},
    {'id': 'encouraging', 'icon': Icons.thumb_up_rounded, 'label': 'Encouraging', 'desc': 'Supportive'},
    {'id': 'serious', 'icon': Icons.psychology_rounded, 'label': 'Focused', 'desc': 'Direct & efficient'},
    {'id': 'friendly', 'icon': Icons.emoji_people_rounded, 'label': 'Friendly', 'desc': 'Warm & casual'},
  ];

  static const _gamificationLevels = [
    {'id': 'full', 'label': 'Full', 'desc': 'XP, badges, streaks'},
    {'id': 'moderate', 'label': 'Moderate', 'desc': 'Progress tracking'},
    {'id': 'minimal', 'label': 'Minimal', 'desc': 'Just learning'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTone = useState<String?>(null);
    final selectedGamification = useState<String?>('full');

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.sunset,
      characterIcon: Icons.campaign_rounded,
      characterName: 'Amara the Griot',
      dialogue: 'I am the storyteller, the voice\nthat guides your journey.',
      question: 'How shall I speak to you?',
      avatarStep: OnboardingStep.story,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Column(
        children: [
          // Tone selection
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Style',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
          SizedBox(
            height: 90.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _tones.length,
              itemBuilder: (context, index) {
                final tone = _tones[index];
                final isSelected = selectedTone.value == tone['id'];
                return Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: _ToneCard(
                    icon: tone['icon'] as IconData,
                    label: tone['label'] as String,
                    description: tone['desc'] as String,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      selectedTone.value = tone['id'] as String;
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24.h),
          // Gamification level
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gamification Level',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                ..._gamificationLevels.map((level) {
                  final isSelected = selectedGamification.value == level['id'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          selectedGamification.value = level['id'] as String;
                        },
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? PanAfricanColors.secondary.withOpacity(0.2)
                                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? PanAfricanColors.secondary
                                  : Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      level['label'] as String,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      level['desc'] as String,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: PanAfricanColors.secondary,
                                  size: 24.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          _ContinueButton(
            enabled: selectedTone.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_tone', selectedTone.value!);
                await prefs.setString('gamification_level', selectedGamification.value!);
              } catch (e) {
                logger.error('Error saving tone/gamification', error: e);
              }
              onNext({
                'app_tone': selectedTone.value,
                'gamification_level': selectedGamification.value,
              });
            },
          ),
        ],
      ),
      ),
    );
  }
}

// =============================================================================
// STEP 8: Naming Ceremony (Profile)
// =============================================================================
class _NamingCeremonyStep extends HookConsumerWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onComplete;

  const _NamingCeremonyStep({
    required this.onboardingData,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final username = useState('');
    final usernameStatus = useState<_UsernameStatus>(_UsernameStatus.initial);
    final isChecking = useState(false);
    final avatarPath = useState<String?>(null);
    Timer? debounceTimer;

    // Listen to username changes
    useEffect(() {
      void listener() {
        final text = usernameController.text.trim();
        username.value = text;
        debounceTimer?.cancel();

        if (text.isEmpty) {
          usernameStatus.value = _UsernameStatus.initial;
          isChecking.value = false;
          return;
        }

        if (text.length < 3) {
          usernameStatus.value = _UsernameStatus.tooShort;
          return;
        }

        if (text.length > 30) {
          usernameStatus.value = _UsernameStatus.tooLong;
          return;
        }

        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
          usernameStatus.value = _UsernameStatus.invalidFormat;
          return;
        }

        usernameStatus.value = _UsernameStatus.checking;
        isChecking.value = true;
        debounceTimer = Timer(const Duration(milliseconds: 500), () async {
          try {
            final api = ref.read(apiProvider.notifier);
            final isAvailable = await api.checkUsernameAvailability(text);
            if (context.mounted) {
              usernameStatus.value = isAvailable
                  ? _UsernameStatus.available
                  : _UsernameStatus.taken;
              isChecking.value = false;
            }
          } catch (e) {
            if (context.mounted) {
              usernameStatus.value = _UsernameStatus.error;
              isChecking.value = false;
            }
          }
        });
      }

      usernameController.addListener(listener);
      return () {
        debounceTimer?.cancel();
        usernameController.removeListener(listener);
      };
    }, []);

    Future<void> pickAvatar() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          avatarPath.value = result.files.single.path;
        }
      } catch (e) {
        logger.error('Error picking avatar', error: e);
        if (context.mounted) {
          showLingAfriqError(context, 'Failed to pick image');
        }
      }
    }

    final canComplete = username.value.isNotEmpty &&
        username.value.length >= 3 &&
        username.value.length <= 30 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.value) &&
        (usernameStatus.value == _UsernameStatus.available ||
            usernameStatus.value == _UsernameStatus.error);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.forest,
      characterIcon: Icons.celebration_rounded,
      characterName: 'The Naming Ceremony',
      dialogue: 'A learner without a name is a\ndrum without a rhythm!',
      question: 'Tell us what you wish to be called.',
      avatarStep: OnboardingStep.profile,
      child: Column(
        children: [
          SizedBox(height: 16.h),
          // Avatar
          GestureDetector(
            onTap: pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55.r,
                  backgroundColor: PanAfricanColors.secondary.withOpacity(0.3),
                  backgroundImage: avatarPath.value != null
                      ? FileImage(File(avatarPath.value!))
                      : null,
                  child: avatarPath.value == null
                      ? Icon(Icons.person_rounded, size: 50.sp, color: Theme.of(context).colorScheme.onPrimary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, size: 16.sp, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap to add photo (optional)',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), fontSize: 12.sp),
          ),
          SizedBox(height: 24.h),
          // Username field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: TextField(
              controller: usernameController,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18.sp),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                hintText: 'Enter your username',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.38)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  borderSide: BorderSide(color: PanAfricanColors.secondary, width: 2),
                ),
                suffixIcon: isChecking.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          ),
                        ),
                      )
                    : _getUsernameIcon(usernameStatus.value),
                helperText: _getUsernameHelperText(usernameStatus.value),
                helperStyle: TextStyle(
                  color: _getUsernameHelperColor(context, usernameStatus.value),
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          const Spacer(),
          _ContinueButton(
            label: 'Complete Setup',
            enabled: canComplete,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', username.value);
                if (avatarPath.value != null) {
                  await prefs.setString('avatar_path', avatarPath.value!);
                }
              } catch (e) {
                logger.error('Error saving profile', error: e);
              }
              onComplete();
            },
          ),
        ],
      ),
    );
  }

  Widget? _getUsernameIcon(_UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.available:
        return Icon(Icons.check_circle_rounded, color: PanAfricanColors.success);
      case _UsernameStatus.taken:
        return Icon(Icons.cancel_rounded, color: PanAfricanColors.error);
      case _UsernameStatus.tooShort:
      case _UsernameStatus.tooLong:
      case _UsernameStatus.invalidFormat:
        return Icon(Icons.warning_rounded, color: PanAfricanColors.warning);
      default:
        return null;
    }
  }

  String? _getUsernameHelperText(_UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.initial:
        return '3-30 characters, letters, numbers, underscores';
      case _UsernameStatus.checking:
        return 'Checking availability...';
      case _UsernameStatus.available:
        return '✓ Username is available';
      case _UsernameStatus.taken:
        return '✗ Username is already taken';
      case _UsernameStatus.tooShort:
        return 'Username must be at least 3 characters';
      case _UsernameStatus.tooLong:
        return 'Username must be 30 characters or less';
      case _UsernameStatus.invalidFormat:
        return 'Only letters, numbers, and underscores allowed';
      case _UsernameStatus.error:
        return 'Could not verify. You can still continue.';
    }
  }

  Color _getUsernameHelperColor(BuildContext context, _UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.available:
        return PanAfricanColors.success;
      case _UsernameStatus.taken:
        return PanAfricanColors.error;
      case _UsernameStatus.tooShort:
      case _UsernameStatus.tooLong:
      case _UsernameStatus.invalidFormat:
        return PanAfricanColors.warning;
      default:
        return Theme.of(context).colorScheme.onPrimary.withOpacity(0.7);
    }
  }
}

enum _UsernameStatus {
  initial,
  checking,
  available,
  taken,
  tooShort,
  tooLong,
  invalidFormat,
  error,
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

/// Template for character-guided steps
class _CharacterStepTemplate extends StatelessWidget {
  final Gradient gradient;
  final IconData characterIcon;
  final String characterName;
  final String dialogue;
  final String question;
  final Widget child;
  final OnboardingStep? avatarStep;

  const _CharacterStepTemplate({
    required this.gradient,
    required this.characterIcon,
    required this.characterName,
    required this.dialogue,
    required this.question,
    required this.child,
    this.avatarStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            SizedBox(height: 60.h),
            // Character avatar — use OnboardingAvatarWidget when step is provided
            if (avatarStep != null)
              SizedBox(
                width: 100.w,
                height: 100.w,
                child: OnboardingAvatarWidget(
                  step: avatarStep!,
                  size: 100.w,
                  animate: true,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOut)
            else
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
                  border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3), width: 2),
                ),
                child: Icon(characterIcon, size: 50.sp, color: Theme.of(context).colorScheme.onPrimary),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
            SizedBox(height: 12.h),
            // Dialogue + Question panel
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dialogue,
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.headlineSmall(context, color: Theme.of(context).colorScheme.onPrimary)
                          .copyWith(height: 1.3),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      question,
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)
                          .copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08, end: 0),
            SizedBox(height: 24.h),
            // Content
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Continue button
class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  const _ContinueButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: SizedBox(
        width: double.infinity,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: PanAfricanButton(
            label: label,
            onPressed: enabled
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed();
                  }
                : null,
            backgroundColor: PanAfricanColors.secondary,
            foregroundColor: PanAfricanColors.neutralDarkest,
            width: double.infinity,
            height: 52.h,
          ),
        ),
      ),
    );
  }
}

/// Language card for grid selection
class _LanguageCard extends StatelessWidget {
  final String flag;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? PanAfricanColors.secondary.withOpacity(0.25)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            border: Border.all(
              color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.12),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: TextStyle(fontSize: 28.sp)),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 8.w),
                Icon(Icons.check_circle_rounded, color: PanAfricanColors.secondary, size: 18.sp),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Language list tile for learning language selection
class _LanguageListTile extends StatelessWidget {
  final String flag;
  final String name;
  final String region;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageListTile({
    required this.flag,
    required this.name,
    required this.region,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected
                ? PanAfricanColors.secondary.withOpacity(0.2)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            border: Border.all(
              color: isSelected ? PanAfricanColors.secondary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.18 : 0.12),
                blurRadius: isSelected ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(flag, style: TextStyle(fontSize: 32.sp)),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      region,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.54),
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reason card for multi-select
class _ReasonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? PanAfricanColors.secondary.withOpacity(0.25)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            border: Border.all(
              color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.12),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PanAfricanColors.secondary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.onPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Goal card
class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? PanAfricanColors.secondary.withOpacity(0.2)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            border: Border.all(
              color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.12),
                blurRadius: isSelected ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PanAfricanColors.secondary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.onPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Style card (same as goal card but different proportions)
class _StyleCard extends _GoalCard {
  const _StyleCard({
    required super.icon,
    required super.title,
    required super.description,
    required super.isSelected,
    required super.onTap,
  });
}

/// Time selection card
class _TimeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? PanAfricanColors.secondary.withOpacity(0.2)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            border: Border.all(
              color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.12),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PanAfricanColors.secondary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.onPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.54),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tone selection card (horizontal scroll)
class _ToneCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToneCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Container(
          width: 100.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isSelected
                ? PanAfricanColors.secondary.withOpacity(0.2)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            border: Border.all(
              color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.12),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PanAfricanColors.secondary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.onPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? PanAfricanColors.secondary : Theme.of(context).colorScheme.onPrimary,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.54),
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
