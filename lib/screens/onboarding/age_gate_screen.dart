import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart'
    show childThresholdFor, computeRegistrationAgeBand;
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

/// Copy keys: age_gate.title, age_gate.body, age_gate.blocked (P9-912).
///
/// Birth year only (LingAfriq age-gate policy): never asks for a month or
/// day. The child threshold is 13 by default and 16 where law requires,
/// configured per country in [kChildThresholdByCountry]; the server
/// re-verifies the band.
class AgeGateScreen extends HookConsumerWidget {
  const AgeGateScreen({
    super.key,
    this.onCompleted,
    this.ageTierService,
    this.deviceKeyOverride,
    this.debugPrefilledBirthYear,
    this.countryCode,
  });

  final VoidCallback? onCompleted;
  final AgeTierService? ageTierService;
  final String? deviceKeyOverride;
  final int? debugPrefilledBirthYear;

  /// ISO country used for the child threshold; defaults to the device locale.
  final String? countryCode;

  static String ageGateTitle(BuildContext context) => l10nOf(context).onboardingWhatYearWereYouBorn;
  static String ageGateBody(BuildContext context) => l10nOf(context).onboardingWeUseThisToKeepLearners;
  static String ageGateBlocked(BuildContext context) => l10nOf(context).onboardingYouAlreadyEnteredABirthYear;
  static String ageGatePendingGuardianTitle(BuildContext context) => l10nOf(context).onboardingWeNeedAGuardian;
  static String ageGatePendingGuardianBody(BuildContext context) => l10nOf(context).onboardingYourAccountIsReadyForLessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ageTierService ?? AgeTierService();
    final selectedDate = useState<int?>(debugPrefilledBirthYear);
    final submitting = useState(false);
    final errorText = useState<String?>(null);
    final blockedRetry = useState(false);
    final pendingGuardian = useState(false);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<String> deviceKey() async {
      if (deviceKeyOverride != null) return deviceKeyOverride!;
      final prefs = await SharedPreferences.getInstance();
      var key = prefs.getString('age_gate_device_key');
      if (key == null || key.isEmpty) {
        key = 'dg-${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('age_gate_device_key', key);
      }
      return key;
    }

    Future<void> submit() async {
      final year = selectedDate.value;
      final country =
          countryCode ?? Localizations.maybeLocaleOf(context)?.countryCode;
      if (year == null ||
          computeRegistrationAgeBand(year, countryCode: country) == null) {
        errorText.value = l10nOf(context).onboardingChooseTheYearYouWereBorn;
        return;
      }
      submitting.value = true;
      errorText.value = null;
      blockedRetry.value = false;
      pendingGuardian.value = false;
      try {
        final result = await service.assignBirthDate(
          birthYear: year,
          deviceKey: await deviceKey(),
        );
        if (!context.mounted) return;
        if (!result.ok) {
          if (result.code == 'AGE_RETRY_BLOCKED') {
            blockedRetry.value = true;
            errorText.value = ageGateBlocked(context);
          } else {
            errorText.value =
                result.message ?? l10nOf(context).onboardingWeCouldNotSaveThatYear;
          }
          return;
        }
        if (result.pendingGuardian) {
          pendingGuardian.value = true;
          return;
        }
        onCompleted?.call();
      } finally {
        submitting.value = false;
      }
    }

    Future<void> pickDate() async {
      final now = DateTime.now();
      final initialYear = selectedDate.value ?? now.year - 18;
      final picked = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ageGateTitle(context)),
          content: SizedBox(
            width: 300,
            height: 320,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: now,
              selectedDate: DateTime(initialYear),
              onChanged: (d) => Navigator.of(dialogContext).pop(d.year),
            ),
          ),
        ),
      );
      if (picked != null) {
        selectedDate.value = picked;
        errorText.value = null;
        blockedRetry.value = false;
      }
    }

    if (pendingGuardian.value) {
      return _AgeGateShell(
        isDark: isDark,
        child: SingleChildScrollView(
          child: _StatusPanel(
            icon: Icons.family_restroom_rounded,
            title: ageGatePendingGuardianTitle(context),
            body: ageGatePendingGuardianBody(context),
            primaryLabel: l10nOf(context).onboardingContinueToLessons,
            onPrimary: () => onCompleted?.call(),
            colorScheme: colorScheme,
          ),
        ),
      );
    }

    return _AgeGateShell(
      isDark: isDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ageGateTitle(context),
                    style: PanAfricanTypography.headlineSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md.h),
                  Text(
                    ageGateBody(context),
                    style: PanAfricanTypography.bodyLarge(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg.h),
                  Semantics(
                    button: true,
                    label:
                        l10nOf(context).onboardingBirthYearValue(selectedDate.value?.toString() ?? l10nOf(context).onboardingNotSelected),
                    child: Material(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          PanAfricanRadius.lg,
                        ),
                        onTap: submitting.value ? null : pickDate,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.lg.w,
                            vertical: PanAfricanSpacing.lg.h,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                color: colorScheme.primary,
                                size: 28.sp,
                              ),
                              SizedBox(width: PanAfricanSpacing.md.w),
                              Expanded(
                                child: Text(
                                  selectedDate.value?.toString() ??
                                      l10nOf(context).onboardingSelectBirthYear,
                                  style: PanAfricanTypography.titleMedium(
                                    context,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more_rounded,
                                color: colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (errorText.value != null) ...[
                    SizedBox(height: PanAfricanSpacing.md.h),
                    Text(
                      errorText.value!,
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: blockedRetry.value
                            ? colorScheme.error
                            : colorScheme.error,
                      ),
                    ),
                  ],
                  SizedBox(height: PanAfricanSpacing.xl.h),
                  SizedBox(
                    height: 48.h,
                    child: FilledButton(
                      onPressed: submitting.value ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: PanAfricanRadius.xxlBR,
                        ),
                      ),
                      child: submitting.value
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10nOf(context).onboardingContinue,
                              style: PanAfricanTypography.labelLarge(context)
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Child threshold for [country]: 13 by default, 16 where law requires.
  static int childThreshold(String? country) => childThresholdFor(country);
}

class _AgeGateShell extends StatelessWidget {
  const _AgeGateShell({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      body: ResponsiveSafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg.w,
            vertical: PanAfricanSpacing.xl.h,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 56.sp, color: colorScheme.primary),
        SizedBox(height: PanAfricanSpacing.lg.h),
        Text(
          title,
          style: PanAfricanTypography.headlineSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: PanAfricanSpacing.md.h),
        Text(
          body,
          style: PanAfricanTypography.bodyLarge(
            context,
          ).copyWith(color: colorScheme.onSurfaceVariant, height: 1.45),
        ),
        SizedBox(height: PanAfricanSpacing.xl.h),
        SizedBox(
          height: 48.h,
          child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ),
      ],
    );
  }
}
