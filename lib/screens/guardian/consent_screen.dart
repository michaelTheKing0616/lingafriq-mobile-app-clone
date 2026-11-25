import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

// Local named constants for the handful of sizes/weights this screen needs
// that aren't already covered by a PanAfricanSpacing/PanAfricanRadius token.
// Keeping them here (rather than inline literals) is what makes every usage
// below self-documenting instead of a bare magic number.
const double _heroIconSize = 24;
const double _heroRingWidth = 2;
const double _heroBadgeTintAlpha = 0.14;
const double _eyebrowLetterSpacing = 0.8;
const double _bodyLineHeight = 1.45;
const double _bannerIconSize = 20;
const double _successIconSize = 28;
const double _spinnerSize = 22;
const double _spinnerStrokeWidth = 2;
const double _attestationBorderWidth = 1;
const double _attestationBorderWidthChecked = 1.5;
const double _successCardAccentWidth = 4;
const double _entranceBeginScale = 0.92;
const Duration _entranceDuration = Duration(milliseconds: 280);

/// Copy keys: guardian.consent.body, guardian.withdraw.confirm (P9-913).
/// Reference: Google Family Link's parental-consent screen — hero identity
/// block, a single attested statement, one primary action, and a persistent
/// status card once consent is granted. Recoloured with the Pan-African
/// palette; no Family Link copy, icons, or layout code is reused verbatim.
class GuardianConsentScreen extends HookConsumerWidget {
  const GuardianConsentScreen({
    super.key,
    required this.childUserId,
    required this.initialStatus,
    this.regime,
    this.guardianLinkService,
    this.onChanged,
    this.connectivityCheck,
  });

  final int childUserId;
  final String initialStatus;
  final String? regime;
  final GuardianLinkService? guardianLinkService;
  final Future<void> Function()? onChanged;

  /// Injectable connectivity probe so this screen can show an honest
  /// "you're offline" affordance before the guardian even taps submit,
  /// not just after the fact. Defaults to the shared [ConnectivityService]
  /// and is overridden with a fake in widget tests.
  final Future<bool> Function()? connectivityCheck;

  static const String consentTitle = 'Guardian consent';

  static const String headlineNeedsConsent =
      'Give your consent to unlock social features';
  static const String headlineActive = 'Consent is active';
  static const String headlineWithdrawn = 'Consent withdrawn';
  static const String headlineUnknown = 'Checking consent status';

  static const String consentBodyNdpr =
      "Under NDPA 2023, we need your confirmation as this learner's parent or legal "
      'guardian. Agreeing to our child safety policy unlocks chat, Village, and '
      "purchases — and you're free to turn it off again anytime.";
  static const String consentBodyGdpr =
      'Under GDPR Article 8, we need confirmation of your parental responsibility '
      'before we process the data chat, Village, and purchases rely on. You stay '
      'in control and can withdraw whenever you choose.';
  static const String consentBodyCoppa =
      "Under COPPA, we need your confirmation as this learner's parent or guardian. "
      'Agreeing allows the limited data use that turns chat, Village, and purchases '
      'on for this account.';

  static const String attestationLabel =
      "I'm this learner's parent or legal guardian, and I agree to the policy shown above.";
  static const String validationErrorCopy =
      'Confirm the statement above to continue.';

  static const String withdrawTitle = 'Withdraw consent?';
  static const String withdrawBody =
      'Chat, Village, and purchases turn off for this learner within about a minute. '
      "Any data handling that requires is queued under our privacy policy — you're "
      'always back in control whenever you want to approve again.';

  static const String offlineBeforeSubmitCopy =
      "You're offline right now. We'll save your answer on this device and finish "
      "the moment you're back online.";
  static const String queuedOfflineCopy =
      "Saved on this device. We'll finish this when you're back online.";
  static const String genericErrorCopy =
      "We couldn't save that. Give it another try in a moment.";
  static const String unknownStatusCopy =
      "We don't recognise this consent status yet. Head back to the family hub and "
      'reopen this learner to refresh it.';

  static const String giveConsentAgainLabel = 'Give consent again';
  static const String backToFamilyHubLabel = 'Back to family hub';
  static const String approveButtonLabel = 'Approve and unlock';
  static const String withdrawButtonLabel = 'Withdraw consent';

