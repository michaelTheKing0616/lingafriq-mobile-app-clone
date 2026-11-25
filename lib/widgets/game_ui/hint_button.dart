import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class HintButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool coolingDown;

  const HintButton({
    super.key,
    required this.onPressed,
    this.label = 'Hint',
    this.coolingDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: coolingDown ? null : onPressed,
      icon: Icon(coolingDown ? Icons.hourglass_bottom_rounded : Icons.lightbulb_outline_rounded),
      label: Text(
        coolingDown ? '$label (cooldown)' : label,
        style: PanAfricanTypography.labelMedium(context),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: context.panSecondary),
        foregroundColor: context.panSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
      ),
    );
  }
}
