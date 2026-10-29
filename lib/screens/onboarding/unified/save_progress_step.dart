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
  });

  final Future<void> Function(_AccountChoice choice) onChoose;
  final int wordsLearned;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    VoidCallback? go(_AccountChoice c) => busy ? null : () => onChoose(c);
    final words = wordsLearned == 1 ? '1 word' : '$wordsLearned words';
    return _StepScaffold(
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
            _bidi(context, 'Later. My answers stay on this phone'),
            textAlign: TextAlign.center,
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      header: _QuestionHeader(
        step: OnboardingStep.profile,
        question: 'Save your progress?',
        hint:
            'You finished your first lesson and learned $words. '
            'An account keeps your progress safe if you change phones.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthProviderButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            background: ModernGriotColors.surfaceContainerLowest,
            foreground: ModernGriotColors.onSurface,
            border: ModernGriotColors.outline,
            onPressed: go(_AccountChoice.google),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          _AuthProviderButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            background: ModernGriotColors.inverseSurface,
            foreground: ModernGriotColors.onInverseSurface,
            border: ModernGriotColors.inverseSurface,
            onPressed: go(_AccountChoice.apple),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          _AuthProviderButton(
            label: 'Sign up with email',
            icon: Icons.mail_outline_rounded,
            background: ModernGriotColors.brandGold,
            foreground: ModernGriotColors.onBrandGold,
            border: ModernGriotColors.brandGold,
            onPressed: go(_AccountChoice.email),
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
                _bidi(context, 'I already have an account'),
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
            _bidi(context, label),
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
