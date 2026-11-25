import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/models/coaching_pattern.dart';
import 'package:lingafriq/services/tutorials/jit_coaching_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Non-blocking coaching banner (P7-943). Does not intercept lesson taps.
class CoachingTip extends StatelessWidget {
  const CoachingTip({
    super.key,
    required this.session,
    required this.onDismiss,
    this.isOffline = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final JitCoachingTipSession session;
  final VoidCallback onDismiss;
  final bool isOffline;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (session.visibility != JitCoachingVisibility.tip) {
      return const SizedBox.shrink(key: ValueKey('coach-hidden'));
    }

    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tipColor = theme.colorScheme.tertiaryContainer;
    final onTip = theme.colorScheme.onTertiaryContainer;

    Widget banner = Material(
      key: const ValueKey('coach-tip'),
      color: tipColor.withValues(alpha: isOffline ? 0.92 : 1),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _body(context, onTip)),
            SizedBox(width: PanAfricanSpacing.sm),
            Semantics(
              label: CoachingCopyKeys.defaultDismiss,
              button: true,
              child: SizedBox(
                width: 48,
                height: 48,
                child: TextButton(
                  onPressed: isLoading ? null : onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.tertiary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(CoachingCopyKeys.defaultDismiss),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion && !isLoading && errorMessage == null) {
      banner = banner
          .animate()
          .fadeIn(duration: 220.ms, curve: Curves.easeOut)
          .slideY(begin: 0.08, end: 0, duration: 220.ms, curve: Curves.easeOut);
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: _semanticsLabel(session.pattern),
      child: banner,
    );
  }

  String _semanticsLabel(CoachingPattern pattern) {
    final parts = <String>[pattern.title, pattern.body, pattern.formHint];
    if (isOffline) {
      parts.add('Offline — tip text is saved on your device.');
    }
    if (errorMessage != null) {
      parts.add(errorMessage!);
    }
    return parts.join('. ');
  }

  Widget _body(BuildContext context, Color onTip) {
    if (isLoading) {
      return Row(
        key: const ValueKey('coach-loading'),
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: onTip,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Text(
            'Loading coaching tip…',
            style: PanAfricanTypography.bodyMedium(context).copyWith(color: onTip),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return Text(
        errorMessage!,
        key: const ValueKey('coach-error'),
        style: PanAfricanTypography.bodyMedium(context).copyWith(color: onTip),
      );
    }

    final pattern = session.pattern;
    return Column(
      key: const ValueKey('coach-default'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pattern.title,
          style: PanAfricanTypography.titleSmall(context).copyWith(color: onTip),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          pattern.body,
          style: PanAfricanTypography.bodyMedium(context).copyWith(color: onTip),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          pattern.formHint,
          style: PanAfricanTypography.bodySmall(context).copyWith(
            color: onTip,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isOffline) ...[
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            'You are offline. This tip stays on screen until you dismiss it.',
            style: PanAfricanTypography.bodySmall(context).copyWith(color: onTip),
          ),
        ],
      ],
    );
  }
}