  // Note on scope: this screen is guardian-only (never opened by the learner
  // account) and *is itself* the guardian-only consent control surface, so a
  // separate "child mode" / "locked" state is not applicable here — locking
  // belongs to learner-facing screens such as GuardianDailyLimitReachedScreen
  // in limits_progress_screen.dart.

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

  static const String _activeSubtext =
      "Thanks for keeping this learner's experience safe. Manage your choice "
      'anytime below.';

  String _withdrawnSubtext(int childUserId) =>
      'Social features stay off for learner #$childUserId until you approve '
      'again. Pick this up whenever you and the family are ready.';

  static const String _unknownSubtext =
      "Let's get this sorted so social features reflect your latest choice.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final checkConnectivity = connectivityCheck ?? ConnectivityService.hasInternet;
    final service = guardianLinkService ?? GuardianLinkService(isOnline: checkConnectivity);

    final attestation = useState(false);
    final submitting = useState(false);
    final submitState = useState<GuardianSubmitState?>(null);
    final status = useState(initialStatus);
    final errorText = useState<String?>(null);
    final isOffline = useState(false);

    Future<void> refreshConnectivity() async {
      final online = await checkConnectivity();
      isOffline.value = !online;
    }

    useEffect(() {
      refreshConnectivity();
      return null;
    }, const []);

