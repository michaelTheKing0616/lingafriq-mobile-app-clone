part of '../unified_onboarding_screen.dart';

enum _AccountChoice { google, apple, email, signIn, later }

/// Last step — save progress (Duolingo web 25: the profile prompt comes after
/// the first win, never before it). Each choice goes to its own destination;
/// every choice first saves all answers, so nothing is lost on the way out.
class _SaveProgressStep extends StatelessWidget {
  const _SaveProgressStep({
    required this.onChoose,
    required this.wordsLearned,
    required this.busy,
    this.failedChoice,
    this.busyChoice,
    this.learnCode,
  });

  /// Chosen language; colours the word basket.
  final String? learnCode;

  /// The choice whose button shows in-button progress while saving.
  final _AccountChoice? busyChoice;

  /// Set when an account choice failed (offline); shows message + Retry.
  final _AccountChoice? failedChoice;

  final Future<void> Function(_AccountChoice choice) onChoose;
  final int wordsLearned;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    VoidCallback? go(_AccountChoice c) => busy ? null : () => onChoose(c);
    final words = wordsLearned == 1 ? l10nOf(context).onboardingText1Word : l10nOf(context).onboardingWordslearnedWords(wordsLearned.toString());
    return _StepScaffold(
      showOfflineNotice: failedChoice == null,
      bottom: Padding(
        padding: EdgeInsets.only(bottom: ModernGriotSpacing.xs.h),
        child: TextButton(
          onPressed: go(_AccountChoice.later),
          style: TextButton.styleFrom(
            minimumSize: const Size(
              ModernGriotLayout.minTouchTarget,
              ModernGriotLayout.minTouchTarget,
            ),
          ),
          child: Text(
            _bidi(context, l10nOf(context).onboardingLaterMyAnswersStayOnThis),
            textAlign: TextAlign.center,
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: _captionInk,
            ),
          ),
        ),
      ),
      header: _QuestionHeader(
        step: OnboardingStep.profile,
        question: l10nOf(context).onboardingSaveYourProgress,
        hint: _tr(
          context,
          l10nOf(context).onboardingYouFinishedYourFirstLessonAnd(words.toString()),
          onboardingArSaveHint(wordsLearned),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WordBasket(code: learnCode, words: wordsLearned),
          SizedBox(height: ModernGriotSpacing.md.h),
          if (failedChoice != null) ...[
            _FinishError(onRetry: () => onChoose(failedChoice!)),
            SizedBox(height: ModernGriotSpacing.md.h),
          ],
          _AuthProviderButton(
            label: l10nOf(context).onboardingContinueWithGoogle,
            icon: Icons.account_circle_outlined,
            background: ModernGriotColors.surfaceContainerLowest,
            foreground: ModernGriotColors.onSurface,
            border: ModernGriotColors.outline,
            onPressed: go(_AccountChoice.google),
            busy: busyChoice == _AccountChoice.google,
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          _AuthProviderButton(
            label: l10nOf(context).onboardingContinueWithApple,
            icon: Icons.apple,
            background: ModernGriotColors.inverseSurface,
            foreground: ModernGriotColors.onInverseSurface,
            border: ModernGriotColors.inverseSurface,
            onPressed: go(_AccountChoice.apple),
            busy: busyChoice == _AccountChoice.apple,
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          _AuthProviderButton(
            label: l10nOf(context).onboardingSignUpWithEmail,
            icon: Icons.mail_outline_rounded,
            background: ModernGriotColors.brandGold,
            foreground: ModernGriotColors.onBrandGold,
            border: ModernGriotColors.brandGold,
            onPressed: go(_AccountChoice.email),
            busy: busyChoice == _AccountChoice.email,
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          Center(
            child: TextButton(
              onPressed: go(_AccountChoice.signIn),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  ModernGriotLayout.minTouchTarget,
                  ModernGriotLayout.minTouchTarget,
                ),
              ),
              child: Text(
                _bidi(context, l10nOf(context).onboardingIAlreadyHaveAnAccount),
                style: ModernGriotTypography.labelLarge(
                  context: context,
                  color: ModernGriotColors.primary,
                ),
              ),
            ),
          ),
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
    this.busy = false,
  });

  final bool busy;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
        minHeight: math.max(
          ModernGriotLayout.minTouchTarget.h,
          ModernGriotLayout.minTouchTarget.toDouble(),
        ),
      ),
      child: Semantics(
        button: true,
        label: _bidi(context, busy ? l10nOf(context).onboardingSavingYourProgress : label),
        excludeSemantics: true,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: busy
              ? null
              : Icon(
                  icon,
                  color: onPressed == null ? _captionInk : foreground,
                  size: 24,
                ),
          label: busy
              ? _BusyLabel(label: l10nOf(context).onboardingSavingYourProgress)
              : Text(
                  _bidi(context, label),
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.labelLarge(
                    context: context,
                    color: onPressed == null ? _captionInk : foreground,
                  ),
                ),
          style: OutlinedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            // While saving, every choice greys out; only the busy one speaks.
            disabledBackgroundColor: ModernGriotColors.surfaceContainerHigh,
            disabledForegroundColor: ModernGriotColors.onSurface,
            minimumSize: const Size.fromHeight(
              ModernGriotLayout.minTouchTarget,
            ),
            side: BorderSide(
              color: onPressed == null
                  ? ModernGriotColors.outlineVariant
                  : border,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishError extends ConsumerWidget {
  const _FinishError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const ValueKey('finish-error'),
        padding: EdgeInsets.all(ModernGriotSpacing.md.w),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
          border: Border.all(color: ModernGriotColors.error, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: ModernGriotColors.error,
                  semanticLabel: l10nOf(context).onboardingError,
                ),
                SizedBox(width: ModernGriotSpacing.xs.w),
                Expanded(
                  child: Text(
                    _bidi(context, l10nOf(context).onboardingCouldnTReachSignIn),
                    style: ModernGriotTypography.titleSmall(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ModernGriotSpacing.xxs.h),
            Text(
              _bidi(
                context,
                l10nOf(context).onboardingYouReOfflineYourAnswersAre,
              ),
              style: ModernGriotTypography.bodyMedium(
                context: context,
                color: ModernGriotColors.onSurface,
              ),
            ),
            SizedBox(height: ModernGriotSpacing.sm.h),
            SizedBox(
              height: ModernGriotLayout.minTouchTarget.toDouble(),
              child: FilledButton(
                onPressed: () {
                  ref.invalidate(onboardingOnlineProvider);
                  onRetry();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ModernGriotColors.brandGold,
                  foregroundColor: ModernGriotColors.onBrandGold,
                ),
                child: Text(_bidi(context, l10nOf(context).onboardingRetry)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
