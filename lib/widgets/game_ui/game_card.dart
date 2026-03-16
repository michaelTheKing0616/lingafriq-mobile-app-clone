import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

enum GameCardState { normal, selected, correct, incorrect, disabled }

class GameCard extends StatelessWidget {
  final Widget child;
  final GameCardState state;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const GameCard({
    super.key,
    required this.child,
    this.state = GameCardState.normal,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;

    Color borderColor = isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight;
    Color bg = baseBg;
    switch (state) {
      case GameCardState.selected:
        borderColor = PanAfricanColors.primary;
        bg = PanAfricanColors.primary.withOpacity(0.08);
        break;
      case GameCardState.correct:
        borderColor = PanAfricanColors.success;
        bg = PanAfricanColors.success.withOpacity(0.12);
        break;
      case GameCardState.incorrect:
        borderColor = PanAfricanColors.error;
        bg = PanAfricanColors.error.withOpacity(0.12);
        break;
      case GameCardState.disabled:
        bg = baseBg.withOpacity(0.5);
        break;
      case GameCardState.normal:
        break;
    }

    return Opacity(
      opacity: state == GameCardState.disabled ? 0.7 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        onTap: state == GameCardState.disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            border: Border.all(color: borderColor),
            boxShadow: PanAfricanShadows.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}