    Future<void> giveConsent() async {
      if (!attestation.value) {
        errorText.value = validationErrorCopy;
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
          if (!reducedMotion) {
            // Fire-and-forget: haptics are best-effort feedback, never a
            // blocking dependency, and some test harnesses lack the channel.
            HapticFeedback.mediumImpact().catchError((_) {});
          }
          await onChanged?.call();
        }
      } finally {
        submitting.value = false;
        await refreshConnectivity();
      }
    }

    Future<void> confirmWithdraw() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(withdrawTitle),
          content: Semantics(
            liveRegion: true,
            child: const Text(withdrawBody),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            Semantics(
              button: true,
              label: 'Confirm withdraw consent for learner $childUserId',
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                child: const Text('Withdraw'),
              ),
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
        await refreshConnectivity();
      }
    }

    void giveConsentAgain() {
      attestation.value = false;
      submitState.value = null;
      errorText.value = null;
      status.value = 'verifying';
    }

    final needsConsent = status.value == 'verifying' || status.value == 'invited';
    final isActive = status.value == 'active';
    final isWithdrawn = status.value == 'withdrawn';
    final isUnknownStatus = !needsConsent && !isActive && !isWithdrawn;

    final String headline = isActive
        ? headlineActive
        : isWithdrawn
            ? headlineWithdrawn
            : isUnknownStatus
                ? headlineUnknown
                : headlineNeedsConsent;

    final IconData heroIcon = isActive
        ? Icons.verified_user_rounded
        : isWithdrawn
            ? Icons.pause_circle_outline
            : isUnknownStatus
                ? Icons.help_outline_rounded
                : Icons.shield_outlined;

    final Color heroColor = isWithdrawn || isUnknownStatus
        ? colorScheme.onSurfaceVariant
        : colorScheme.primary;

    // A quiet signature touch, not a reference-app copy: a slim ring around
    // the badge marks a status that's live or awaiting action, and stays
    // neutral once withdrawn or unrecognised, so the accent itself carries
    // meaning. Deliberately reuses `heroColor` (verified >6:1 against
    // colorScheme.surface) rather than a hardcoded Pan-African hex — a fixed
    // hue can't be guaranteed to stay readable against whichever ColorScheme
    // (e.g. ModernGriotColorScheme) is actually live at the app root.
    final Color heroRingColor = isWithdrawn || isUnknownStatus ? colorScheme.outlineVariant : heroColor;

    return Scaffold(
      // Reads from the live theme, same as every other colour in this file —
      // was previously the one orphaned reference to the unused
      // PanAfricanColorScheme, which could silently diverge from whatever
      // ColorScheme (e.g. ModernGriotColorScheme) is actually wired at the
      // app root.
      backgroundColor: colorScheme.surface,
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
              _HeroHeader(
                eyebrow: 'Learner #$childUserId',
                headline: headline,
                icon: heroIcon,
                iconColor: heroColor,
                ringColor: heroRingColor,
              ),
              SizedBox(height: PanAfricanSpacing.sm.h),
              Text(
                needsConsent ? _bodyForRegime(regime) : _bodySubtext(childUserId, isActive, isWithdrawn),
                style: PanAfricanTypography.bodyLarge(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: _bodyLineHeight,
                ),
              ),
              if (isOffline.value) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                _InfoBanner(
                  icon: Icons.cloud_off_outlined,
                  message: offlineBeforeSubmitCopy,
                  background: colorScheme.secondaryContainer,
                  foreground: colorScheme.onSecondaryContainer,
                  semanticsPrefix: 'Offline:',
                ),
              ],
              if (needsConsent) ...[
                SizedBox(height: PanAfricanSpacing.lg.h),
                _AttestationCard(
                  checked: attestation.value,
                  enabled: !submitting.value,
                  onChanged: (v) => attestation.value = v,
                  colorScheme: colorScheme,
                ),
                if (errorText.value != null) ...[
                  SizedBox(height: PanAfricanSpacing.xs.h),
                  _InfoBanner(
                    icon: Icons.error_outline_rounded,
                    message: errorText.value!,
                    background: colorScheme.errorContainer,
                    foreground: colorScheme.onErrorContainer,
                    semanticsPrefix: 'Form error:',
                  ),
                ],
                SizedBox(height: PanAfricanSpacing.md.h),
                Semantics(
                  button: true,
                  label: 'Approve and unlock social features for learner $childUserId',
                  child: ConstrainedBox(
                    // A minimum, not a fixed, height: this keeps the 48dp tap
                    // target on standard text sizes while still letting the
                    // button grow instead of clipping its label when a
                    // guardian has large system text scaling turned on.
                    constraints: BoxConstraints(minHeight: AdaptiveLayout.minTouchTarget.h),
                    child: FilledButton(
                      onPressed: submitting.value ? null : giveConsent,
                      child: submitting.value
                          ? SizedBox(
                              width: _spinnerSize.w,
                              height: _spinnerSize.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: _spinnerStrokeWidth,
                                color: Colors.white,
                              ),
                            )
                          : const Text(approveButtonLabel),
                    ),
                  ),
                ),
              ],
              if (isActive) ...[
                SizedBox(height: PanAfricanSpacing.lg.h),
                _SuccessCard(
                  childUserId: childUserId,
                  animate: !reducedMotion,
                  colorScheme: colorScheme,
                ),
                SizedBox(height: PanAfricanSpacing.lg.h),
                Semantics(
                  button: true,
                  label: 'Withdraw consent for learner $childUserId',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: AdaptiveLayout.minTouchTarget.h),
                    child: OutlinedButton(
                      onPressed: submitting.value ? null : confirmWithdraw,
                      style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                      child: submitting.value
                          ? SizedBox(
                              width: _spinnerSize.w,
                              height: _spinnerSize.w,
                              child: CircularProgressIndicator(
                                strokeWidth: _spinnerStrokeWidth,
                                color: colorScheme.error,
                              ),
                            )
                          : const Text(withdrawButtonLabel),
                    ),
                  ),
                ),
              ],
              if (isWithdrawn) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                Semantics(
                  button: true,
                  label: 'Give consent again for learner $childUserId',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: AdaptiveLayout.minTouchTarget.h),
                    child: OutlinedButton(
                      onPressed: giveConsentAgain,
                      child: const Text(giveConsentAgainLabel),
                    ),
                  ),
                ),
              ],
              if (isUnknownStatus) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                _InfoBanner(
                  icon: Icons.help_outline_rounded,
                  message: unknownStatusCopy,
                  background: colorScheme.surfaceContainerHighest,
                  foreground: colorScheme.onSurfaceVariant,
                  semanticsPrefix: 'Notice:',
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                // Turns the "head back to the family hub" instruction above
                // from plain text into a one-tap escape hatch, instead of
                // leaving the guardian to hunt for the app bar's back arrow.
                Semantics(
                  button: true,
                  label: backToFamilyHubLabel,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: AdaptiveLayout.minTouchTarget.h),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text(backToFamilyHubLabel),
                    ),
                  ),
                ),
              ],
              if (submitState.value == GuardianSubmitState.queuedOffline) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                _InfoBanner(
                  icon: Icons.cloud_queue_outlined,
                  message: queuedOfflineCopy,
                  background: colorScheme.secondaryContainer,
                  foreground: colorScheme.onSecondaryContainer,
                  semanticsPrefix: 'Saved offline:',
                ),
              ],
              if (submitState.value == GuardianSubmitState.error) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                _InfoBanner(
                  icon: Icons.error_outline_rounded,
                  message: genericErrorCopy,
                  background: colorScheme.errorContainer,
                  foreground: colorScheme.onErrorContainer,
                  semanticsPrefix: 'Error:',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _bodySubtext(int childUserId, bool isActive, bool isWithdrawn) {
    if (isActive) return _activeSubtext;
    if (isWithdrawn) return _withdrawnSubtext(childUserId);
    return _unknownSubtext;
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.eyebrow,
    required this.headline,
    required this.icon,
    required this.iconColor,
    required this.ringColor,
  });

  final String eyebrow;
  final String headline;
  final IconData icon;
  final Color iconColor;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AdaptiveLayout.minTouchTarget.w,
          height: AdaptiveLayout.minTouchTarget.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: _heroBadgeTintAlpha),
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: _heroRingWidth),
          ),
          child: Icon(icon, size: _heroIconSize.sp, color: iconColor),
        ),
        SizedBox(width: PanAfricanSpacing.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: iconColor,
                  letterSpacing: _eyebrowLetterSpacing,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xxs.h),
              Semantics(
                header: true,
                child: Text(
                  headline,
                  style: PanAfricanTypography.headlineSmall(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttestationCard extends StatelessWidget {
  const _AttestationCard({
    required this.checked,
    required this.enabled,
    required this.onChanged,
    required this.colorScheme,
  });

  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // CheckboxListTile already merges the checkbox + title into a single,
    // correctly-labelled and checked Semantics node — wrapping it in another
    // Semantics here would just produce a duplicate, conflicting node.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: checked ? colorScheme.primary : colorScheme.outlineVariant,
          width: checked ? _attestationBorderWidthChecked : _attestationBorderWidth,
        ),
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm.w),
        value: checked,
        onChanged: enabled
            ? (v) {
                HapticFeedback.selectionClick().catchError((_) {});
                onChanged(v ?? false);
              }
            : null,
        title: Text(
          GuardianConsentScreen.attestationLabel,
          style: PanAfricanTypography.bodyMedium(context),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.childUserId,
    required this.animate,
    required this.colorScheme,
  });

  final int childUserId;
  final bool animate;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md.w),
      decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          // Same signature-accent idea as the hero ring, carried onto the
          // card that confirms a guardian's choice took effect. Uses
          // `onPrimaryContainer` — the same ink already used for this card's
          // own title/body text below, so it's guaranteed (by the same M3
          // pairing that keeps that text legible) to read clearly against
          // `primaryContainer`, in light or dark mode, under any live theme.
          border: Border(
            left: BorderSide(color: colorScheme.onPrimaryContainer, width: _successCardAccentWidth),
          ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: _successIconSize.sp,
            color: colorScheme.onPrimaryContainer,
          ),
          SizedBox(width: PanAfricanSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's unlocked",
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs.h),
                Text(
                  'Chat, Village, and purchases are unlocked for learner #$childUserId. '
                  "You're always in control — withdraw anytime below.",
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!animate) {
      return Semantics(liveRegion: true, child: content);
    }

    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _entranceBeginScale, end: 1),
        duration: _entranceDuration,
        curve: Curves.easeOutCubic,
        builder: (_, scale, child) => Opacity(
          opacity: ((scale - _entranceBeginScale) / (1 - _entranceBeginScale)).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        ),
        child: content,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
    required this.semanticsPrefix,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;
  final String semanticsPrefix;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$semanticsPrefix $message',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: _bannerIconSize.sp, color: foreground),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: Text(
                  message,
                  style: PanAfricanTypography.bodyMedium(context).copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
