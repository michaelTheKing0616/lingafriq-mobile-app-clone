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
import 'dart:math' as math;

import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/games_learning_language_preload.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:lingafriq/models/onboarding_answers.dart';
import 'placement_test_screen.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/providers/tts_provider.dart';

/// Documented Modern Griot opacity roles — never invent ad-hoc alphas in UI.
abstract final class _GriotAlpha {
  /// Ghost border for inputs / quiet outlines (design system rule 3).
  static const double ghostBorder = 0.15;

  /// Soft selected fill over brandGold.
  static const double softSelected = 0.18;

  /// Selected chip / filter fill over brandGold.
  static const double chipSelected = 0.35;

  /// Progress track under coral fill.
  static const double progressTrack = 0.12;

  /// Back / icon button wash.
  static const double iconWash = 0.08;

  /// Gold accent border on value cards.
  static const double goldBorder = 0.55;

  /// Completing overlay scrim on onSurface.
  static const double completingScrim = 0.72;

  /// Quiet label wash when CTA disabled.
  static const double disabledLabel = 0.5;

  /// Signal-bar empty segment.
  static const double signalEmpty = 0.45;

  /// Ask-a-parent panel wash on primaryContainer.
  static const double parentPanel = 0.45;
}

/// Mirrors server `agePolicy` default thresholds (P1-020).
/// Child threshold is configurable per country (default 13, DE 16).
/// Do NOT hard-code Nigeria to 18 — NDPA under-18 remains a counsel question.
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

/// Display name + first-lesson greeting keyed by learning-language code.
({String name, String hear, String tap, String say, String reminder})
    _lessonCopyFor(String code) {
  switch (code) {
    case 'ha':
      return (
        name: 'Hausa',
        hear: 'Sannu',
        tap: 'Sannu',
        say: 'Sannu, Hello',
        reminder: 'Sannu! 5 minutes of Hausa?',
      );
    case 'ig':
      return (
        name: 'Igbo',
        hear: 'Ndewo',
        tap: 'Ndewo',
        say: 'Ndewo, Hello',
        reminder: 'Ndewo! 5 minutes of Igbo?',
      );
    case 'sw':
      return (
        name: 'Swahili',
        hear: 'Habari',
        tap: 'Habari',
        say: 'Habari, Hello',
        reminder: 'Habari! 5 minutes of Swahili?',
      );
    case 'am':
      return (
        name: 'Amharic',
        hear: 'ሰላም',
        tap: 'ሰላም',
        say: 'ሰላም, Hello',
        reminder: 'ሰላም! 5 minutes of Amharic?',
      );
    case 'zu':
      return (
        name: 'Zulu',
        hear: 'Sawubona',
        tap: 'Sawubona',
        say: 'Sawubona, Hello',
        reminder: 'Sawubona! 5 minutes of Zulu?',
      );
    default:
      return (
        name: 'Yoruba',
        hear: 'Báwo',
        tap: 'Báwo ni',
        say: 'Báwo, Hello',
        reminder: 'Ẹ kú àárọ̀! 5 minutes of Yoruba?',
      );
  }
}

Duration _motionDuration(BuildContext context, Duration normal) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

Duration _motionDelay(BuildContext context, Duration normal) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

