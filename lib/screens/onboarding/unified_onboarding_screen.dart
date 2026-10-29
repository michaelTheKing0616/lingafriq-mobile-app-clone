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
import 'package:lingafriq/screens/auth/world_class_signup_screen.dart';
import 'package:lingafriq/screens/auth/sign_in_options.dart';
import 'package:lingafriq/services/device_identity.dart';
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

part 'unified/shared_widgets.dart';
part 'unified/welcome_step.dart';
part 'unified/language_pick_step.dart';
part 'unified/reason_step.dart';
part 'unified/level_placement_step.dart';
part 'unified/daily_goal_step.dart';
part 'unified/first_win_step.dart';
part 'unified/birth_year_step.dart';
part 'unified/notifications_step.dart';
part 'unified/learning_style_step.dart';
part 'unified/tone_step.dart';
part 'unified/profile_step.dart';
part 'unified/save_progress_step.dart';
part 'unified/identity.dart';
part 'unified/copy_ar.dart';

/// Documented Modern Griot opacity roles — never invent ad-hoc alphas in UI.
abstract final class _GriotAlpha {
  /// Ghost border for inputs / quiet outlines (design system rule 3).
  static const double ghostBorder = 0.15;

  /// Soft selected fill over brandGold.
  static const double softSelected = 0.18;

  /// Selected chip / filter fill over brandGold.
  static const double chipSelected = 0.35;

  /// Progress track under coral fill.

  /// Back / icon button wash.
  static const double iconWash = 0.08;

  /// Gold accent border on value cards.
  static const double goldBorder = 0.55;

  /// Completing overlay scrim on onSurface.
  static const double completingScrim = 0.72;

  /// Signal-bar empty segment.
  static const double signalEmpty = 0.45;

  /// Ask-a-parent panel wash on primaryContainer.
}

/// Per-country child thresholds, mirroring node-backend
/// `src/config/agePolicy.ts` (the server re-verifies every band; P1-020).
/// Default 13; 16 where law requires. Counsel owns additions (for example
/// whether Nigeria's NDPA needs a different rule): add a row here and on the
/// server, never a hard-coded branch.
const Map<String, int> kChildThresholdByCountry = {'DE': 16};

/// Whether the device can reach the network. Onboarding never blocks on it:
/// answers save locally and sync through the outbox; this only drives the
/// offline notice. Overridable in tests.
final onboardingOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

const int kDefaultChildThreshold = 13;
const int kAdultAge = 18;

int childThresholdFor(String? countryCode) =>
    kChildThresholdByCountry[countryCode?.toUpperCase()] ??
    kDefaultChildThreshold;

