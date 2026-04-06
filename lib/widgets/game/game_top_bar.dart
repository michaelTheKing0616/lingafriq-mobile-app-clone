import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Game-mode top bar replacing the standard app bar.
///
/// Provides a close button on the left, a progress indicator in the center,
/// and streak + XP counters on the right. Designed for immersive game screens
/// where bottom navigation is hidden.
class GameTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Called when the close (X) button is tapped.
  final VoidCallback onClose;

  /// Linear progress from 0.0 to 1.0. Ignored when [currentStep] is provided.
  final double progress;

  /// Current step index (1-based) for step-based progress display.
  final int? currentStep;

  /// Total number of steps for step-based progress display.
  final int? totalSteps;

  /// Current daily streak count.
  final int streak;

  /// Current XP amount to display.
  final int xp;

  const GameTopBar({
    super.key,
    required this.onClose,
    this.progress = 0.0,
    this.currentStep,
    this.totalSteps,
    this.streak = 0,
    this.xp = 0,
  });

  bool get _useSteps => currentStep != null && totalSteps != null && totalSteps! > 0;

  double get _effectiveProgress {
    if (_useSteps) return currentStep! / totalSteps!;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.xs,
        ),
        child: Row(
          children: [
            _buildCloseButton(cs),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(child: _buildProgressIndicator(context, cs)),
            SizedBox(width: PanAfricanSpacing.sm),
            _buildStats(context, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(ColorScheme cs) {
    return SizedBox(
      width: 40.w,
      height: 40.w,
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onClose();
        },
        icon: Icon(PanAfricanIcons.close, size: 22.sp),
        style: IconButton.styleFrom(
          backgroundColor: cs.surfaceContainerHigh,
          foregroundColor: cs.onSurface,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        tooltip: 'Close',
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: PanAfricanRadius.roundBR,
          child: LinearProgressIndicator(
            value: _effectiveProgress,
            minHeight: 8.h,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        if (_useSteps) ...[
          SizedBox(height: PanAfricanSpacing.xxxs),
          Text(
            '$currentStep / $totalSteps',
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(BuildContext context, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (streak > 0) ...[
          _StatChip(
            icon: Icons.local_fire_department_rounded,
            value: '$streak',
            iconColor: PanAfricanColors.tertiary,
            backgroundColor: PanAfricanColors.tertiaryContainer,
          ),
          SizedBox(width: PanAfricanSpacing.xxs),
        ],
        _StatChip(
          icon: Icons.star_rounded,
          value: '$xp',
          iconColor: PanAfricanColors.secondary,
          backgroundColor: PanAfricanColors.secondaryContainer,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color iconColor;
  final Color backgroundColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xs,
        vertical: PanAfricanSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16.sp),
          SizedBox(width: PanAfricanSpacing.xxxs),
          Text(
            value,
            style: PanAfricanTypography.labelLarge(context).copyWith(
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
