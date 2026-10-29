part of '../unified_onboarding_screen.dart';

/// Step 7 — birth year only (age-gate policy; never a full date, never a
/// yes/no "are you over 18"). Child band switches to a kind Ask-a-parent path
/// with no dead end and no error red. The server re-verifies the band.
class _BirthYearStep extends HookConsumerWidget {
  const _BirthYearStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowYear = DateTime.now().year;
    final years = useMemoized(() => [for (var y = nowYear; y >= 1900; y--) y]);
    // Start on a neutral teen-adult boundary so nobody is nudged to a band.
    final initialIndex = years.indexOf(nowYear - 18);
    final selectedYear = useState(years[initialIndex]);
    final touched = useState(false);
    // One input at a time: the wheel, or a typed field behind a link.
    final typing = useState(false);
    final wheel = useMemoized(
      () => FixedExtentScrollController(
        initialItem: years.indexOf(selectedYear.value),
      ),
      [typing.value],
    );
    useEffect(() => wheel.dispose, [wheel]);
    final typedInvalid = useState(false);
    final parentEmail = useState('');
    final saving = useState(false);
    final country = Localizations.localeOf(context).countryCode;
    final band = computeRegistrationAgeBand(
      selectedYear.value,
      countryCode: country,
    );
    final isChild = band == 'child';
    final emailValid = _email.hasMatch(parentEmail.value.trim());

    Future<void> submit({required bool withParentEmail}) async {
      if (band == null || saving.value) return;
      saving.value = true;
      final year = selectedYear.value;
      final email = withParentEmail ? parentEmail.value.trim() : '';
      try {
        await ref
            .read(onboardingProvider.notifier)
            .persistRegistrationBirthYear(year, band);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('age_category', band);
        await prefs.setInt('birth_year', year);
        if (isChild) {
          await prefs.setBool('needs_guardian_consent', true);
          if (email.isNotEmpty) await prefs.setString('guardian_email', email);
        }
      } catch (e) {
        logger.error('Error saving birth year', error: e);
      } finally {
        saving.value = false;
      }
      onNext({
        'birth_year': year,
        'age_band': band,
        'age_category': band,
        if (isChild) 'needs_guardian_consent': true,
        if (email.isNotEmpty) 'guardian_email': email,
      });
    }

    final ctaEnabled =
        touched.value && band != null && (!isChild || emailValid);

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: ctaEnabled && !saving.value,
        onPressed: () => submit(withParentEmail: isChild),
      ),
      header: const _QuestionHeader(
        step: OnboardingStep.profile,
        question: 'What year were you born?',
        hint:
            'This helps us keep LingAfriq right for you. '
            'We only ask for the year.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (typing.value) ...[
            TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: ModernGriotTypography.bodyLarge(
                context: context,
                color: ModernGriotColors.onSurface,
              ),
              decoration: InputDecoration(
                counterText: '',
                labelText: 'Birth year',
                hintText: 'For example ${nowYear - 18}',
                helperText: typedInvalid.value
                    ? 'Use a year between 1900 and $nowYear.'
                    : null,
                filled: true,
                fillColor: ModernGriotColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                ),
              ),
              onChanged: (v) {
                if (v.length != 4) return;
                final idx = years.indexOf(int.tryParse(v) ?? -1);
                typedInvalid.value = idx < 0;
                if (idx < 0) return;
                selectedYear.value = years[idx];
                touched.value = true;
                wheel.jumpToItem(idx);
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => typing.value = false,
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    ModernGriotLayout.minTouchTarget,
                    ModernGriotLayout.minTouchTarget,
                  ),
                ),
                child: Text(
                  'Use the year wheel',
                  style: ModernGriotTypography.labelLarge(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ] else ...[
            Semantics(
              label: 'Birth year',
              value: '${selectedYear.value}',
              hint: 'Swipe up or down to change the year',
              child: Container(
                height: ModernGriotLayout.minTouchTarget.h * 4,
                decoration: BoxDecoration(
                  color: ModernGriotColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: Container(
                        height: ModernGriotLayout.minTouchTarget.h,
                        margin: EdgeInsets.symmetric(
                          horizontal: ModernGriotSpacing.md.w,
                        ),
                        decoration: BoxDecoration(
                          color: ModernGriotColors.brandGold.withValues(
                            alpha: _GriotAlpha.softSelected,
                          ),
                          borderRadius: BorderRadius.circular(
                            ModernGriotRadius.lg,
                          ),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: wheel,
                      itemExtent: ModernGriotLayout.minTouchTarget.h,
                      physics: const FixedExtentScrollPhysics(),
                      diameterRatio: 1.6,
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        selectedYear.value = years[i];
                        touched.value = true;
                        typedInvalid.value = false;
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: years.length,
                        builder: (context, i) => Center(
                          child: Text(
                            '${years[i]}',
                            style: years[i] == selectedYear.value
                                ? ModernGriotTypography.headlineSmall(
                                    context: context,
                                    color: ModernGriotColors.onSurface,
                                  )
                                : ModernGriotTypography.titleMedium(
                                    context: context,
                                    color: _captionInk,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => typing.value = true,
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    ModernGriotLayout.minTouchTarget,
                    ModernGriotLayout.minTouchTarget,
                  ),
                ),
                child: Text(
                  'Type it instead',
                  style: ModernGriotTypography.labelLarge(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
          SizedBox(height: ModernGriotSpacing.md.h),
          if (touched.value && isChild)
            _AskParentPanel(
              onEmailChanged: (v) => parentEmail.value = v,
              onLater: saving.value
                  ? null
                  : () => submit(withParentEmail: false),
            )
          else if (touched.value && band == 'teen')
            Semantics(
              liveRegion: true,
              child: Text(
                'Your profile stays private, and adults cannot send you '
                'direct messages.',
                style: ModernGriotTypography.bodyMedium(
                  context: context,
                  color: _captionInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AskParentPanel extends StatelessWidget {
  const _AskParentPanel({required this.onEmailChanged, required this.onLater});

  final ValueChanged<String> onEmailChanged;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsets.all(ModernGriotSpacing.md.w),
        decoration: BoxDecoration(
          color: ModernGriotColors.secondaryContainer,
          borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              'A parent or guardian says yes before you chat or share. '
              'Add their email so they can approve your account.',
              style: ModernGriotTypography.bodyMedium(
                context: context,
                color: ModernGriotColors.onSecondaryContainer,
              ),
            ),
            SizedBox(height: ModernGriotSpacing.sm.h),
            TextField(
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: onEmailChanged,
              style: ModernGriotTypography.bodyLarge(
                context: context,
                color: ModernGriotColors.onSurface,
              ),
              decoration: InputDecoration(
                labelText: "Parent's email",
                filled: true,
                fillColor: ModernGriotColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            TextButton(
              onPressed: onLater,
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  ModernGriotLayout.minTouchTarget,
                  ModernGriotLayout.minTouchTarget,
                ),
              ),
              child: Text(
                'Keep learning. My parent will add it later',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.labelLarge(
                  context: context,
                  color: ModernGriotColors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