/// Birth year only. Age is counted conservatively (birthday not yet reached)
/// so a borderline learner always gets the safer band.
String? computeRegistrationAgeBand(int birthYear, {String? countryCode}) {
  final nowYear = DateTime.now().year;
  if (birthYear < 1900 || birthYear > nowYear) return null;
  final age = nowYear - birthYear - 1;
  if (age < 0) return null;
  if (age < childThresholdFor(countryCode)) return 'child';
  if (age < kAdultAge) return 'teen';
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
    final failedChoice = useState<_AccountChoice?>(null);

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

    void capture(Map<String, dynamic> data) => _captureOnboardingAnswer(
      data,
      onboardingData,
      pageController,
      currentStep,
      animationController,
      stepsLength: () => stepCount[0],
      reask: reask,
      context: context,
      ref: ref,
    );
    String language() =>
        onboardingData.value['learning_language'] as String? ?? 'yo';

    // Reference order (pack second pass, Duolingo web 15–26): language →
    // reason → level → daily goal → first win → age → reminders → make it
    // yours → profile → save progress. One question per screen.
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
      );
    }
    if (ask(const ['proficiency_language', 'learning_language'])) {
      addStep(_LanguagePickStep(onNext: capture), allowSkip: true);
    }
    if (ask(const ['primary_goal', 'learning_reasons'])) {
      addStep(_ReasonStep(onNext: capture, learningLanguage: language()));
    }
    if (ask(const ['self_reported_level']) || reask.isEmpty) {
      addStep(
        _LevelPlacementStep(learningLanguage: language(), onNext: capture),
      );
    }
    if (ask(const ['daily_duration_minutes'])) {
      addStep(_DailyGoalStep(onNext: capture));
    }
    if (reask.isEmpty) {
      addStep(_FirstWinStep(learningLanguage: language(), onNext: capture));
    }
    if (ask(const ['age_category'])) {
      addStep(_BirthYearStep(onNext: capture));
    }
    if (ask(const ['preferred_time_of_day', 'reminders_enabled'])) {
      addStep(
        _NotificationsStep(
          dailyMinutes:
              onboardingData.value['daily_duration_minutes'] as int? ?? 10,
          learningLanguage: language(),
          onNext: capture,
        ),
      );
    }
    if (ask(const ['learning_style'])) {
      addStep(_LearningStyleStep(onNext: capture), allowSkip: true);
    }
    if (ask(const ['app_tone', 'gamification_level'])) {
      addStep(_ToneStep(onNext: capture), allowSkip: true);
    }
    if (reask.isEmpty) {
      addStep(
        _ProfileStep(
          onboardingData: onboardingData.value,
          onComplete: () => capture(const {}),
          onSkip: () => capture(const {}),
        ),
      );
      addStep(
        _SaveProgressStep(
          busy: isCompleting.value,
          wordsLearned: onboardingData.value['first_win_words'] as int? ?? 0,
          failedChoice: failedChoice.value,
          onChoose: (choice) async {
            if (isCompleting.value) return;
            if (choice != _AccountChoice.later) {
              var online = true;
              try {
                online = await ref.read(onboardingOnlineProvider.future);
              } catch (_) {}
              if (!online) {
                // Sign-in needs a connection: show the error, not a spinner.
                failedChoice.value = choice;
                return;
              }
            }
            if (!context.mounted) return;
            failedChoice.value = null;
            isCompleting.value = true;
            try {
              await _completeOnboarding(
                {
                  ...onboardingData.value,
                  'account_choice': choice.name,
                  'account_skipped': choice == _AccountChoice.later,
                },
                context,
                ref,
                destination: _destinationFor(choice),
              );
            } finally {
              if (context.mounted) isCompleting.value = false;
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
                accentCode:
                    onboardingData.value['learning_language'] as String?,
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
            // Never stack the saving scrim over the offline banner.
            if (isCompleting.value &&
                ref.watch(onboardingOnlineProvider).value != false)
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
                            'Preparing your village…',
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
    String? accentCode,
  }) {
    final Color foregroundColor = isLightBackground
        ? ModernGriotColors.onSurface
        : ModernGriotColors.surface;
    final Color progressFillColor = _accentFor(accentCode);
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
                    data: IconThemeData(
                      color: foregroundColor,
                      size: ModernGriotSpacing.lg.sp,
                    ),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: ModernGriotSpacing.xs.w,
                  ),
                  child: SizedBox(
                    height: 12,
                    child: CustomPaint(
                      painter: _BeadProgressPainter(
                        current: current,
                        total: total,
                        accent: progressFillColor,
                        track: foregroundColor.withValues(alpha: 0.38),
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
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
                    _bidi(context, 'Skip'),
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
    _turnPage(context, controller, step.value, 400.ms, Curves.easeInOut);
  }

  /// Animated page turn, or an instant jump under reduce-motion
  /// (PageController.animateToPage asserts on a zero duration).
  static void _turnPage(
    BuildContext context,
    PageController controller,
    int page,
    Duration normal,
    Curve curve,
  ) {
    final duration = _motionDuration(context, normal);
    if (duration == Duration.zero) {
      controller.jumpToPage(page);
    } else {
      controller.animateToPage(page, duration: duration, curve: curve);
    }
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
    _turnPage(context, controller, step.value, 300.ms, Curves.easeOut);
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

  /// Where each save-progress choice lands. Signed-in users skip auth.
  static Widget? _destinationFor(_AccountChoice choice) => switch (choice) {
    _AccountChoice.google => const SignInOptionsScreen(
      googleIdToken: DeviceIdentity.googleIdToken,
      appleIdToken: DeviceIdentity.appleIdToken,
      autoStart: SignInAutoStart.google,
    ),
    _AccountChoice.apple => const SignInOptionsScreen(
      googleIdToken: DeviceIdentity.googleIdToken,
      appleIdToken: DeviceIdentity.appleIdToken,
      autoStart: SignInAutoStart.apple,
    ),
    _AccountChoice.email => const WorldClassSignupScreen(),
    _AccountChoice.signIn => const WorldClassLoginScreen(),
    _AccountChoice.later => null,
  };

  static Future<void> _completeOnboarding(
    Map<String, dynamic> data,
    BuildContext context,
    WidgetRef ref, {
    Widget? destination,
  }) async {
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
      if (data.containsKey('account_skipped')) {
        await prefs.setBool(
          'onboarding_account_skipped',
          data['account_skipped'] == true,
        );
      }
    } catch (e) {
      logger.error('Error saving onboarding completion locally', error: e);
    }

    var isOnline = true;
    try {
      isOnline = await ref.read(onboardingOnlineProvider.future);
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
                    color: _captionInk,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Maybe later',
                      style: ModernGriotTypography.labelLarge(
                        context: dialogContext,
                        color: _captionInk,
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
          : destination ?? const WorldClassLoginScreen();
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
