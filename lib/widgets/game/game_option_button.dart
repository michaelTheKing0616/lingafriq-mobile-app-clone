import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Visual state of a game answer option.
enum GameOptionState {
  /// Default resting state.
  idle,

  /// User has selected this option, awaiting validation.
  selected,

  /// Answer was correct.
  correct,

  /// Answer was wrong.
  wrong,
}

/// A selectable answer option button with four visual states.
///
/// Provides distinct styling for [idle], [selected], [correct], and [wrong]
/// states. Includes haptic feedback on tap and a subtle shake animation
/// when the answer is wrong.
class GameOptionButton extends StatefulWidget {
  /// The primary answer text.
  final String label;

  /// Optional secondary text (e.g. transliteration).
  final String? sublabel;

  /// Current visual state of the button.
  final GameOptionState state;

  /// Called when the button is tapped. Null disables the button.
  final VoidCallback? onTap;

  /// Optional leading icon.
  final IconData? icon;

  const GameOptionButton({
    super.key,
    required this.label,
    this.sublabel,
    this.state = GameOptionState.idle,
    this.onTap,
    this.icon,
  });

  @override
  State<GameOptionButton> createState() => _GameOptionButtonState();
}

class _GameOptionButtonState extends State<GameOptionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(GameOptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == GameOptionState.wrong &&
        oldWidget.state != GameOptionState.wrong) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
    }
    if (widget.state == GameOptionState.correct &&
        oldWidget.state != GameOptionState.correct) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolved = _resolveStyle(cs);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap != null
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.md,
          ),
          decoration: BoxDecoration(
            color: resolved.background,
            borderRadius: PanAfricanRadius.lgBR,
            border: Border.all(
              color: resolved.borderColor,
              width: resolved.borderWidth,
            ),
            boxShadow: widget.state == GameOptionState.idle
                ? PanAfricanShadows.sm
                : PanAfricanShadows.none,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 22.sp, color: resolved.foreground),
                SizedBox(width: PanAfricanSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        color: resolved.foreground,
                      ),
                    ),
                    if (widget.sublabel != null) ...[
                      SizedBox(height: PanAfricanSpacing.xxxs),
                      Text(
                        widget.sublabel!,
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: resolved.foreground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.state == GameOptionState.correct)
                Icon(Icons.check_circle_rounded,
                    color: resolved.trailingColor, size: 24.sp),
              if (widget.state == GameOptionState.wrong)
                Icon(Icons.cancel_rounded,
                    color: resolved.trailingColor, size: 24.sp),
              if (widget.state == GameOptionState.selected)
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary, width: 2.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _OptionStyle _resolveStyle(ColorScheme cs) {
    switch (widget.state) {
      case GameOptionState.idle:
        return _OptionStyle(
          background: cs.surfaceContainerLowest,
          borderColor: cs.outlineVariant,
          borderWidth: 1.0,
          foreground: cs.onSurface,
          trailingColor: Colors.transparent,
        );
      case GameOptionState.selected:
        return _OptionStyle(
          background: cs.primaryContainer.withOpacity(0.3),
          borderColor: cs.primary,
          borderWidth: 2.0,
          foreground: cs.onSurface,
          trailingColor: cs.primary,
        );
      case GameOptionState.correct:
        return _OptionStyle(
          background: PanAfricanColors.success.withOpacity(0.12),
          borderColor: PanAfricanColors.success,
          borderWidth: 2.0,
          foreground: PanAfricanColors.success,
          trailingColor: PanAfricanColors.success,
        );
      case GameOptionState.wrong:
        return _OptionStyle(
          background: PanAfricanColors.error.withOpacity(0.12),
          borderColor: PanAfricanColors.error,
          borderWidth: 2.0,
          foreground: PanAfricanColors.error,
          trailingColor: PanAfricanColors.error,
        );
    }
  }
}

class _OptionStyle {
  final Color background;
  final Color borderColor;
  final double borderWidth;
  final Color foreground;
  final Color trailingColor;

  const _OptionStyle({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.foreground,
    required this.trailingColor,
  });
}
