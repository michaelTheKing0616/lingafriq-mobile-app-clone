part of '../unified_onboarding_screen.dart';

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
    final emailOk =
        !isChild ||
        RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(parentEmail.value.trim());

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
