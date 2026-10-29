import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copy keys: age_gate.title, age_gate.body, age_gate.blocked (P9-912).
class AgeGateScreen extends HookConsumerWidget {
  const AgeGateScreen({
    super.key,
    this.onCompleted,
    this.ageTierService,
    this.deviceKeyOverride,
    this.debugPrefilledBirthDate,
  });

  final VoidCallback? onCompleted;
  final AgeTierService? ageTierService;
  final String? deviceKeyOverride;
  final DateTime? debugPrefilledBirthDate;

  static const String ageGateTitle = 'When were you born?';
  static const String ageGateBody =
      'We use this to keep learners safe and unlock the right features for your age. '
      'We store your age group, not your full birthday, after you continue.';
  static const String ageGateBlocked =
      'You already entered a birth date on this device. If something looks wrong, ask a guardian to help from their account.';
  static const String ageGatePendingGuardianTitle = 'We need a guardian';
  static const String ageGatePendingGuardianBody =
      'Your account is ready for lessons, but chat, Village, and purchases stay paused until a guardian approves.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ageTierService ?? AgeTierService();
    final selectedDate = useState<DateTime?>(debugPrefilledBirthDate);
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
      final dob = selectedDate.value;
      if (dob == null) {
        errorText.value = 'Choose your date of birth to continue.';
        return;
      }
      submitting.value = true;
      errorText.value = null;
      blockedRetry.value = false;
      pendingGuardian.value = false;
      try {
        final result = await service.assignBirthDate(
          birthYear: dob.year,
          birthMonth: dob.month,
          birthDay: dob.day,
          deviceKey: await deviceKey(),
        );
        if (!result.ok) {
          if (result.code == 'AGE_RETRY_BLOCKED') {
            blockedRetry.value = true;
            errorText.value = ageGateBlocked;
          } else {
            errorText.value =
                result.message ?? 'We could not save that date. Try again.';
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
      final initial =
          selectedDate.value ?? DateTime(now.year - 18, now.month, now.day);
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1920),
        lastDate: now,
        helpText: ageGateTitle,
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
            title: ageGatePendingGuardianTitle,
            body: ageGatePendingGuardianBody,
            primaryLabel: 'Continue to lessons',
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
                    ageGateTitle,
                    style: PanAfricanTypography.headlineSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md.h),
                  Text(
                    ageGateBody,
                    style: PanAfricanTypography.bodyLarge(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg.h),
                  Semantics(
                    button: true,
                    label:
                        'Date of birth, ${selectedDate.value != null ? _formatDob(selectedDate.value!) : 'not selected'}',
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
                                  selectedDate.value != null
                                      ? _formatDob(selectedDate.value!)
                                      : 'Select date of birth',
                                  style: PanAfricanTypography.titleMedium(
                                    context,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_month,
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
                              'Continue',
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

  static String _formatDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
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