/// Unified Onboarding — reference-led flow (Finch + Speak + Duolingo + Opal + Headspace).
///
/// Recipe order (second pass): Welcome → Language → Goal(+daily) → Level →
/// First win → Account/age/sign-in → Notifications → remaining prefs → profile.
/// All existing onboarding answer keys are preserved and wired through
/// SharedPreferences + onboarding_provider + outbox sync.
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

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    final stepCount = <int>[0];
    // All redesigned steps sit on warm parchment (Modern Griot surface) so
    // chrome uses dark on-surface tokens for AA contrast.
    final stepsLight = <bool>[];
    final stepsAllowSkip = <bool>[];
    final steps = <Widget>[];

    void addStep(Widget step, {bool light = true, bool allowSkip = false}) {
      stepsLight.add(light);
      stepsAllowSkip.add(allowSkip);
      steps.add(step);
    }

    if (reask.isEmpty) {
      addStep(
        _WelcomeStep(
          onNext: () => _goToNext(
            context,
            pageController,
            currentStep,
            animationController,
          ),
          onHaveAccount: () {
            ref
                .read(navigationProvider)
                .navigateOffAll(const WorldClassLoginScreen());
          },
        ),
        allowSkip: true,
      );
    }

    if (ask(const ['proficiency_language', 'learning_language'])) {
      addStep(
        _LanguagePickStep(
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
        allowSkip: true,
      );
    }

    if (ask(const [
      'primary_goal',
      'learning_reasons',
      'daily_duration_minutes',
    ])) {
      addStep(
        _GoalStep(
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
        allowSkip: true,
      );
    }

    if (ask(const ['learning_style']) || reask.isEmpty) {
      addStep(
        _LevelPlacementStep(
          learningLanguage:
              onboardingData.value['learning_language'] as String? ?? 'yo',
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
      );
    }

    if (reask.isEmpty) {
      addStep(
        _FirstWinStep(
          learningLanguage:
              onboardingData.value['learning_language'] as String? ?? 'yo',
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
      );
    }

    if (ask(const ['age_category', 'learning_reasons']) ||
        ask(const ['age_category'])) {
      addStep(
        _AccountAgeStep(
          existingReasons:
              (onboardingData.value['learning_reasons'] as List?)
                  ?.cast<String>() ??
              const <String>[],
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
          onSignIn: () {
            ref
                .read(navigationProvider)
                .navigateOffAll(const WorldClassLoginScreen());
          },
        ),
      );
    }

    if (ask(const [
      'daily_duration_minutes',
      'preferred_time_of_day',
      'reminders_enabled',
    ])) {
      addStep(
        _NotificationsStep(
          dailyMinutes:
              onboardingData.value['daily_duration_minutes'] as int? ?? 10,
          learningLanguage:
              onboardingData.value['learning_language'] as String? ?? 'yo',
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
      );
    }

    // Remaining prefs after first win + account + notifications (recipe order).
    if (ask(const ['learning_style'])) {
      addStep(
        _LearningStyleStep(
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
      );
    }

    if (ask(const ['app_tone', 'gamification_level'])) {
      addStep(
        _ToneStep(
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
      );
    }

    if (reask.isEmpty) {
      addStep(
        _ProfileStep(
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
          onSkip: () async {
            if (isCompleting.value) return;
            isCompleting.value = true;
            try {
              await _completeOnboarding(onboardingData.value, context, ref);
            } finally {
              isCompleting.value = false;
            }
          },
        ),
      );
    }

    stepCount[0] = steps.length;
    final totalSteps = steps.length;

    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
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
            if (totalSteps > 0)
              _buildProgressIndicator(
                context,
                ref,
                currentStep.value,
                totalSteps,
                isLightBackground: stepsLight[currentStep.value],
                allowSkip: stepsAllowSkip[currentStep.value],
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
            if (isCompleting.value)
              Positioned.fill(
                child: Semantics(
                  liveRegion: true,
                  label: 'Setting up your language village, please wait',
                  child: Container(
                    color: ModernGriotColors.onSurface.withValues(
                      alpha: _GriotAlpha.completingScrim,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: ModernGriotSpacing.xl.w,
                            height: ModernGriotSpacing.xl.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ModernGriotColors.brandGold,
                              ),
                            ),
                          ),
                          SizedBox(height: ModernGriotSpacing.md.h),
                          Text(
                            'Preparing your village...',
                            style: ModernGriotTypography.bodyMedium(
                              context: context,
                              color: ModernGriotColors.surface,
                            ),
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
    required bool allowSkip,
    VoidCallback? onBack,
    VoidCallback? onSkip,
  }) {
    final Color foregroundColor = isLightBackground
        ? ModernGriotColors.onSurface
        : ModernGriotColors.surface;
    final Color progressFillColor = ModernGriotColors.brandCoral;
    return Positioned(
      top: MediaQuery.of(context).padding.top + ModernGriotSpacing.xxs.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.sm.w),
        child: Row(
          children: [
            if (onBack != null)
              Semantics(
                label: 'Go back to the previous step',
                button: true,
                child: IconButton(
                  onPressed: onBack,
                  icon: IconTheme(
                    data: IconThemeData(color: foregroundColor, size: ModernGriotSpacing.lg.sp),
                    child: const BackButtonIcon(),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: foregroundColor.withValues(
                      alpha: _GriotAlpha.iconWash,
                    ),
                    minimumSize: const Size(
                      ModernGriotLayout.minTouchTarget,
                      ModernGriotLayout.minTouchTarget,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: ModernGriotLayout.minTouchTarget.w),
            Expanded(
              child: Semantics(
                label: 'Onboarding progress',
                value: 'Step ${current + 1} of $total',
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.xs.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final progress = total == 0
                            ? 0.0
                            : ((current + 1) / total).clamp(0.0, 1.0);
                        return Stack(
                          children: [
                            Container(
                              height: ModernGriotSpacing.xxs.h,
                              color: foregroundColor.withValues(
                                alpha: _GriotAlpha.progressTrack,
                              ),
                            ),
                            AnimatedContainer(
                              duration: _motionDuration(
                                context,
                                const Duration(milliseconds: 300),
                              ),
                              height: ModernGriotSpacing.xxs.h,
                              width: constraints.maxWidth * progress,
                              color: progressFillColor,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (allowSkip)
              Semantics(
                label: 'Skip onboarding',
                button: true,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      ModernGriotLayout.minTouchTarget,
                      ModernGriotLayout.minTouchTarget,
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: ModernGriotTypography.labelLarge(
                      context: context,
                      color: foregroundColor,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: ModernGriotLayout.minTouchTarget.w),
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
          backgroundColor: ModernGriotColors.onSurface,
          content: Text(
            "You're offline right now, but we've saved your answers and "
            'will sync them the moment you reconnect.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.surface,
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    final learningLanguage = data['learning_language'] as String?;
    if (learningLanguage != null &&
        context.mounted &&
        data['self_reported_level'] == 'unsure') {
      try {
        final alreadyPrompted =
            prefs.getBool('placement_test_prompt_shown') ?? false;
        if (!alreadyPrompted) {
          final shouldTakeTest = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: ModernGriotColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
                ),
                title: Text(
                  'Take a quick placement test?',
                  style: ModernGriotTypography.titleLarge(
                    context: dialogContext,
                    color: ModernGriotColors.onSurface,
                  ),
                ),
                content: Text(
                  "We'll ask a few short questions to find your starting "
                  'level in $learningLanguage. You can always take it later '
                  'from your profile.',
                  style: ModernGriotTypography.bodyMedium(
                    context: dialogContext,
                    color: ModernGriotColors.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Maybe later',
                      style: ModernGriotTypography.labelLarge(
                        context: dialogContext,
                        color: ModernGriotColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: ModernGriotColors.brandGold,
                      foregroundColor: ModernGriotColors.onBrandGold,
                      minimumSize: const Size(
                        ModernGriotLayout.minTouchTarget,
                        ModernGriotLayout.minTouchTarget,
                      ),
                    ),
                    child: const Text('Take the test'),
                  ),
                ],
              );
            },
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
// Shared chrome
// =============================================================================

/// Clips Polie to a fixed square so the avatar's internal column cannot
/// overflow speech-bubble rows on phone-sized layouts.
class _PolieBadge extends StatelessWidget {
  const _PolieBadge({
    required this.step,
    this.size,
  });

  final OnboardingStep step;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final side = size ?? ModernGriotSpacing.xxxl.w;
    return SizedBox(
      width: side,
      height: side,
      child: ClipRect(
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: OnboardingAvatarWidget(
            step: step,
            size: side,
            animate: true,
            showDialogue: false,
          ),
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.child,
    this.bottom,
  });

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernGriotColors.surface,
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            SizedBox(height: ModernGriotSpacing.xxl.h),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.lg.w),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.color = ModernGriotColors.brandGold,
    this.foreground = ModernGriotColors.onBrandGold,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(ModernGriotSpacing.lg.w, ModernGriotSpacing.xs.h, ModernGriotSpacing.lg.w, ModernGriotSpacing.md.h),
      child: SizedBox(
        width: double.infinity,
        height: math.max(ModernGriotLayout.minTouchTarget.h, ModernGriotLayout.minTouchTarget.toDouble()),
        child: FilledButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed?.call();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: ModernGriotColors.surfaceContainerHighest,
            disabledForegroundColor: ModernGriotColors.onSurfaceVariant
                .withValues(alpha: _GriotAlpha.disabledLabel),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
            textStyle: ModernGriotTypography.titleMedium(context: context),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.height = ModernGriotLayout.selectRowMin,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;

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
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
          child: AnimatedContainer(
            duration: _motionDuration(context, 180.ms),
            constraints: BoxConstraints(
              minHeight: math.max(height.h, ModernGriotLayout.minTouchTarget.toDouble()),
            ),
            margin: EdgeInsets.only(bottom: ModernGriotSpacing.sm.h),
            padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.md.w, vertical: ModernGriotSpacing.sm.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? ModernGriotColors.brandGold.withValues(
                      alpha: _GriotAlpha.softSelected,
                    )
                  : ModernGriotColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
              border: Border.all(
                color: isSelected
                    ? ModernGriotColors.brandCoral
                    : ModernGriotColors.outlineVariant.withValues(
                        alpha: _GriotAlpha.ghostBorder,
                      ),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: ModernGriotSpacing.sm.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: ModernGriotTypography.titleMedium(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                            color: ModernGriotColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: ModernGriotColors.brandCoral,
                    size: ModernGriotSpacing.lg.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. Welcome — Finch mascot + Speak promise (Polie ~55%)
// =============================================================================

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext, required this.onHaveAccount});

  final VoidCallback onNext;
  final VoidCallback onHaveAccount;

  Widget _poliePlane(BuildContext context, double side) {
    return Semantics(
      label:
          'LingAfriq. Speak African languages with confidence. '
          'Learn with Polie. Works offline.',
      child: ExcludeSemantics(
        child: Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ClipRect(
              child: OverflowBox(
                maxHeight: double.infinity,
                alignment: Alignment.topCenter,
                child: OnboardingAvatarWidget(
                  step: OnboardingStep.welcome,
                  size: side,
                  animate: true,
                  showDialogue: false,
                ),
              ),
            ),
          )
              .animate()
              .scale(
                delay: _motionDelay(context, 200.ms),
                duration: _motionDuration(context, 600.ms),
                curve: Curves.easeOut,
              )
              .fadeIn(duration: _motionDuration(context, 500.ms)),
        ),
      ),
    );
  }

  List<Widget> _copyAndActions(BuildContext context) {
    return [
      Text(
        'Welcome to',
        textAlign: TextAlign.center,
        style: ModernGriotTypography.titleMedium(
          context: context,
          color: ModernGriotColors.onSurfaceVariant,
        ),
      ).animate().fadeIn(
        delay: _motionDelay(context, 400.ms),
        duration: _motionDuration(context, 300.ms),
      ),
      SizedBox(height: ModernGriotSpacing.xxs.h),
      Text(
        'LingAfriq',
        textAlign: TextAlign.center,
        style: ModernGriotTypography.displaySmall(
          context: context,
          color: ModernGriotColors.onSurface,
        ).copyWith(height: 1.05),
      ),
      SizedBox(height: ModernGriotSpacing.xs.h),
      Text(
        'The language village that gets you speaking.',
        textAlign: TextAlign.center,
        style: ModernGriotTypography.headlineSmall(
          context: context,
          color: ModernGriotColors.onSurface,
        ).copyWith(height: 1.25),
      ),
      SizedBox(height: ModernGriotSpacing.xxs.h),
      Text(
        'Short lessons with Polie. Hear, tap, and say real phrases.',
        textAlign: TextAlign.center,
        style: ModernGriotTypography.bodyMedium(
          context: context,
          color: ModernGriotColors.onSurfaceVariant,
        ),
      ),
      SizedBox(height: ModernGriotSpacing.sm.h),
      Semantics(
        label: 'Works offline, about 2 megabytes per unit',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ModernGriotSpacing.sm.w,
            vertical: ModernGriotSpacing.xxs.h,
          ),
          decoration: BoxDecoration(
            color: ModernGriotColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
          ),
          child: Text(
            'Works offline · about 2 MB per unit',
            textAlign: TextAlign.center,
            style: ModernGriotTypography.labelMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
        ),
      ),
      SizedBox(height: ModernGriotSpacing.md.h),
      SizedBox(
        width: double.infinity,
        height: math.max(
          ModernGriotLayout.minTouchTarget.h,
          ModernGriotLayout.minTouchTarget.toDouble(),
        ),
        child: FilledButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onNext();
          },
          style: FilledButton.styleFrom(
            backgroundColor: ModernGriotColors.brandGold,
            foregroundColor: ModernGriotColors.onBrandGold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
          ),
          child: Text(
            'Get started',
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onBrandGold,
            ),
          ),
        ),
      ).animate().fadeIn(
        delay: _motionDelay(context, 800.ms),
        duration: _motionDuration(context, 300.ms),
      ),
      TextButton(
        onPressed: onHaveAccount,
        style: TextButton.styleFrom(
          minimumSize: const Size(
            ModernGriotLayout.minTouchTarget,
            ModernGriotLayout.minTouchTarget,
          ),
        ),
        child: Text(
          'I already have an account',
          style: ModernGriotTypography.labelLarge(
            context: context,
            color: ModernGriotColors.onSurface,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ModernGriotColors.tertiaryContainer,
            ModernGriotColors.surface,
            ModernGriotColors.surfaceContainerLow,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: ResponsiveSafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final useScroll = textScale >= 1.5;
            final polieSide = math.min(
              constraints.maxWidth - ModernGriotSpacing.lg.w * 2,
              // ~55% of the viewport at default scale; shrink when text grows.
              constraints.maxHeight * (useScroll ? 0.28 : 0.55),
            );

            if (useScroll) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: ModernGriotSpacing.lg.w,
                ),
                child: Column(
                  children: [
                    SizedBox(height: ModernGriotSpacing.xl.h),
                    SizedBox(
                      height: polieSide,
                      width: double.infinity,
                      child: _poliePlane(context, polieSide),
                    ),
                    SizedBox(height: ModernGriotSpacing.md.h),
                    ..._copyAndActions(context),
                    SizedBox(height: ModernGriotSpacing.md.h),
                  ],
                ),
              );
            }

            // Finch/Speak composition: Polie owns the top ~55%; CTA stays on-screen.
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.lg.w),
              child: Column(
                children: [
                  Expanded(
                    flex: 55,
                    child: _poliePlane(context, polieSide),
                  ),
                  ..._copyAndActions(context),
                  SizedBox(height: ModernGriotSpacing.xs.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// 2. Language pick — Duolingo grouped rows
// =============================================================================

class _LanguagePickStep extends HookConsumerWidget {
  const _LanguagePickStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _homeLanguages = [
    {'code': 'en', 'name': 'English', 'script': 'English'},
    {'code': 'fr', 'name': 'French', 'script': 'Français'},
    {'code': 'pt', 'name': 'Portuguese', 'script': 'Português'},
    {'code': 'ar', 'name': 'Arabic', 'script': 'العربية'},
    {'code': 'sw', 'name': 'Swahili', 'script': 'Kiswahili'},
  ];

  static const _learnLanguages = [
    {
      'code': 'yo',
      'name': 'Yoruba',
      'script': 'Èdè Yorùbá',
      'region': 'West Africa',
      'glyph': 'Y',
      'learners': '120k learners',
    },
    {
      'code': 'ha',
      'name': 'Hausa',
      'script': 'Hausa',
      'region': 'West Africa',
      'glyph': 'H',
      'learners': '95k learners',
    },
    {
      'code': 'ig',
      'name': 'Igbo',
      'script': 'Asụsụ Igbo',
      'region': 'West Africa',
      'glyph': 'Ị',
      'learners': '70k learners',
    },
    {
      'code': 'tw',
      'name': 'Twi',
      'script': 'Twi',
      'region': 'West Africa',
      'glyph': 'T',
      'learners': '40k learners',
    },
    {
      'code': 'wo',
      'name': 'Wolof',
      'script': 'Wolof',
      'region': 'West Africa',
      'glyph': 'W',
      'learners': '25k learners',
    },
    {
      'code': 'pcm',
      'name': 'Nigerian Pidgin',
      'script': 'Naijá',
      'region': 'West Africa',
      'glyph': 'N',
      'learners': '80k learners',
    },
    {
      'code': 'sw',
      'name': 'Swahili',
      'script': 'Kiswahili',
      'region': 'East Africa',
      'glyph': 'S',
      'learners': '200k learners',
    },
    {
      'code': 'am',
      'name': 'Amharic',
      'script': 'አማርኛ',
      'region': 'East Africa',
      'glyph': 'አ',
      'learners': '55k learners',
    },
    {
      'code': 'zu',
      'name': 'Zulu',
      'script': 'isiZulu',
      'region': 'Southern Africa',
      'glyph': 'Z',
      'learners': '45k learners',
    },
    {
      'code': 'xh',
      'name': 'Xhosa',
      'script': 'isiXhosa',
      'region': 'Southern Africa',
      'glyph': 'X',
      'learners': '30k learners',
    },
    {
      'code': 'ar-maghreb',
      'name': 'Darija',
      'script': 'الدارجة',
      'region': 'North Africa',
      'glyph': 'د',
      'learners': '35k learners',
    },
    {
      'code': 'ber',
      'name': 'Tamazight',
      'script': 'ⵜⴰⵎⴰⵣⵉⵖⵜ',
      'region': 'North Africa',
      'glyph': 'ⵣ',
      'learners': '20k learners',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLearn = useState<String?>(null);
    // Null until the learner overrides — defaults from device locale in build.
    final selectedHomeOverride = useState<String?>(null);
    final query = useState('');
    final searchController = useTextEditingController();

    final deviceLang =
        Localizations.localeOf(context).languageCode.toLowerCase();
    final deviceHome = _homeLanguages.any((h) => h['code'] == deviceLang)
        ? deviceLang
        : 'en';
    final selectedHome = selectedHomeOverride.value ?? deviceHome;

    final filtered = _learnLanguages.where((lang) {
      final q = query.value.trim().toLowerCase();
      if (q.isEmpty) return true;
      return (lang['name'] as String).toLowerCase().contains(q) ||
          (lang['script'] as String).toLowerCase().contains(q) ||
          (lang['region'] as String).toLowerCase().contains(q);
    }).toList();

    final regions = <String>[];
    for (final lang in filtered) {
      final r = lang['region'] as String;
      if (!regions.contains(r)) regions.add(r);
    }

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selectedLearn.value != null,
        onPressed: () async {
          try {
            await DynamicLocalizationService.setLanguage(selectedHome);
          } catch (e) {
            logger.error('Error setting language', error: e);
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('proficiency_language', selectedHome);
            await prefs.setString('learning_language', selectedLearn.value!);
            scheduleGamesPreloadAfterLearningLanguageSaved(ref);
          } catch (e) {
            logger.error('Error saving languages', error: e);
          }
          onNext({
            'proficiency_language': selectedHome,
            'learning_language': selectedLearn.value,
          });
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PolieBadge(step: OnboardingStep.languageSelection),
              SizedBox(width: ModernGriotSpacing.sm.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(ModernGriotSpacing.sm.w),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
                    border: Border.all(
                      color: ModernGriotColors.outlineVariant.withValues(
                        alpha: _GriotAlpha.ghostBorder,
                      ),
                    ),
                  ),
                  child: Text(
                    'What do you want to learn?',
                    style: ModernGriotTypography.titleLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          Text(
            'I speak',
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final home in _homeLanguages)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: ModernGriotSpacing.xs.w),
                    child: FilterChip(
                      selected: selectedHome == home['code'],
                      label: Text(home['name']!),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        selectedHomeOverride.value = home['code']!;
                      },
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                      selectedColor: ModernGriotColors.brandGold.withValues(
                        alpha: _GriotAlpha.chipSelected,
                      ),
                      checkmarkColor: ModernGriotColors.brandCoral,
                      labelStyle: ModernGriotTypography.labelLarge(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          TextField(
            controller: searchController,
            onChanged: (v) => query.value = v,
            style: ModernGriotTypography.bodyLarge(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search languages',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: ModernGriotColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                borderSide: BorderSide(
                  color: ModernGriotColors.outlineVariant.withValues(
                    alpha: _GriotAlpha.ghostBorder,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                borderSide: BorderSide(
                  color: ModernGriotColors.outlineVariant.withValues(
                    alpha: _GriotAlpha.ghostBorder,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: ModernGriotSpacing.xl.h,
              ),
              child: Semantics(
                liveRegion: true,
                label: 'No languages match your search',
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: ModernGriotSpacing.xl.sp,
                      color: ModernGriotColors.onSurfaceVariant,
                    ),
                    SizedBox(height: ModernGriotSpacing.xs.h),
                    Text(
                      'No languages match that search.',
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.titleMedium(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                    SizedBox(height: ModernGriotSpacing.xxs.h),
                    Text(
                      'Try a region, a script name, or clear the box.',
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: ModernGriotColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final region in regions) ...[
              Text(
                region,
                style: ModernGriotTypography.titleSmall(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: ModernGriotSpacing.xs.h),
              for (final lang in filtered.where((l) => l['region'] == region))
                _SelectRow(
                  height: ModernGriotLayout.selectRowComfortable,
                  label: lang['name'] as String,
                  subtitle: '${lang['script']} · ${lang['learners']}',
                  isSelected: selectedLearn.value == lang['code'],
                  leading: _ScriptGlyphBadge(
                    glyph: lang['glyph'] as String,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedLearn.value = lang['code'] as String;
                  },
                ),
              SizedBox(height: ModernGriotSpacing.xs.h),
            ],
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

class _ScriptGlyphBadge extends StatelessWidget {
  const _ScriptGlyphBadge({required this.glyph});

  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ModernGriotLayout.minTouchTarget.w * 0.75,
      height: ModernGriotLayout.minTouchTarget.w * 0.75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(ModernGriotRadius.md),
        border: Border.all(
          color: ModernGriotColors.outlineVariant.withValues(
            alpha: _GriotAlpha.ghostBorder,
          ),
        ),
      ),
      child: Text(
        glyph,
        style: ModernGriotTypography.titleMedium(
          context: context,
          color: ModernGriotColors.onSurface,
        ).copyWith(height: 1),
      ),
    );
  }
}

// =============================================================================
// 3. Goal + daily time — Finch cards + Headspace clarity
// =============================================================================

class _GoalStep extends HookConsumerWidget {
  const _GoalStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _goals = [
    {
      'id': 'family',
      'icon': Icons.favorite_rounded,
      'title': 'Talk to family',
      'reason': 'family',
    },
    {
      'id': 'travel',
      'icon': Icons.flight_rounded,
      'title': 'Travel',
      'reason': 'travel',
    },
    {
      'id': 'heritage',
      'icon': Icons.diversity_3_rounded,
      'title': 'Heritage and culture',
      'reason': 'heritage',
    },
    {
      'id': 'work',
      'icon': Icons.work_rounded,
      'title': 'Work',
      'reason': 'business',
    },
  ];

  static const _durations = [
    {'min': 5, 'label': 'Casual'},
    {'min': 10, 'label': 'Steady'},
    {'min': 15, 'label': 'Serious'},
    {'min': 20, 'label': 'Intense'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<Set<String>>({});
    final duration = useState(10);

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value.isNotEmpty,
        onPressed: () async {
          final reasons = selected.value
              .map(
                (id) =>
                    _goals.firstWhere((g) => g['id'] == id)['reason'] as String,
              )
              .toList();
          final primary = selected.value.first;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('primary_goal', primary);
            await prefs.setStringList('learning_reasons', reasons);
            await prefs.setInt('daily_duration', duration.value);
          } catch (e) {
            logger.error('Error saving goals', error: e);
          }
          onNext({
            'primary_goal': primary,
            'learning_reasons': reasons,
            'daily_duration_minutes': duration.value,
          });
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why are you learning?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'Pick one or more. We will shape your first path around them.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final goal in _goals)
            _SelectRow(
              height: ModernGriotLayout.selectRowComfortable,
              label: goal['title'] as String,
              isSelected: selected.value.contains(goal['id']),
              leading: Icon(
                goal['icon'] as IconData,
                color: selected.value.contains(goal['id'])
                    ? ModernGriotColors.brandCoral
                    : ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                final next = Set<String>.from(selected.value);
                final id = goal['id'] as String;
                if (next.contains(id)) {
                  next.remove(id);
                } else {
                  next.add(id);
                }
                selected.value = next;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          Text(
            'Daily time',
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          Wrap(
            spacing: ModernGriotSpacing.xs.w,
            runSpacing: ModernGriotSpacing.xs.h,
            children: [
              for (final d in _durations)
                Semantics(
                  button: true,
                  selected: duration.value == d['min'],
                  label: '${d['min']} minutes, ${d['label']}',
                  child: ChoiceChip(
                    selected: duration.value == d['min'],
                    label: Text('${d['min']} min · ${d['label']}'),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      duration.value = d['min'] as int;
                    },
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                    selectedColor: ModernGriotColors.brandGold.withValues(
                      alpha: _GriotAlpha.chipSelected,
                    ),
                    labelStyle: ModernGriotTypography.labelLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. Level placement — Duolingo signal bars
// =============================================================================

class _LevelPlacementStep extends HookConsumerWidget {
  const _LevelPlacementStep({
    required this.onNext,
    required this.learningLanguage,
  });

  final Function(Map<String, dynamic>) onNext;
  final String learningLanguage;

  static const _levels = [
    {'id': 'new', 'label': "I'm new", 'bars': 0},
    {'id': 'words', 'label': 'I know some common words', 'bars': 1},
    {'id': 'basic', 'label': 'I can have basic conversations', 'bars': 2},
    {'id': 'topics', 'label': 'I can talk about various topics', 'bars': 3},
    {'id': 'fluent', 'label': 'I can hold a conversation', 'bars': 4},
  ];

  String get _langName {
    switch (learningLanguage) {
      case 'yo':
        return 'Yoruba';
      case 'sw':
        return 'Swahili';
      case 'ha':
        return 'Hausa';
      case 'ig':
        return 'Igbo';
      case 'zu':
        return 'Zulu';
      case 'am':
        return 'Amharic';
      default:
        return 'this language';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final showQuickCheck = useState(false);
    final recognizedWords = useState<Set<String>>({});

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value != null,
        onPressed: () async {
          final level = selected.value!;
          // Map level loosely into a default learning style so reask keys
          // that expect learning_style still receive a value when style
          // step is skipped in reask flows that only ask level.
          final styleHint = level == 'new' || level == 'words'
              ? 'audio'
              : 'mixed';
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('self_reported_level', level);
            if (prefs.getString('learning_style') == null) {
              await prefs.setString('learning_style', styleHint);
            }
          } catch (e) {
            logger.error('Error saving level', error: e);
          }
          onNext({
            'self_reported_level': level,
            'learning_style': styleHint,
          });
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PolieBadge(step: OnboardingStep.goals),
              SizedBox(width: ModernGriotSpacing.sm.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(ModernGriotSpacing.sm.w),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
                    border: Border.all(
                      color: ModernGriotColors.outlineVariant.withValues(
                        alpha: _GriotAlpha.ghostBorder,
                      ),
                    ),
                  ),
                  child: Text(
                    'How much $_langName do you know?',
                    style: ModernGriotTypography.titleLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          for (final level in _levels)
            _SelectRow(
              label: level['label'] as String,
              isSelected: selected.value == level['id'],
              leading: _SignalBars(filled: level['bars'] as int),
              onTap: () {
                HapticFeedback.selectionClick();
                selected.value = level['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          TextButton(
            onPressed: () {
              showQuickCheck.value = !showQuickCheck.value;
              if (!showQuickCheck.value) {
                recognizedWords.value = {};
                return;
              }
              selected.value = 'unsure';
            },
            child: Text(
              "Not sure? Take a 1-minute check",
              style: ModernGriotTypography.labelLarge(
                context: context,
                color: ModernGriotColors.primary,
              ),
            ),
          ),
          if (showQuickCheck.value) ...[
            SizedBox(height: ModernGriotSpacing.xs.h),
            Text(
              'Quick check: tap each word you recognize.',
              style: ModernGriotTypography.bodyMedium(
                context: context,
                color: ModernGriotColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            Wrap(
              spacing: ModernGriotSpacing.xs.w,
              children: [
                for (final word in _quickCheckWords(learningLanguage))
                  FilterChip(
                    label: Text(word),
                    selected: recognizedWords.value.contains(word),
                    onSelected: (isOn) {
                      HapticFeedback.selectionClick();
                      final next = Set<String>.from(recognizedWords.value);
                      if (isOn) {
                        next.add(word);
                      } else {
                        next.remove(word);
                      }
                      recognizedWords.value = next;
                      if (next.isEmpty) {
                        selected.value = 'unsure';
                      } else if (next.length >= 2) {
                        selected.value = 'words';
                      } else {
                        selected.value = 'new';
                      }
                    },
                  ),
              ],
            ),
          ],
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

List<String> _quickCheckWords(String code) {
  final copy = _lessonCopyFor(code);
  switch (code) {
    case 'ha':
      return [copy.hear, 'Na gode', 'Ina kwana'];
    case 'ig':
      return [copy.hear, 'Kedu', 'Daalụ'];
    case 'sw':
      return [copy.hear, 'Asante', 'Jambo'];
    case 'am':
      return [copy.hear, 'አመሰግናለሁ', 'እንደምን'];
    case 'zu':
      return [copy.hear, 'Ngiyabonga', 'Unjani'];
    default:
      return [copy.hear, 'Ẹ káàárọ̀', 'Oúnjẹ'];
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ModernGriotSpacing.xl.w,
      height: ModernGriotSpacing.lg.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final on = i < filled;
          return Padding(
            padding: EdgeInsetsDirectional.only(
              end: i == 3 ? 0 : ModernGriotSpacing.xxs.w,
            ),
            child: Container(
              width: ModernGriotSpacing.xxs.w,
              height: (ModernGriotSpacing.xs + i * ModernGriotSpacing.xxs).h,
              decoration: BoxDecoration(
                color: on
                    ? ModernGriotColors.primary
                    : ModernGriotColors.outlineVariant.withValues(
                        alpha: _GriotAlpha.signalEmpty,
                      ),
                borderRadius: BorderRadius.circular(ModernGriotRadius.xs / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Learning style (preserved feature)
// =============================================================================

class _LearningStyleStep extends HookConsumerWidget {
  const _LearningStyleStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

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
    final selected = useState<String?>(null);

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value != null,
        onPressed: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('learning_style', selected.value!);
          } catch (e) {
            logger.error('Error saving learning style', error: e);
          }
          onNext({'learning_style': selected.value});
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you learn best?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'Pick the style that feels most natural.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final style in _styles)
            _SelectRow(
              label: style['title'] as String,
              subtitle: style['desc'] as String,
              isSelected: selected.value == style['id'],
              leading: Icon(
                style['icon'] as IconData,
                color: ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                selected.value = style['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. First win — Speak/Finch celebration after micro-lesson
// =============================================================================

class _FirstWinStep extends HookConsumerWidget {
  const _FirstWinStep({
    required this.onNext,
    required this.learningLanguage,
  });

  final Function(Map<String, dynamic>) onNext;
  final String learningLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = useState(0); // 0 hear, 1 tap, 2 say, 3 celebration
    final heard = useState(false);
    final audioStatus = useState<_GreetingAudioStatus>(
      _GreetingAudioStatus.idle,
    );
    final pickedTap = useState<String?>(null);
    final saidReady = useState(false);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final copy = _lessonCopyFor(learningLanguage);
    final decoy = switch (learningLanguage) {
      'sw' => 'Jambo',
      'ha' => 'Ina kwana',
      'ig' => 'Kedu',
      'am' => 'ታደለ',
      'zu' => 'Unjani',
      _ => 'Sannu',
    };
    final tapChoices = [copy.tap, 'Hello', decoy];

    Future<void> playGreeting() async {
      if (audioStatus.value == _GreetingAudioStatus.playing) return;
      HapticFeedback.selectionClick();
      audioStatus.value = _GreetingAudioStatus.playing;
      // Widget tests have no audio pipeline — still show an honest outcome.
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        audioStatus.value = _GreetingAudioStatus.unavailable;
        heard.value = true;
        return;
      }
      var played = false;
      try {
        played = await ref
            .read(ttsProvider.notifier)
            .speak(
              copy.hear,
              languageName: copy.name.toLowerCase(),
            )
            .timeout(const Duration(seconds: 4), onTimeout: () => false);
      } catch (e) {
        logger.warn('First-win greeting TTS failed', error: e);
        played = false;
      }
      if (!context.mounted) return;
      // Honest outcome: real audio OR explicit unavailable — never silent.
      audioStatus.value = played
          ? _GreetingAudioStatus.heard
          : _GreetingAudioStatus.unavailable;
      heard.value = true;
    }

    if (phase.value >= 3) {
      return _StepScaffold(
        bottom: _PrimaryCta(
          label: 'Keep going',
          enabled: true,
          onPressed: () {
            onNext({
              'first_win_completed': true,
              'first_win_xp': 20,
              'first_win_words': 3,
            });
          },
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!reduceMotion) const _ConfettiBurst(),
            Column(
              children: [
                SizedBox(height: ModernGriotSpacing.lg.h),
                if (!reduceMotion)
                  _PolieBadge(
                        step: OnboardingStep.complete,
                        size: (ModernGriotSpacing.xl * 6).w,
                      )
                      .animate()
                      .scale(
                        duration: _motionDuration(context, 1200.ms),
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: _motionDuration(context, 400.ms))
                else
                  _PolieBadge(
                    step: OnboardingStep.complete,
                    size: (ModernGriotSpacing.xl * 6).w,
                  ),
                SizedBox(height: ModernGriotSpacing.md.h),
                Text(
                  'You did it!',
                  style: ModernGriotTypography.headlineMedium(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ),
                ),
                SizedBox(height: ModernGriotSpacing.xs.h),
                Text(
                  'Celebrate progress, not perfection.',
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.bodyLarge(
                    context: context,
                    color: ModernGriotColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ModernGriotSpacing.lg.h),
                const Row(
                  children: [
                    Expanded(
                      child: _StatTile(value: '3', label: 'Words'),
                    ),
                    Expanded(
                      child: _StatTile(value: '20', label: 'XP'),
                    ),
                    Expanded(
                      child: _StatTile(value: '1', label: 'Day streak'),
                    ),
                  ],
                ),
                SizedBox(height: ModernGriotSpacing.lg.h),
              ],
            ),
          ],
        ),
      );
    }

    final canAdvance = switch (phase.value) {
      0 => heard.value,
      1 => pickedTap.value == copy.tap,
      2 => saidReady.value,
      _ => false,
    };

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: phase.value == 2 ? 'Finish lesson' : 'Continue',
        enabled: canAdvance,
        onPressed: () {
          phase.value++;
          heard.value = false;
          pickedTap.value = null;
          saidReady.value = false;
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your first win',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'A 60-second taste of ${copy.name}. Hear, tap, say.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          LinearProgressIndicator(
            value: (phase.value + 1) / 3,
            backgroundColor: ModernGriotColors.surfaceContainerHighest,
            color: ModernGriotColors.brandGold,
            minHeight: ModernGriotSpacing.xxs.h,
            borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
          ),
          SizedBox(height: ModernGriotSpacing.xl.h),
          Center(
            child: _PolieBadge(
              step: OnboardingStep.story,
              size: (ModernGriotSpacing.xxl * 2 + ModernGriotSpacing.lg).w,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          if (phase.value == 0) ...[
            Center(
              child: Text(
                'Hear: ${copy.hear}',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.headlineMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.sm.h),
            Center(
              child: Semantics(
                button: true,
                liveRegion: true,
                label: switch (audioStatus.value) {
                  _GreetingAudioStatus.heard => 'Greeting played',
                  _GreetingAudioStatus.unavailable => 'Audio unavailable',
                  _GreetingAudioStatus.playing => 'Playing greeting',
                  _GreetingAudioStatus.idle => 'Play greeting ${copy.hear}',
                },
                child: OutlinedButton.icon(
                  onPressed: audioStatus.value == _GreetingAudioStatus.playing
                      ? null
                      : playGreeting,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      ModernGriotLayout.minTouchTarget * 2.5,
                      ModernGriotLayout.minTouchTarget.toDouble(),
                    ),
                    foregroundColor: ModernGriotColors.onSurface,
                    side: const BorderSide(color: ModernGriotColors.brandCoral),
                  ),
                  icon: Icon(
                    switch (audioStatus.value) {
                      _GreetingAudioStatus.heard =>
                        Icons.check_circle_rounded,
                      _GreetingAudioStatus.unavailable =>
                        Icons.volume_off_rounded,
                      _GreetingAudioStatus.playing => Icons.graphic_eq_rounded,
                      _GreetingAudioStatus.idle => Icons.volume_up_rounded,
                    },
                  ),
                  label: Text(
                    switch (audioStatus.value) {
                      _GreetingAudioStatus.heard => 'Heard it',
                      _GreetingAudioStatus.unavailable => 'Audio unavailable',
                      _GreetingAudioStatus.playing => 'Playing…',
                      _GreetingAudioStatus.idle => 'Play greeting',
                    },
                  ),
                ),
              ),
            ),
            if (audioStatus.value == _GreetingAudioStatus.unavailable) ...[
              SizedBox(height: ModernGriotSpacing.xs.h),
              Text(
                'We could not play sound right now. You can still continue.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
            ],
          ] else if (phase.value == 1) ...[
            Center(
              child: Text(
                'Tap the greeting',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.headlineMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.md.h),
            for (final choice in tapChoices)
              _SelectRow(
                label: choice,
                isSelected: pickedTap.value == choice,
                onTap: () {
                  HapticFeedback.selectionClick();
                  pickedTap.value = choice;
                },
              ),
          ] else ...[
            Center(
              child: Text(
                'Say it with Polie',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.headlineMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            Center(
              child: Text(
                copy.say,
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodyLarge(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.md.h),
            Center(
              child: Semantics(
                button: true,
                label: saidReady.value
                    ? 'You marked the phrase as said'
                    : 'Mark that you said ${copy.hear}',
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    saidReady.value = true;
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      ModernGriotLayout.minTouchTarget * 2.5,
                      ModernGriotLayout.minTouchTarget.toDouble(),
                    ),
                    foregroundColor: ModernGriotColors.onSurface,
                    side: const BorderSide(color: ModernGriotColors.brandCoral),
                  ),
                  icon: Icon(
                    saidReady.value
                        ? Icons.check_circle_rounded
                        : Icons.mic_rounded,
                  ),
                  label: Text(
                    saidReady.value ? 'Nice, you said it' : 'I said it',
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

enum _GreetingAudioStatus { idle, playing, heard, unavailable }

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  @override
  Widget build(BuildContext context) {
    final dots = <(double, double, Color)>[
      (0.12, 0.08, ModernGriotColors.brandGold),
      (0.28, 0.18, ModernGriotColors.brandCoral),
      (0.55, 0.06, ModernGriotColors.secondary),
      (0.72, 0.16, ModernGriotColors.brandGold),
      (0.88, 0.10, ModernGriotColors.primary),
      (0.40, 0.22, ModernGriotColors.tertiary),
    ];
    return IgnorePointer(
      child: SizedBox(
        height: ModernGriotSpacing.xxxl.h * 2,
        width: double.infinity,
        child: Stack(
          children: [
            for (var i = 0; i < dots.length; i++)
              Positioned(
                left: MediaQuery.sizeOf(context).width * dots[i].$1 -
                    ModernGriotSpacing.lg.w,
                top: ModernGriotSpacing.xxl.h * dots[i].$2,
                child: Container(
                  width: ModernGriotSpacing.sm.w,
                  height: ModernGriotSpacing.sm.w,
                  decoration: BoxDecoration(
                    color: dots[i].$3,
                    borderRadius: BorderRadius.circular(ModernGriotRadius.xs),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 280.ms)
                    .moveY(
                      begin: -ModernGriotSpacing.md,
                      end: ModernGriotSpacing.lg.toDouble(),
                      duration: 900.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(delay: 700.ms, duration: 300.ms),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.xxs.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ModernGriotSpacing.md.h,
          horizontal: ModernGriotSpacing.xs.w,
        ),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
          border: Border.all(
            color: ModernGriotColors.outlineVariant.withValues(
              alpha: _GriotAlpha.ghostBorder,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: ModernGriotTypography.headlineMedium(
                context: context,
                color: ModernGriotColors.primary,
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xxs.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: ModernGriotTypography.labelMedium(
                context: context,
                color: ModernGriotColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 6. Account + age — birth-year wheel, Ask-a-parent, distinct sign-in
// =============================================================================

class _AccountAgeStep extends HookConsumerWidget {
  const _AccountAgeStep({
    required this.onNext,
    required this.onSignIn,
    required this.existingReasons,
  });

  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onSignIn;
  final List<String> existingReasons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowYear = DateTime.now().year;
    final years = [for (var y = nowYear; y >= 1900; y--) y];
    final initialIndex = years.indexOf(nowYear - 18).clamp(0, years.length - 1);
    final selectedYear = useState(years[initialIndex]);
    final wheelController = useFixedExtentScrollController(
      initialItem: initialIndex,
    );
    final parentEmail = useState('');
    final countryCode = Localizations.localeOf(context).countryCode;
    final band = computeRegistrationAgeBand(
      selectedYear.value,
      countryCode: countryCode,
    );
    final isChild = band == 'child';
    final emailOk = !isChild ||
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(parentEmail.value.trim());

    /// Persists birth year / guardian flags. Returns payload or null if invalid.
    /// Auth CTAs must call this before leaving — never abandon answers.
    Future<Map<String, dynamic>?> persistAge({
      required bool requireParentEmail,
      required bool accountSkipped,
    }) async {
      final year = selectedYear.value;
      final ageBand = band;
      if (ageBand == null) return null;
      if (requireParentEmail && isChild && !emailOk) return null;
      try {
        await ref
            .read(onboardingProvider.notifier)
            .persistRegistrationBirthYear(year, ageBand);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('age_category', ageBand);
        await prefs.setInt('birth_year', year);
        if (existingReasons.isNotEmpty) {
          await prefs.setStringList('learning_reasons', existingReasons);
        }
        if (isChild) {
          final email = parentEmail.value.trim();
          if (email.isNotEmpty) {
            await prefs.setString('guardian_email', email);
          }
          await prefs.setBool('needs_guardian_consent', true);
        }
        await prefs.setBool('onboarding_account_skipped', accountSkipped);
      } catch (e) {
        logger.error('Error saving age', error: e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: ModernGriotColors.onSurface,
              content: Text(
                'We could not save that just now. Your answers stay on this device.',
                style: ModernGriotTypography.bodyMedium(
                  context: context,
                  color: ModernGriotColors.surface,
                ),
              ),
            ),
          );
        }
      }
      return {
        'birth_year': year,
        'age_band': ageBand,
        'age_category': ageBand,
        if (existingReasons.isNotEmpty) 'learning_reasons': existingReasons,
        if (isChild && parentEmail.value.trim().isNotEmpty)
          'guardian_email': parentEmail.value.trim(),
        if (isChild) 'needs_guardian_consent': true,
        'account_skipped': accountSkipped,
      };
    }

    Future<void> persistAndContinue({required bool requireParentEmail}) async {
      final payload = await persistAge(
        requireParentEmail: requireParentEmail,
        accountSkipped: !requireParentEmail,
      );
      if (payload == null) return;
      onNext(payload);
    }

    Future<void> persistThenSignIn() async {
      // Save age/progress first — auth must not wipe the wheel answers.
      final payload = await persistAge(
        requireParentEmail: false,
        accountSkipped: false,
      );
      if (payload == null || !context.mounted) return;
      onSignIn();
    }

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: isChild ? 'Ask a parent to continue' : 'Continue',
        enabled: band != null && emailOk,
        onPressed: () => persistAndContinue(requireParentEmail: true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section A: Age ──────────────────────────────────────────────
          Text(
            'When were you born?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'This helps us keep LingAfriq right for you.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          Semantics(
            label: 'Birth year scroll wheel',
            value: '${selectedYear.value}',
            child: SizedBox(
              height: (ModernGriotSpacing.xxxl * 2 + ModernGriotSpacing.xl).h,
              child: ListWheelScrollView.useDelegate(
                controller: wheelController,
                itemExtent: ModernGriotLayout.minTouchTarget.h,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  selectedYear.value = years[i];
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: years.length,
                  builder: (context, index) {
                    final y = years[index];
                    final selected = y == selectedYear.value;
                    return Center(
                      child: Text(
                        '$y',
                        style: selected
                            ? ModernGriotTypography.headlineMedium(
                                context: context,
                                color: ModernGriotColors.onSurface,
                              )
                            : ModernGriotTypography.titleLarge(
                                context: context,
                                color: ModernGriotColors.onSurfaceVariant,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          Semantics(
            label: 'Birth year',
            textField: true,
            child: TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: ModernGriotTypography.bodyLarge(
                context: context,
                color: ModernGriotColors.onSurface,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Or type year, e.g. 2008',
                filled: true,
                fillColor: ModernGriotColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                ),
              ),
              onChanged: (v) {
                if (v.length != 4) return;
                final parsed = int.tryParse(v);
                if (parsed == null) return;
                final idx = years.indexOf(parsed);
                if (idx < 0) return;
                selectedYear.value = parsed;
                wheelController.jumpToItem(idx);
              },
            ),
          ),
          if (isChild) ...[
            SizedBox(height: ModernGriotSpacing.md.h),
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(ModernGriotSpacing.md.w),
                decoration: BoxDecoration(
                  color: ModernGriotColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask a parent',
                      style: ModernGriotTypography.titleMedium(
                        context: context,
                        color: ModernGriotColors.onSecondaryContainer,
                      ),
                    ),
                    SizedBox(height: ModernGriotSpacing.xxs.h),
                    Text(
                      'A guardian can help finish set-up. Share their email '
                      'and we will send a kind invite. No dead ends.',
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: ModernGriotColors.onSecondaryContainer,
                      ),
                    ),
                    SizedBox(height: ModernGriotSpacing.sm.h),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => parentEmail.value = v,
                      style: ModernGriotTypography.bodyLarge(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Parent email',
                        filled: true,
                        fillColor: ModernGriotColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ModernGriotRadius.lg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (band == 'teen') ...[
            SizedBox(height: ModernGriotSpacing.sm.h),
            Semantics(
              liveRegion: true,
              child: Text(
                'Your profile stays private, and adults cannot DM you until '
                'you connect in a circle.',
                style: ModernGriotTypography.bodyMedium(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
            ),
          ],

          SizedBox(height: ModernGriotSpacing.xl.h),

          // ── Section B: Account (visually separated) ─────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ModernGriotSpacing.md.w),
            decoration: BoxDecoration(
              color: ModernGriotColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save progress with an account',
                  style: ModernGriotTypography.titleMedium(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ),
                ),
                SizedBox(height: ModernGriotSpacing.xxs.h),
                Text(
                  'Optional. Your answers already stay on this device.',
                  style: ModernGriotTypography.bodySmall(
                    context: context,
                    color: ModernGriotColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ModernGriotSpacing.md.h),
                _AuthProviderButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  background: ModernGriotColors.surfaceContainerLowest,
                  foreground: ModernGriotColors.onSurface,
                  border: ModernGriotColors.outline,
                  onPressed: band == null ? null : persistThenSignIn,
                ),
                SizedBox(height: ModernGriotSpacing.xs.h),
                _AuthProviderButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  background: ModernGriotColors.inverseSurface,
                  foreground: ModernGriotColors.onInverseSurface,
                  border: ModernGriotColors.inverseSurface,
                  onPressed: band == null ? null : persistThenSignIn,
                ),
                SizedBox(height: ModernGriotSpacing.xs.h),
                _AuthProviderButton(
                  label: 'Continue with Email',
                  icon: Icons.mail_outline_rounded,
                  background: ModernGriotColors.tertiaryContainer,
                  foreground: ModernGriotColors.onTertiaryContainer,
                  border: ModernGriotColors.tertiary,
                  onPressed: band == null ? null : persistThenSignIn,
                ),
              ],
            ),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          // Skip MUST advance and persist — never a dead no-op.
          Center(
            child: TextButton(
              onPressed: band == null
                  ? null
                  : () => persistAndContinue(requireParentEmail: false),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  ModernGriotLayout.minTouchTarget,
                  ModernGriotLayout.minTouchTarget,
                ),
              ),
              child: Text(
                'Skip for now. Progress stays on this device',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.labelMedium(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: math.max(
        ModernGriotLayout.minTouchTarget.h,
        ModernGriotLayout.minTouchTarget.toDouble(),
      ),
      child: Semantics(
        button: true,
        label: label,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: foreground),
          label: Text(
            label,
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: foreground,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            side: BorderSide(color: border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 7. Notifications — Opal value-first pre-prompt
// =============================================================================

class _NotificationsStep extends HookConsumerWidget {
  const _NotificationsStep({
    required this.onNext,
    required this.dailyMinutes,
    required this.learningLanguage,
  });

  final Function(Map<String, dynamic>) onNext;
  final int dailyMinutes;
  final String learningLanguage;

  static const _times = [
    {'id': 'sunrise', 'label': 'Sunrise', 'time': '6–9 AM'},
    {'id': 'midday', 'label': 'Midday', 'time': '12–2 PM'},
    {'id': 'sunset', 'label': 'Sunset', 'time': '5–7 PM'},
    {'id': 'night', 'label': 'Night', 'time': '8–10 PM'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTime = useState<String?>('sunrise');
    final lesson = _lessonCopyFor(learningLanguage);
    final reminderLine = lesson.reminder.replaceFirst(
      '5 minutes',
      '$dailyMinutes minutes',
    );

    Future<void> finish({required bool enable}) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('daily_duration', dailyMinutes);
        await prefs.setString('preferred_time', selectedTime.value ?? 'sunrise');
        await prefs.setBool('reminders_enabled', enable);
        if (enable) {
          try {
            await ref
                .read(firebaseMessagingProvider)
                .messaging
                .requestPermission();
          } catch (e) {
            logger.warn('Notification permission request failed', error: e);
          }
        }
      } catch (e) {
        logger.error('Error saving reminders', error: e);
      }
      onNext({
        'daily_duration_minutes': dailyMinutes,
        'preferred_time_of_day': selectedTime.value ?? 'sunrise',
        'reminders_enabled': enable,
      });
    }

    return _StepScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryCta(
            label: 'Turn on reminders',
            enabled: selectedTime.value != null,
            onPressed: () => finish(enable: true),
          ),
          TextButton(
            onPressed: () => finish(enable: false),
            style: TextButton.styleFrom(
              minimumSize: const Size(
                ModernGriotLayout.minTouchTarget,
                ModernGriotLayout.minTouchTarget,
              ),
            ),
            child: Text(
              'Not now',
              style: ModernGriotTypography.labelLarge(
                context: context,
                color: ModernGriotColors.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A soft nudge when it matters',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'See the reminder below. Turn it on only if it helps you '
            'keep your streak. You pick the time.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ModernGriotSpacing.md.w),
            decoration: BoxDecoration(
              color: ModernGriotColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
              border: Border.all(
                color: ModernGriotColors.brandGold.withValues(
                  alpha: _GriotAlpha.goldBorder,
                ),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PolieBadge(
                      step: OnboardingStep.schedule,
                      size: ModernGriotLayout.selectRowMin.w,
                    ),
                    SizedBox(width: ModernGriotSpacing.sm.w),
                    Expanded(
                      child: Text(
                        reminderLine,
                        style: ModernGriotTypography.titleMedium(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ModernGriotSpacing.sm.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ModernGriotSpacing.sm.w,
                    vertical: ModernGriotSpacing.xxs.h,
                  ),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.brandGold.withValues(
                      alpha: _GriotAlpha.chipSelected,
                    ),
                    borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
                  ),
                  child: Text(
                    _times
                        .firstWhere(
                          (t) => t['id'] == selectedTime.value,
                          orElse: () => _times.first,
                        )['time']
                        as String,
                    style: ModernGriotTypography.labelLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          Text(
            'Best time',
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          for (final t in _times)
            _SelectRow(
              label: t['label'] as String,
              subtitle: t['time'] as String,
              isSelected: selectedTime.value == t['id'],
              onTap: () {
                HapticFeedback.selectionClick();
                selectedTime.value = t['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// Tone + gamification (preserved)
// =============================================================================

class _ToneStep extends HookConsumerWidget {
  const _ToneStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

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

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How should Polie sound?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'Pick the voice that feels like a good study buddy.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final tone in _tones)
            _SelectRow(
              label: tone['label'] as String,
              subtitle: tone['desc'] as String,
              isSelected: selectedTone.value == tone['id'],
              leading: Icon(
                tone['icon'] as IconData,
                color: ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                selectedTone.value = tone['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.md.h),
          Text(
            'How much game feel?',
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          for (final level in _gamificationLevels)
            _SelectRow(
              label: level['label'] as String,
              subtitle: level['desc'] as String,
              isSelected: selectedGamification.value == level['id'],
              onTap: () {
                HapticFeedback.selectionClick();
                selectedGamification.value = level['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// Profile / naming (preserved)
// =============================================================================

class _ProfileStep extends HookConsumerWidget {
  const _ProfileStep({
    required this.onboardingData,
    required this.onComplete,
    required this.onSkip,
  });

  final Map<String, dynamic> onboardingData;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final username = useState('');
    final usernameStatus = useState<_UsernameStatus>(_UsernameStatus.initial);
    final isChecking = useState(false);
    final avatarPath = useState<String?>(null);
    Timer? debounceTimer;

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

    return _StepScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryCta(
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
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip for now',
              style: ModernGriotTypography.labelLarge(
                context: context,
                color: ModernGriotColors.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Pick a name',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'A learner without a name is a drum without a rhythm.',
            textAlign: TextAlign.center,
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          Semantics(
            button: true,
            label: 'Add a profile photo, optional',
            child: GestureDetector(
              onTap: pickAvatar,
              child: CircleAvatar(
                radius: ModernGriotSpacing.xxl.r,
                backgroundColor: ModernGriotColors.brandGold.withValues(
                  alpha: _GriotAlpha.chipSelected,
                ),
                backgroundImage: avatarPath.value != null
                    ? FileImage(File(avatarPath.value!))
                    : null,
                child: avatarPath.value == null
                    ? Icon(
                        Icons.person_rounded,
                        size: ModernGriotSpacing.xl.sp,
                        color: ModernGriotColors.onSurface,
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          Text(
            'Tap to add photo (optional)',
            style: ModernGriotTypography.labelMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          TextField(
            controller: usernameController,
            style: ModernGriotTypography.bodyLarge(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
              filled: true,
              fillColor: ModernGriotColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
              ),
              suffixIcon: isChecking.value
                  ? Padding(
                      padding: EdgeInsets.all(ModernGriotSpacing.sm.w),
                      child: SizedBox(
                        width: ModernGriotSpacing.md.w,
                        height: ModernGriotSpacing.md.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _usernameIcon(usernameStatus.value),
              helperText: _usernameHelper(usernameStatus.value),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }

  Widget? _usernameIcon(_UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.available:
        return const Icon(Icons.check_circle_rounded, color: ModernGriotColors.secondary);
      case _UsernameStatus.taken:
        return const Icon(Icons.cancel_rounded, color: ModernGriotColors.error);
      case _UsernameStatus.tooShort:
      case _UsernameStatus.tooLong:
      case _UsernameStatus.invalidFormat:
        return const Icon(Icons.warning_rounded, color: ModernGriotColors.tertiary);
      default:
        return null;
    }
  }

  String? _usernameHelper(_UsernameStatus status) {
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
