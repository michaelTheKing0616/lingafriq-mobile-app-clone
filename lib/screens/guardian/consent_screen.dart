import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: guardian.consent.body, guardian.withdraw.confirm (P9-913).
class GuardianConsentScreen extends HookConsumerWidget {
  const GuardianConsentScreen({
    super.key,
    required this.childUserId,
    required this.initialStatus,
    this.regime,
    this.guardianLinkService,
    this.onChanged,
  });

  final int childUserId;
  final String initialStatus;
  final String? regime;
  final GuardianLinkService? guardianLinkService;
  final Future<void> Function()? onChanged;

  static const String consentTitle = 'Guardian consent';
  static const String consentBodyNdpr =
      'Under NDPA 2023, you confirm you are the parent or legal guardian for this learner '
      'and agree to our child safety policy before social features unlock.';
  static const String consentBodyGdpr =
      'Under GDPR Article 8, you confirm parental responsibility and consent to processing '
      'needed for chat, Village, and purchases.';
  static const String consentBodyCoppa =
      'Under COPPA, you confirm you are the parent or guardian and consent to limited '
      'data use for this learner account.';
  static const String attestationLabel =
      'I am the parent or legal guardian and I agree to the current policy version.';
  static const String withdrawTitle = 'Withdraw consent?';
  static const String withdrawBody =
      'Chat, Village, and purchases turn off within about a minute. We queue any required '
      'data handling per our privacy policy.';
  static const String queuedOfflineCopy =
      'Saved on this device. We will finish when you are back online.';

  String _bodyForRegime(String? regimeCode) {
    switch (regimeCode) {
      case 'GDPR_ART_8':
        return consentBodyGdpr;
      case 'COPPA':
        return consentBodyCoppa;
      default:
        return consentBodyNdpr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = guardianLinkService ?? GuardianLinkService();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attestation = useState(false);
    final submitting = useState(false);
    final submitState = useState<GuardianSubmitState?>(null);
    final status = useState(initialStatus);
    final errorText = useState<String?>(null);

    Future<void> giveConsent() async {
      if (!attestation.value) {
        errorText.value = 'Confirm the statement above to continue.';
        return;
      }
      submitting.value = true;
      errorText.value = null;
      submitState.value = null;
      try {
        final result = await service.submitConsent(
          childUserId: childUserId,
          attestationConfirmed: true,
        );
        submitState.value = result;
        if (result == GuardianSubmitState.sent) {
          status.value = 'active';
          await onChanged?.call();
        }
      } finally {
        submitting.value = false;
      }
    }

    Future<void> confirmWithdraw() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(withdrawTitle),
          content: const Text(withdrawBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: const Text('Withdraw'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      submitting.value = true;
      submitState.value = null;
      try {
        final result = await service.withdrawConsent(childUserId: childUserId);
        submitState.value = result;
        if (result == GuardianSubmitState.sent) {
          status.value = 'withdrawn';
          await onChanged?.call();
        }
      } finally {
        submitting.value = false;
      }
    }

    final needsConsent = status.value == 'verifying' || status.value == 'invited';
    final isActive = status.value == 'active';

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(title: const Text(consentTitle)),
      body: ResponsiveSafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg.w,
            vertical: PanAfricanSpacing.lg.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Learner #$childUserId',
                style: PanAfricanTypography.headlineSmall(context).copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: PanAfricanSpacing.sm.h),
              Text(
                _bodyForRegime(regime),
                style: PanAfricanTypography.bodyLarge(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (needsConsent) ...[
                SizedBox(height: PanAfricanSpacing.lg.h),
                Semantics(
                  checked: attestation.value,
                  label: attestationLabel,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: attestation.value,
                    onChanged: submitting.value ? null : (v) => attestation.value = v ?? false,
                    title: Text(
                      attestationLabel,
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                if (errorText.value != null) ...[
                  Text(
                    errorText.value!,
                    style: PanAfricanTypography.bodyMedium(context).copyWith(color: colorScheme.error),
                  ),
                ],
                SizedBox(height: PanAfricanSpacing.md.h),
                SizedBox(
                  height: 48.h,
                  child: FilledButton(
                    onPressed: submitting.value ? null : giveConsent,
                    child: submitting.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Approve and unlock'),
                  ),
                ),
              ],
              if (isActive) ...[
                SizedBox(height: PanAfricanSpacing.lg.h),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined, color: colorScheme.primary),
                      SizedBox(height: PanAfricanSpacing.sm.h),
                      Text(
                        'Consent is active. Social features are on for this learner.',
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ],
                  ),
                ),
                ),
                SizedBox(height: PanAfricanSpacing.lg.h),
                SizedBox(
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: submitting.value ? null : confirmWithdraw,
                    style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                    child: const Text('Withdraw consent'),
                  ),
                ),
              ],
              if (status.value == 'withdrawn')
                Padding(
                  padding: EdgeInsets.only(top: PanAfricanSpacing.lg.h),
                  child: Text(
                    'Consent withdrawn. Social features stay off until you approve again.',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (submitState.value == GuardianSubmitState.queuedOffline) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                Text(
                  queuedOfflineCopy,
                  style: PanAfricanTypography.bodyMedium(context).copyWith(color: colorScheme.primary),
                ),
              ],
              if (submitState.value == GuardianSubmitState.error) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                Text(
                  'Something went wrong. Try again in a moment.',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(color: colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
