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
import 'package:lingafriq/models/onboarding_answers.dart';
import 'placement_test_screen.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';

/// Mirrors server `agePolicy` default thresholds (P1-020).
String? computeRegistrationAgeBand(int birthYear, {String? countryCode}) {
  final nowYear = DateTime.now().year;
  if (birthYear < 1900 || birthYear > nowYear) return null;
  final age = nowYear - birthYear - 1;
  if (age < 0) return null;
  final childUnder = countryCode?.toUpperCase() == 'DE' ? 16 : 13;
  const adultAt = 18;
  if (age < childUnder) return 'child';
  if (age < adultAt) return 'teen';
  return 'adult';
}

/// Returns [Duration.zero] when the platform/OS has requested reduced
/// motion (MediaQuery.disableAnimations), so every entrance animation in
/// this flow snaps straight to its final state instead of animating.
Duration _motionDuration(BuildContext context, Duration normal) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

/// Same reduced-motion guard for `flutter_animate`'s `delay:` parameter.
Duration _motionDelay(BuildContext context, Duration normal) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

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
    final reask =
        ref
            .read(sharedPreferencesProvider)
            .prefs
            .getStringList('onboarding_reask') ??
        const <String>[];
    bool ask(Iterable<String> keys) =>
        reask.isEmpty || keys.any(reask.contains);
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
    final stepCount = <int>[0];
    // Mirrors `steps`' own conditions exactly so `stepsLight[i]` always
    // tells the floating progress bar/back/skip chrome (which overlays
    // whichever step is currently showing through the `Stack` below)
    // whether that step's background is one of the near-white
    // `PanAfricanGradients.earth`/`sunset` tints - the only steps where the
    // cream `colorScheme.onPrimary` this chrome used to hardcode would be
    // close to invisible.
    final stepsLight = <bool>[
      if (reask.isEmpty) false, // _VillageWelcomeStep: dark primary green
      if (ask(const ['proficiency_language'])) true, // _ElderStep: earth
      if (ask(const ['learning_language'])) true, // _WeaverStep: sunset
      if (ask(const ['age_category', 'learning_reasons']))
        true, // _ElderQuestionStep: earth
      if (ask(const ['primary_goal'])) false, // _PathChooserStep: forest
      if (ask(const ['learning_style'])) true, // _RhythmMasterStep: sunset
      if (ask(const [
        'daily_duration_minutes',
        'preferred_time_of_day',
        'reminders_enabled',
      ]))
        true, // _TimekeeperStep: earth
      if (ask(const ['app_tone', 'gamification_level']))
        true, // _GriotStep: sunset
      if (reask.isEmpty) false, // _NamingCeremonyStep: dark forest
    ];
    final steps = <Widget>[
      if (reask.isEmpty)
        _VillageWelcomeStep(
          onNext: () => _goToNext(
            context,
            pageController,
            currentStep,
            animationController,
          ),
        ),
      if (ask(const ['proficiency_language']))
        _ElderStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (ask(const ['learning_language']))
        _WeaverStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (ask(const ['age_category', 'learning_reasons']))
        _ElderQuestionStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (ask(const ['primary_goal']))
        _PathChooserStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (ask(const ['learning_style']))
        _RhythmMasterStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (ask(const [
        'daily_duration_minutes',
        'preferred_time_of_day',
        'reminders_enabled',
      ]))
        _TimekeeperStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (ask(const ['app_tone', 'gamification_level']))
        _GriotStep(
          onNext: (data) => _captureOnboardingAnswer(
            data,
            onboardingData,
            pageController,
            currentStep,
            animationController,
            stepsLength: () => stepCount[0],
            reask: reask,
            context: context,
            ref: ref,
          ),
        ),
      if (reask.isEmpty)
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
    stepCount[0] = steps.length;

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
            _buildProgressIndicator(
              context,
              ref,
              currentStep.value,
              totalSteps,
              isLightBackground: stepsLight[currentStep.value],
              onBack: (!isCompleting.value && currentStep.value > 0)
                  ? () => _goToPrevious(
                      context,
                      pageController,
                      currentStep,
                      animationController,
                    )
                  : null,
              onSkip: isCompleting.value
                  ? null
                  : () => _skipOnboarding(context, ref),
            ),
            // Completion loading state: shown while local save, backend
            // sync queueing, and the placement-test offer are in flight so
            // the learner never sees an unresponsive screen.
            if (isCompleting.value)
              Positioned.fill(
                child: Semantics(
                  liveRegion: true,
                  label: 'Setting up your language village, please wait',
                  child: Container(
                    color: PanAfricanColors.neutralDarkest.withValues(
                      alpha: 0.72,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 36.w,
                            height: 36.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                PanAfricanColors.secondary,
                              ),
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.md.h),
                          Text(
                            'Preparing your village...',
                            style: PanAfricanTypography.bodyMedium(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
    required bool isLightBackground,
    VoidCallback? onBack,
    VoidCallback? onSkip,
  }) {
    // This chrome floats over whichever step is currently showing (see the
    // `Stack` in `build`), so it can't rely on `colorScheme.onPrimary` -
    // which is designed for the app's *dark* primary surfaces - whenever
    // the step underneath is one of the near-white
    // `PanAfricanGradients.earth`/`sunset` steps; see `isLightBackground` on
    // `_CharacterStepTemplate` for the full contrast-math rationale.
    final Color foregroundColor = isLightBackground
        ? PanAfricanColors.textPrimary
        : Theme.of(context).colorScheme.onPrimary;
    final Color progressFillColor = isLightBackground
        ? PanAfricanColors.primary
        : Theme.of(context).colorScheme.primaryContainer;
    return Positioned(
      top: MediaQuery.of(context).padding.top + PanAfricanSpacing.xs.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
        child: Row(
          children: [
            // Back button: BackButtonIcon auto-mirrors for RTL locales
            // (Arabic, Darija) instead of a hardcoded LTR chevron.
            if (onBack != null)
              Semantics(
                label: 'Go back to the previous step',
                button: true,
                child: IconButton(
                  onPressed: onBack,
                  icon: IconTheme(
                    data: IconThemeData(color: foregroundColor, size: 20.sp),
                    child: const BackButtonIcon(),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: foregroundColor.withValues(alpha: 0.15),
                    minimumSize: const Size(
                      AdaptiveLayout.minTouchTarget,
                      AdaptiveLayout.minTouchTarget,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: PanAfricanSpacing.xxl.w),

            // Progress bar
            Expanded(
              child: Semantics(
                label: 'Onboarding progress',
                value: 'Step ${current + 1} of $total',
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.sm.w,
                    vertical: PanAfricanSpacing.xs.h,
                  ),
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
                    border: Border.all(
                      color: foregroundColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            PanAfricanRadius.pill,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final progress = total == 0
                                  ? 0.0
                                  : ((current + 1) / total).clamp(0.0, 1.0);
                              return Stack(
                                children: [
                                  Container(
                                    height: PanAfricanSpacing.xxs.h,
                                    color: foregroundColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: _motionDuration(
                                      context,
                                      const Duration(milliseconds: 300),
                                    ),
                                    height: PanAfricanSpacing.xxs.h,
                                    width: constraints.maxWidth * progress,
                                    decoration: BoxDecoration(
                                      color: progressFillColor,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm.w),
                      Text(
                        '${current + 1}/$total',
                        style: TextStyle(
                          color: foregroundColor.withValues(alpha: 0.9),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                      color: foregroundColor.withValues(alpha: 0.9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: PanAfricanSpacing.xxl.w),
          ],
        ),
      ),
    );
  }

  void _goToNext(
    BuildContext context,
    PageController controller,
    ValueNotifier<int> step,
    AnimationController anim,
  ) {
    step.value++;
    controller.nextPage(
      // Runs on every one of this flow's step transitions, so it's the
      // single most frequent motion in onboarding - it must respect
      // reduced-motion like every other animation here.
      duration: _motionDuration(context, 400.ms),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _captureOnboardingAnswer(
    Map<String, dynamic> data,
    ValueNotifier<Map<String, dynamic>> onboardingData,
    PageController pageController,
    ValueNotifier<int> currentStep,
    AnimationController animationController, {
    required int Function() stepsLength,
    required List<String> reask,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    onboardingData.value = {...onboardingData.value, ...data};
    if (reask.isNotEmpty && currentStep.value + 1 >= stepsLength()) {
      await _completeOnboarding(onboardingData.value, context, ref);
      return;
    }
    _goToNext(context, pageController, currentStep, animationController);
  }

  void _goToPrevious(
    BuildContext context,
    PageController controller,
    ValueNotifier<int> step,
    AnimationController anim,
  ) {
    if (step.value <= 0) return;
    step.value--;
    controller.previousPage(
      duration: _motionDuration(context, 300.ms),
      curve: Curves.easeOut,
    );
  }

  static Future<void> _skipOnboarding(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider).prefs;
      await prefs.setString('onboarding_complete', 'true');
      await prefs.setBool('onboarding_seen', true);
      if (context.mounted) {
        ref
            .read(navigationProvider)
            .navigateOffAll(const WorldClassLoginScreen());
      }
    } catch (e) {
      logger.warn('Skip onboarding failed', error: e);
      if (context.mounted) {
        ref
            .read(navigationProvider)
            .navigateOffAll(const WorldClassLoginScreen());
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
      await prefs.setString(
        'onboarding_data',
        OnboardingAnswers.encodeStored(
          prefs.getString('onboarding_data'),
          data,
        ),
      );
      await prefs.remove('onboarding_reask');
      await prefs.setBool('onboarding_seen', true);
    } catch (e) {
      logger.error('Error saving onboarding completion locally', error: e);
    }

    // Queue backend sync: this always succeeds locally even offline,
    // because PersistedOutboxService is a durable, offline-first queue.
    var isOnline = true;
    try {
      isOnline = await ConnectivityService.hasInternet();
      await PersistedOutboxService.instance.enqueue(
        type: 'onboarding_sync',
        data: {...data, 'completed_at': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      logger.warn('Backend sync failed for onboarding completion', error: e);
    }
    if (!isOnline && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: PanAfricanColors.neutralDark,
          content: Text(
            "You're offline right now, but we've saved your answers and "
            'will sync them the moment you reconnect.',
            style: PanAfricanTypography.bodyMedium(
              context,
              color: Colors.white,
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Offer placement test
    final learningLanguage = data['learning_language'] as String?;
    if (learningLanguage != null && context.mounted) {
      try {
        final alreadyPrompted =
            prefs.getBool('placement_test_prompt_shown') ?? false;
        if (!alreadyPrompted) {
          // Reuses the shared Pan-African dialog component instead of a
          // one-off AlertDialog, so styling stays consistent with the rest
          // of the design system.
          final shouldTakeTest = await PanAfricanDialog.show<bool>(
            context: context,
            title: 'Take a quick placement test?',
            subtitle:
                "We'll ask a few short questions to find your starting "
                'level in $learningLanguage. You can always take it later '
                'from your profile.',
            child: const SizedBox.shrink(),
            actions: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(color: PanAfricanColors.textSecondary),
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    minimumSize: const Size(
                      double.infinity,
                      AdaptiveLayout.minTouchTarget,
                    ),
                  ),
                  child: const Text('Take the test'),
                ),
              ),
            ],
          );

          await prefs.setBool('placement_test_prompt_shown', true);

          if (shouldTakeTest == true && context.mounted) {
            await Navigator.push(
              context,
              SmoothPageRoute.platform(
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

      final nextScreen = isLoggedIn
          ? const TabsViewMaterial3()
          : const WorldClassLoginScreen();
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute.platform(child: nextScreen),
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
                child: Semantics(
                  // Group the welcome narrative into one readable block so a
                  // screen reader announces it as a coherent sentence rather
                  // than four separate fragments.
                  label:
                      'Welcome to Kijiji cha Lugha, The Language Village. '
                      'Your journey to mastering African languages begins here.',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child:
                            // `OnboardingAvatarWidget` always renders a
                            // name/title caption beneath the portrait, so it
                            // needs more height than this hero's 200x200
                            // footprint. `OverflowBox` lets it lay itself out
                            // without tripping its own internal `RenderFlex`
                            // overflow assertion, and the outer `SizedBox` +
                            // `ClipRect` crop the result back down to exactly
                            // the intended portrait size.
                            SizedBox(
                                  width: 200.w,
                                  height: 200.w,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      maxHeight: double.infinity,
                                      alignment: Alignment.topCenter,
                                      child: OnboardingAvatarWidget(
                                        step: OnboardingStep.welcome,
                                        size: 200.w,
                                        animate: true,
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .scale(
                                  delay: _motionDelay(context, 200.ms),
                                  duration: _motionDuration(context, 700.ms),
                                  curve: Curves.elasticOut,
                                )
                                .fadeIn(
                                  duration: _motionDuration(context, 500.ms),
                                ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xxl.h),
                      ExcludeSemantics(
                        child:
                            Text(
                              'Welcome to',
                              style: PanAfricanTypography.titleMedium(context)
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.9),
                                    letterSpacing: 1,
                                  ),
                            ).animate().fadeIn(
                              delay: _motionDelay(context, 400.ms),
                              duration: _motionDuration(context, 300.ms),
                            ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs.h),
                      ExcludeSemantics(
                        child:
                            Text(
                                  'Kijiji cha Lugha',
                                  textAlign: TextAlign.center,
                                  style: PanAfricanTypography.displaySmall(
                                    context,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ).copyWith(height: 1.1, letterSpacing: -1),
                                )
                                .animate()
                                .fadeIn(
                                  delay: _motionDelay(context, 500.ms),
                                  duration: _motionDuration(context, 300.ms),
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: _motionDuration(context, 300.ms),
                                ),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm.h),
                      ExcludeSemantics(
                        child:
                            Text(
                              'The Language Village',
                              textAlign: TextAlign.center,
                              style: PanAfricanTypography.titleMedium(context)
                                  .copyWith(
                                    color: PanAfricanColors.secondary,
                                    letterSpacing: 0.5,
                                  ),
                            ).animate().fadeIn(
                              delay: _motionDelay(context, 600.ms),
                              duration: _motionDuration(context, 300.ms),
                            ),
                      ),
                      SizedBox(height: PanAfricanSpacing.lg.h),
                      ExcludeSemantics(
                        child:
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.xxl.w,
                              ),
                              child: Text(
                                'Your journey to mastering African languages begins here.',
                                textAlign: TextAlign.center,
                                style: PanAfricanTypography.bodyMedium(context)
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.85),
                                    ),
                              ),
                            ).animate().fadeIn(
                              delay: _motionDelay(context, 700.ms),
                              duration: _motionDuration(context, 300.ms),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
              child:
                  SizedBox(
                        width: double.infinity,
                        child: PanAfricanButton(
                          label: 'Begin Your Journey',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onNext();
                          },
                          backgroundColor: PanAfricanColors.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          height: 56.h,
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: _motionDelay(context, 800.ms),
                        duration: _motionDuration(context, 300.ms),
                      )
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: _motionDuration(context, 300.ms),
                      ),
            ),
            SizedBox(height: PanAfricanSpacing.md.h),
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
      isLightBackground: true,
      characterIcon: Icons.elderly_rounded,
      characterName: 'Pa LingAfriq',
      dialogue:
          'Karibu, traveler! I am Pa LingAfriq,\nkeeper of the village memory.',
      question: 'Tell me, what language flows from your tongue?',
      avatarStep: OnboardingStep.welcome,
      child: Column(
        children: [
          // `shrinkWrap` + `NeverScrollableScrollPhysics` sizes this grid to
          // its own content instead of needing an `Expanded` ancestor to
          // tell it how tall to be - `_CharacterStepTemplate` now owns the
          // single scrollable that this whole step scrolls within.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: PanAfricanSpacing.sm.w,
              mainAxisSpacing: PanAfricanSpacing.sm.h,
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
          _ContinueButton(
            enabled: selectedLanguage.value != null,
            onPressed: () async {
              // Set app language
              try {
                await DynamicLocalizationService.setLanguage(
                  selectedLanguage.value!,
                );
              } catch (e) {
                logger.error('Error setting language', error: e);
              }
              // Save to prefs
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'proficiency_language',
                  selectedLanguage.value!,
                );
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
    {
      'code': 'xh',
      'name': 'Xhosa',
      'flag': '🇿🇦',
      'region': 'Southern Africa',
    },
    {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹', 'region': 'East Africa'},
    {
      'code': 'pcm',
      'name': 'Nigerian Pidgin',
      'flag': '🇳🇬',
      'region': 'West Africa',
    },
    {'code': 'wo', 'name': 'Wolof', 'flag': '🇸🇳', 'region': 'West Africa'},
    {'code': 'tw', 'name': 'Twi', 'flag': '🇬🇭', 'region': 'West Africa'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.sunset,
      isLightBackground: true,
      characterIcon: Icons.auto_fix_high_rounded,
      characterName: 'Adisa the Weaver',
      dialogue:
          'I weave the threads of languages\ninto patterns of understanding.',
      question: 'Which African tongue calls to your spirit?',
      avatarStep: OnboardingStep.languageSelection,
      child: Column(
        children: [
          // `shrinkWrap` + `NeverScrollableScrollPhysics` sizes this list to
          // its own content instead of needing an `Expanded` ancestor -
          // `_CharacterStepTemplate` now owns the single scrollable that
          // this whole step scrolls within.
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            itemCount: _africanLanguages.length,
            itemBuilder: (context, index) {
              final lang = _africanLanguages[index];
              final isSelected = selectedLanguage.value == lang['code'];
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm.h),
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
          _ContinueButton(
            enabled: selectedLanguage.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'learning_language',
                  selectedLanguage.value!,
                );
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
    {
      'id': 'heritage',
      'icon': Icons.family_restroom_rounded,
      'label': 'Heritage',
    },
    {'id': 'travel', 'icon': Icons.flight_rounded, 'label': 'Travel'},
    {'id': 'school', 'icon': Icons.school_rounded, 'label': 'School'},
    {
      'id': 'business',
      'icon': Icons.business_center_rounded,
      'label': 'Business',
    },
    {'id': 'curiosity', 'icon': Icons.lightbulb_rounded, 'label': 'Curiosity'},
    {'id': 'family', 'icon': Icons.favorite_rounded, 'label': 'Family'},
    {'id': 'culture', 'icon': Icons.music_note_rounded, 'label': 'Culture'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthYearController = useTextEditingController();
    final selectedReasons = useState<Set<String>>({});
    final computedBand = useState<String?>(null);
    final birthYearError = useState<String?>(null);

    void recomputeBand() {
      final parsed = int.tryParse(birthYearController.text.trim());
      if (parsed == null || birthYearController.text.trim().length != 4) {
        computedBand.value = null;
        birthYearError.value = 'Enter your birth year (four digits).';
        return;
      }
      final band = computeRegistrationAgeBand(parsed);
      if (band == null) {
        computedBand.value = null;
        birthYearError.value = 'That birth year does not look right.';
        return;
      }
      birthYearError.value = null;
      computedBand.value = band;
    }

    useEffect(() {
      void listener() => recomputeBand();
      birthYearController.addListener(listener);
      return () => birthYearController.removeListener(listener);
    }, [birthYearController]);

    final isChildBlocked = computedBand.value == 'child';

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.earth,
      isLightBackground: true,
      characterIcon: Icons.elderly_rounded,
      characterName: 'Pa LingAfriq',
      dialogue: 'Every learner has a story.\nShare yours with me.',
      question: 'When were you born, and why do you seek knowledge?',
      avatarStep: OnboardingStep.welcome,
      // The guardian note below only appears once a child age band is
      // selected, growing this step's content on the fly; the reasons grid
      // is already `shrinkWrap`-sized rather than `Expanded`, so it's safe
      // to size this whole step naturally - `_CharacterStepTemplate` owns
      // the single scrollable this step (and its header above) scrolls
      // within.
      child: Column(
        children: [
          // Age selection
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your birth year',
                  style: TextStyle(
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                Semantics(
                  label: 'Birth year',
                  child: TextField(
                    controller: birthYearController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'e.g. 2008',
                      errorText: birthYearError.value,
                      filled: true,
                      fillColor: PanAfricanColors.textPrimary.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                if (isChildBlocked) ...[
                  SizedBox(height: PanAfricanSpacing.xs.h),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'We need a guardian to verify consent before creating an account. '
                      'Ask a grown-up to help you finish sign-up.',
                      style: TextStyle(
                        color: PanAfricanColors.secondary,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ] else if (computedBand.value == 'teen') ...[
                  SizedBox(height: PanAfricanSpacing.xs.h),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Your profile stays private, and adults cannot DM you until you connect in a circle.',
                      style: TextStyle(
                        color: PanAfricanColors.textPrimary.withValues(alpha: 0.75),
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          // Reasons grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you learning? (Select all that apply)',
                  style: TextStyle(
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: PanAfricanSpacing.sm.w,
              mainAxisSpacing: PanAfricanSpacing.sm.h,
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
          SizedBox(height: PanAfricanSpacing.md.h),
          _ContinueButton(
            enabled:
                computedBand.value != null &&
                !isChildBlocked &&
                selectedReasons.value.isNotEmpty,
            onPressed: () async {
              final year = int.parse(birthYearController.text.trim());
              final band = computedBand.value!;
              try {
                await ref
                    .read(onboardingProvider.notifier)
                    .persistRegistrationBirthYear(year, band);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('age_category', band);
                await prefs.setStringList(
                  'learning_reasons',
                  selectedReasons.value.toList(),
                );
              } catch (e) {
                logger.error('Error saving age/reasons', error: e);
              }
              onNext({
                'birth_year': year,
                'age_band': band,
                'age_category': band,
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
    {
      'id': 'travel',
      'icon': Icons.explore_rounded,
      'title': 'Travel',
      'desc': 'Navigate confidently',
    },
    {
      'id': 'heritage',
      'icon': Icons.favorite_rounded,
      'title': 'Heritage',
      'desc': 'Connect with roots',
    },
    {
      'id': 'business',
      'icon': Icons.business_center_rounded,
      'title': 'Business',
      'desc': 'Professional growth',
    },
    {
      'id': 'academic',
      'icon': Icons.school_rounded,
      'title': 'Academic',
      'desc': 'Educational success',
    },
    {
      'id': 'confidence',
      'icon': Icons.mic_rounded,
      'title': 'Confidence',
      'desc': 'Speak boldly',
    },
    {
      'id': 'brain',
      'icon': Icons.psychology_rounded,
      'title': 'Brain Training',
      'desc': 'Sharpen your mind',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.forest,
      characterIcon: Icons.fork_right_rounded,
      characterName: 'Zuri the Pathfinder',
      dialogue:
          'Many paths lead through our village.\nEach offers different wisdom.',
      question: 'Which path calls to you?',
      avatarStep: OnboardingStep.goals,
      child: Column(
        children: [
          // `shrinkWrap` + `NeverScrollableScrollPhysics` sizes this grid to
          // its own content instead of needing an `Expanded` ancestor -
          // `_CharacterStepTemplate` now owns the single scrollable that
          // this whole step scrolls within.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: PanAfricanSpacing.sm.w,
              mainAxisSpacing: PanAfricanSpacing.sm.h,
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
    {
      'id': 'audio',
      'icon': Icons.headphones_rounded,
      'title': 'Listening',
      'desc': 'Learn by ear',
    },
    {
      'id': 'visual',
      'icon': Icons.visibility_rounded,
      'title': 'Visual',
      'desc': 'See to remember',
    },
    {
      'id': 'stories',
      'icon': Icons.auto_stories_rounded,
      'title': 'Stories',
      'desc': 'Narrative learning',
    },
    {
      'id': 'drills',
      'icon': Icons.repeat_rounded,
      'title': 'Practice',
      'desc': 'Repetition & drills',
    },
    {
      'id': 'conversation',
      'icon': Icons.chat_rounded,
      'title': 'Conversation',
      'desc': 'Talk to learn',
    },
    {
      'id': 'mixed',
      'icon': Icons.shuffle_rounded,
      'title': 'Mixed',
      'desc': 'Variety of methods',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStyle = useState<String?>(null);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.sunset,
      isLightBackground: true,
      characterIcon: Icons.music_note_rounded,
      characterName: 'Nuru the Rhythm Master',
      dialogue: 'Language is music, traveler.\nEach soul dances differently.',
      question: 'How does your spirit best receive knowledge?',
      avatarStep: OnboardingStep.learningStyle,
      child: Column(
        children: [
          // `shrinkWrap` + `NeverScrollableScrollPhysics` sizes this grid to
          // its own content instead of needing an `Expanded` ancestor -
          // `_CharacterStepTemplate` now owns the single scrollable that
          // this whole step scrolls within.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: PanAfricanSpacing.sm.w,
              mainAxisSpacing: PanAfricanSpacing.sm.h,
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
    {
      'id': 'sunrise',
      'icon': Icons.wb_twilight_rounded,
      'label': 'Sunrise',
      'time': '6-9 AM',
    },
    {
      'id': 'midday',
      'icon': Icons.wb_sunny_rounded,
      'label': 'Midday',
      'time': '12-2 PM',
    },
    {
      'id': 'sunset',
      'icon': Icons.nights_stay_rounded,
      'label': 'Sunset',
      'time': '5-7 PM',
    },
    {
      'id': 'night',
      'icon': Icons.bedtime_rounded,
      'label': 'Night',
      'time': '8-10 PM',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = useState(15);
    final selectedTime = useState<String?>(null);
    final remindersEnabled = useState(true);

    return _CharacterStepTemplate(
      gradient: PanAfricanGradients.earth,
      isLightBackground: true,
      characterIcon: Icons.schedule_rounded,
      characterName: 'Kofi the Timekeeper',
      dialogue:
          'Time is the gift we give ourselves.\nHow much will you invest?',
      question: 'When and how long shall we train?',
      avatarStep: OnboardingStep.schedule,
      // `_CharacterStepTemplate` now owns the single scrollable this step
      // (and its header above) scrolls within, so this no longer needs its
      // own nested `SingleChildScrollView`; the time grid below is already
      // `shrinkWrap`-sized rather than `Expanded`.
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            child: Column(
              children: [
                // Duration slider
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // `Flexible` + ellipsis keeps this label from
                          // forcing a `RenderFlex` overflow in this fixed-
                          // width row at larger text scales or on
                          // narrower devices; the minutes value (the
                          // slider's actual live readout) keeps its full,
                          // unclipped width since it's the more important
                          // of the two to always show in full.
                          Flexible(
                            child: Text(
                              'Daily Goal',
                              style: TextStyle(
                                color: PanAfricanColors.textPrimary.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: PanAfricanSpacing.sm.w),
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
                      SizedBox(height: PanAfricanSpacing.sm.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: PanAfricanColors.secondary,
                          inactiveTrackColor: PanAfricanColors.textPrimary
                              .withValues(alpha: 0.2),
                          thumbColor: PanAfricanColors.secondary,
                          overlayColor: PanAfricanColors.secondary.withValues(
                            alpha: 0.2,
                          ),
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
                          Text(
                            '5 min',
                            style: TextStyle(
                              color: PanAfricanColors.textPrimary.withValues(
                                alpha: 0.54,
                              ),
                              fontSize: 12.sp,
                            ),
                          ),
                          Text(
                            '60 min',
                            style: TextStyle(
                              color: PanAfricanColors.textPrimary.withValues(
                                alpha: 0.54,
                              ),
                              fontSize: 12.sp,
                            ),
                          ),
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
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: PanAfricanSpacing.sm.w,
              mainAxisSpacing: PanAfricanSpacing.sm.h,
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
          SizedBox(height: PanAfricanSpacing.xs.h),
          // Reminders toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            child: SwitchListTile(
              title: Text(
                'Enable Daily Reminders',
                style: TextStyle(
                  color: PanAfricanColors.textPrimary,
                  fontSize: 14.sp,
                ),
              ),
              value: remindersEnabled.value,
              onChanged: (v) => remindersEnabled.value = v,
              activeThumbColor: PanAfricanColors.secondary,
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
                await prefs.setBool(
                  'reminders_enabled',
                  remindersEnabled.value,
                );
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
          SizedBox(height: PanAfricanSpacing.md.h),
        ],
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
    {
      'id': 'playful',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'label': 'Playful',
      'desc': 'Fun & light',
    },
    {
      'id': 'encouraging',
      'icon': Icons.thumb_up_rounded,
      'label': 'Encouraging',
      'desc': 'Supportive',
    },
    {
      'id': 'serious',
      'icon': Icons.psychology_rounded,
      'label': 'Focused',
      'desc': 'Direct & efficient',
    },
    {
      'id': 'friendly',
      'icon': Icons.emoji_people_rounded,
      'label': 'Friendly',
      'desc': 'Warm & casual',
    },
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
      isLightBackground: true,
      characterIcon: Icons.campaign_rounded,
      characterName: 'Amara the Griot',
      dialogue: 'I am the storyteller, the voice\nthat guides your journey.',
      question: 'How shall I speak to you?',
      avatarStep: OnboardingStep.story,
      // `_CharacterStepTemplate` now owns the single scrollable this step
      // (and its header above) scrolls within, so this no longer needs its
      // own nested `SingleChildScrollView`. The horizontal tone-row
      // `SingleChildScrollView` below is unrelated (it scrolls sideways).
      child: Column(
        children: [
          // Tone selection
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Style',
                  style: TextStyle(
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
              ],
            ),
          ),
          // `_ToneCard` is an icon plus two lines of text with no slack
          // budget, so a fixed `SizedBox` height (tuned for 1.0x text
          // scale) overflows once a learner's OS text-scale setting grows
          // the label/description lines. `SingleChildScrollView` + `Row`
          // (there are only 4 tones, so no list virtualization is needed)
          // sizes this row to its own content's height instead, so it
          // never clips or overflows at any text scale.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            child: Row(
              children: [
                for (final tone in _tones)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: PanAfricanSpacing.sm.w,
                    ),
                    child: _ToneCard(
                      icon: tone['icon'] as IconData,
                      label: tone['label'] as String,
                      description: tone['desc'] as String,
                      isSelected: selectedTone.value == tone['id'],
                      onTap: () {
                        HapticFeedback.selectionClick();
                        selectedTone.value = tone['id'] as String;
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          // Gamification level
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gamification Level',
                  style: TextStyle(
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                ..._gamificationLevels.map((level) {
                  final isSelected = selectedGamification.value == level['id'];
                  final levelLabel = level['label'] as String;
                  final levelDesc = level['desc'] as String;
                  return Padding(
                    padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm.h),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: isSelected
                          ? '$levelLabel, $levelDesc, selected'
                          : '$levelLabel, $levelDesc',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            selectedGamification.value = level['id'] as String;
                          },
                          borderRadius: BorderRadius.circular(
                            PanAfricanRadius.md,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AdaptiveLayout.minTouchTarget,
                            ),
                            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? PanAfricanColors.secondary.withValues(
                                      alpha: 0.2,
                                    )
                                  : PanAfricanColors.textPrimary.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(
                                PanAfricanRadius.md,
                              ),
                              // `PanAfricanColors.secondary` (gold) is
                              // ~1.5:1 against this row's light background -
                              // below WCAG 1.4.11's 3:1 non-text minimum for
                              // a selection border/icon; the brand's dark
                              // green stays ~5.5:1 here instead - same fix
                              // as the `_LanguageCard`/`_ReasonCard`/etc.
                              // selection cards above.
                              border: Border.all(
                                color: isSelected
                                    ? PanAfricanColors.primary
                                    : PanAfricanColors.textPrimary.withValues(
                                        alpha: 0.2,
                                      ),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level['label'] as String,
                                        style: TextStyle(
                                          color: PanAfricanColors.textPrimary,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        level['desc'] as String,
                                        // This step is a light `sunset`
                                        // gradient (`isLightBackground:
                                        // true` above); `colorScheme.
                                        // onPrimary` is for the app's *dark*
                                        // primary surfaces and was missed in
                                        // the earlier contrast pass - fixed
                                        // to the same fixed dark text token
                                        // used by every other label here.
                                        style: TextStyle(
                                          color: PanAfricanColors.textPrimary
                                              .withValues(alpha: 0.7),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: PanAfricanColors.primary,
                                    size: 24.sp,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          _ContinueButton(
            enabled: selectedTone.value != null,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_tone', selectedTone.value!);
                await prefs.setString(
                  'gamification_level',
                  selectedGamification.value!,
                );
              } catch (e) {
                logger.error('Error saving tone/gamification', error: e);
              }
              onNext({
                'app_tone': selectedTone.value,
                'gamification_level': selectedGamification.value,
              });
            },
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
        ],
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

    final canComplete =
        username.value.isNotEmpty &&
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
          SizedBox(height: PanAfricanSpacing.md.h),
          // Avatar
          GestureDetector(
            onTap: pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55.r,
                  backgroundColor: PanAfricanColors.secondary.withValues(
                    alpha: 0.3,
                  ),
                  backgroundImage: avatarPath.value != null
                      ? FileImage(File(avatarPath.value!))
                      : null,
                  child: avatarPath.value == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 50.sp,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.xs.w),
                    decoration: const BoxDecoration(
                      color: PanAfricanColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xs.h),
          Text(
            'Tap to add photo (optional)',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          // Username field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg.w),
            child: TextField(
              controller: usernameController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18.sp,
              ),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
                hintText: 'Enter your username',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.38),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  borderSide: const BorderSide(
                    color: PanAfricanColors.secondary,
                    width: 2,
                  ),
                ),
                suffixIcon: isChecking.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: Padding(
                          padding: EdgeInsets.all(PanAfricanSpacing.sm.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
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
          // `Spacer()` required a bounded-height `Column` to push this
          // button to the bottom of the screen; `_CharacterStepTemplate`'s
          // header+content now scroll together as one unbounded-height
          // unit, which `Spacer`/`Expanded` can't live inside. A fixed gap
          // keeps the button directly below the form instead.
          SizedBox(height: PanAfricanSpacing.xl.h),
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
        return const Icon(
          Icons.check_circle_rounded,
          color: PanAfricanColors.success,
        );
      case _UsernameStatus.taken:
        return const Icon(Icons.cancel_rounded, color: PanAfricanColors.error);
      case _UsernameStatus.tooShort:
      case _UsernameStatus.tooLong:
      case _UsernameStatus.invalidFormat:
        return const Icon(
          Icons.warning_rounded,
          color: PanAfricanColors.warning,
        );
      default:
        return null;
    }
  }

  String? _getUsernameHelperText(_UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.initial:
        return 'Use 3 to 30 letters, numbers, or underscores';
      case _UsernameStatus.checking:
        return 'Checking if that name is free...';
      case _UsernameStatus.available:
        return 'That name is yours';
      case _UsernameStatus.taken:
        return "Someone's already using that one, try another";
      case _UsernameStatus.tooShort:
        return 'Needs at least 3 characters';
      case _UsernameStatus.tooLong:
        return 'Keep it to 30 characters or fewer';
      case _UsernameStatus.invalidFormat:
        return 'Only letters, numbers, and underscores, please';
      case _UsernameStatus.error:
        return "We couldn't check that just now, but you can still continue";
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
        return Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7);
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

  /// `PanAfricanGradients.earth`/`sunset` are fixed, theme-independent
  /// near-white tints (they don't darken in dark mode). Pairing them with
  /// `colorScheme.onPrimary` - meant for the app's *dark* primary surfaces -
  /// produces ~1.05:1 text contrast (needs 4.5:1), making dialogue
  /// effectively invisible. Steps on a light/pale [gradient] must set this
  /// to `true` so text/icons use a fixed dark color instead; steps on a
  /// genuinely dark gradient (e.g. `forest`) leave this `false` and keep
  /// using the theme's `onPrimary`, which is designed for dark surfaces.
  final bool isLightBackground;

  const _CharacterStepTemplate({
    required this.gradient,
    required this.characterIcon,
    required this.characterName,
    required this.dialogue,
    required this.question,
    required this.child,
    this.avatarStep,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    // PanAfricanColors.textPrimary/textSecondary are the same file's fixed
    // dark text tokens (not theme-aware), matching the fixed, theme-aware
    // gradients they pair with here: textPrimary vs earth/sunset computes to
    // ~16-17:1 contrast and textSecondary to ~6.5-6.8:1, both comfortably
    // above the 4.5:1 WCAG AA body-text threshold.
    final Color foregroundColor = isLightBackground
        ? PanAfricanColors.textPrimary
        : Theme.of(context).colorScheme.onPrimary;
    final Color mutedForegroundColor = isLightBackground
        ? PanAfricanColors.textSecondary
        : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85);
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: ResponsiveSafeArea(
        // This avatar+dialogue header is fixed, non-collapsing chrome sitting
        // above `child`. At large system text-scale settings (e.g. the
        // ~200% Android/iOS accessibility maximum - a real, reachable
        // setting, not a hypothetical edge case) the dialogue/question text
        // grows uncapped, and the header's own natural height alone can
        // exceed the full screen height before `child` even starts. An
        // `Expanded` sibling can't claim negative space, so a plain `Column`
        // here overflowed instead of letting the learner scroll to see the
        // rest - on every one of this template's 8 steps, not just one.
        // Scrolling the *whole* header+content column as a single unit
        // (the same approach already used for this step's own body - see
        // `_ElderQuestionStep`) fixes this for every device size and every
        // text scale. Every step's `child` was updated to match: a plain,
        // non-expanding `Column` (shrink-wrapped grids/lists instead of
        // `Expanded` + their own separate scrollable), since only one
        // scrollable should own the vertical axis here.
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: PanAfricanSpacing.xl.h),
              // Character avatar: use OnboardingAvatarWidget when step is provided
              Semantics(
                label: '$characterName, your guide for this step',
                image: true,
                child: ExcludeSemantics(
                  child: avatarStep != null
                      ? SizedBox(
                          // OnboardingAvatarWidget always renders a name/title
                          // caption beneath the portrait, needing far more
                          // height than this compact per-step header can
                          // spare (the language/goal/schedule content below
                          // needs that room instead). `OverflowBox` gives the
                          // widget the extra height it wants to lay itself out
                          // without tripping its own internal RenderFlex
                          // overflow assertion, and `ClipRect` then crops the
                          // result back down to exactly the portrait — instead
                          // of the pre-existing behaviour, where a plain
                          // `SizedBox` here produced a debug-only overflow
                          // warning while still painting the caption text
                          // bleeding into the dialogue panel below in release
                          // builds.
                          width: 100.w,
                          height: 100.w,
                          child: ClipRect(
                            child: OverflowBox(
                              maxHeight: double.infinity,
                              alignment: Alignment.topCenter,
                              child: OnboardingAvatarWidget(
                                step: avatarStep!,
                                size: 100.w,
                                animate: true,
                              ),
                            ),
                          ),
                        ).animate().scale(
                          duration: _motionDuration(context, 400.ms),
                          curve: Curves.easeOut,
                        )
                      : Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: foregroundColor.withValues(alpha: 0.15),
                            border: Border.all(
                              color: foregroundColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            characterIcon,
                            size: 50.sp,
                            color: foregroundColor,
                          ),
                        ).animate().scale(
                          duration: _motionDuration(context, 400.ms),
                          curve: Curves.easeOut,
                        ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm.h),
              // Dialogue + Question panel
              Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.lg.w,
                    ),
                    child: Semantics(
                      label: '$characterName says: $dialogue $question',
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 18.h,
                        ),
                        decoration: BoxDecoration(
                          color: foregroundColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            PanAfricanRadius.lg,
                          ),
                          border: Border.all(
                            color: foregroundColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Column(
                            children: [
                              Text(
                                dialogue,
                                textAlign: TextAlign.center,
                                style: PanAfricanTypography.headlineSmall(
                                  context,
                                  color: foregroundColor,
                                ).copyWith(height: 1.3),
                              ),
                              SizedBox(height: PanAfricanSpacing.sm.h),
                              Text(
                                question,
                                textAlign: TextAlign.center,
                                style: PanAfricanTypography.bodyMedium(
                                  context,
                                  color: mutedForegroundColor,
                                ).copyWith(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: _motionDelay(context, 300.ms),
                    duration: _motionDuration(context, 300.ms),
                  )
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: _motionDuration(context, 300.ms),
                  ),
              SizedBox(height: PanAfricanSpacing.md.h),
              // Content
              child,
            ],
          ),
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected ? '$name, selected' : name,
      // Without this, the explicit label above merges with the child
      // Row's own flag-emoji and name `Text` semantics into one messy,
      // duplicated node instead of the clean label set here.
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AdaptiveLayout.minTouchTarget,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? PanAfricanColors.secondary.withValues(alpha: 0.25)
                  : PanAfricanColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              // `PanAfricanColors.secondary` (gold) is ~1.5:1 against this
              // card's light background - below WCAG 1.4.11's 3:1 non-text
              // minimum for a selection border/icon. The brand's dark green
              // stays ~5.5:1 here instead; see `_GoalCard.selectedAccent`
              // for the equivalent fix on a shared light/dark card.
              border: Border.all(
                color: isSelected
                    ? PanAfricanColors.primary
                    : PanAfricanColors.textPrimary.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.2 : 0.12,
                  ),
                  blurRadius: isSelected ? 16 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(flag, style: TextStyle(fontSize: 28.sp)),
                SizedBox(width: PanAfricanSpacing.sm.w),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: PanAfricanColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(width: PanAfricanSpacing.xs.w),
                  Icon(
                    Icons.check_circle_rounded,
                    color: PanAfricanColors.primary,
                    size: 18.sp,
                  ),
                ],
              ],
            ),
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected ? '$name, $region, selected' : '$name, $region',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AdaptiveLayout.minTouchTarget,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md.w,
              vertical: 14.h,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                  : PanAfricanColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              // `PanAfricanColors.secondary` (gold) is ~1.5:1 against this
              // tile's light background - below WCAG 1.4.11's 3:1 non-text
              // minimum for a selection border/icon; the brand's dark green
              // stays ~5.5:1 here instead.
              border: Border.all(
                color: isSelected
                    ? PanAfricanColors.primary
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.18 : 0.12,
                  ),
                  blurRadius: isSelected ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(flag, style: TextStyle(fontSize: 32.sp)),
                SizedBox(width: PanAfricanSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: PanAfricanColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        region,
                        style: TextStyle(
                          color: PanAfricanColors.textPrimary.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? PanAfricanColors.primary
                      : PanAfricanColors.textPrimary.withValues(alpha: 0.54),
                  size: 24.sp,
                ),
              ],
            ),
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected ? '$label, selected' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AdaptiveLayout.minTouchTarget,
              minWidth: AdaptiveLayout.minTouchTarget,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? PanAfricanColors.secondary.withValues(alpha: 0.25)
                  : PanAfricanColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              // `PanAfricanColors.secondary` (gold) is ~1.5:1 against this
              // card's light background - below WCAG 1.4.11's 3:1 non-text
              // minimum for a selection border/icon; the brand's dark green
              // stays ~5.5:1 here instead.
              border: Border.all(
                color: isSelected
                    ? PanAfricanColors.primary
                    : PanAfricanColors.textPrimary.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.2 : 0.12,
                  ),
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
                        ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                        : PanAfricanColors.textPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? PanAfricanColors.primary
                        : PanAfricanColors.textPrimary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs.h),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.xxs.w,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: PanAfricanColors.textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Goal card
class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  /// `_GoalCard` is reused by `_PathChooserStep` (dark `forest` gradient)
  /// directly and, via `_StyleCard`, by `_RhythmMasterStep` (near-white
  /// `sunset` gradient). It can't hardcode either `colorScheme.onPrimary`
  /// (invisible on the light gradient) or a fixed dark color (invisible on
  /// the dark one) - callers on a light background must set this `true`.
  final bool isLightBackground;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = isLightBackground
        ? PanAfricanColors.textPrimary
        : Theme.of(context).colorScheme.onPrimary;
    // `PanAfricanColors.secondary` (gold) is ~1.5:1 against the light
    // gradients - swap the selected-state accent for the brand's dark
    // green on light backgrounds instead, which stays ~5.5:1.
    final Color selectedAccent = isLightBackground
        ? PanAfricanColors.primary
        : PanAfricanColors.secondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected
          ? '$title, $description, selected'
          : '$title, $description',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AdaptiveLayout.minTouchTarget,
            ),
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xxs.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                  : baseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              border: Border.all(
                color: isSelected
                    ? selectedAccent
                    : baseColor.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.2 : 0.12,
                  ),
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
                        ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                        : baseColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? selectedAccent : baseColor,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xs.h),
                Text(
                  title,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: PanAfricanSpacing.xxxs.h),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: baseColor.withValues(alpha: 0.6),
                    fontSize: 11.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
  }) : super(isLightBackground: true);
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected ? '$label, $time, selected' : '$label, $time',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AdaptiveLayout.minTouchTarget,
            ),
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                  : PanAfricanColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              // `PanAfricanColors.secondary` (gold) is ~1.5:1 against this
              // card's light background - below WCAG 1.4.11's 3:1 non-text
              // minimum for a selection border/icon; the brand's dark green
              // stays ~5.5:1 here instead.
              border: Border.all(
                color: isSelected
                    ? PanAfricanColors.primary
                    : PanAfricanColors.textPrimary.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.2 : 0.12,
                  ),
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
                        ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                        : PanAfricanColors.textPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? PanAfricanColors.primary
                        : PanAfricanColors.textPrimary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.sm.w),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: PanAfricanColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: PanAfricanColors.textPrimary.withValues(
                            alpha: 0.54,
                          ),
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected
          ? '$label, $description, selected'
          : '$label, $description',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          child: Container(
            width: 100.w,
            constraints: const BoxConstraints(
              minHeight: AdaptiveLayout.minTouchTarget,
            ),
            padding: EdgeInsets.all(PanAfricanSpacing.sm.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                  : PanAfricanColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              // `PanAfricanColors.secondary` (gold) is ~1.5:1 against this
              // card's light background - below WCAG 1.4.11's 3:1 non-text
              // minimum for a selection border/icon; the brand's dark green
              // stays ~5.5:1 here instead.
              border: Border.all(
                color: isSelected
                    ? PanAfricanColors.primary
                    : PanAfricanColors.textPrimary.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.2 : 0.12,
                  ),
                  blurRadius: isSelected ? 16 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PanAfricanColors.secondary.withValues(alpha: 0.2)
                        : PanAfricanColors.textPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? PanAfricanColors.primary
                        : PanAfricanColors.textPrimary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs.h),
                Text(
                  label,
                  style: TextStyle(
                    color: PanAfricanColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: PanAfricanColors.textPrimary.withValues(alpha: 0.54),
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
