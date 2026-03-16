import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final bool broken;

  const StreakBadge({
    super.key,
    required this.streak,
    this.broken = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = broken ? PanAfricanColors.warning : PanAfricanColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(broken ? Icons.heart_broken_rounded : Icons.local_fire_department_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'x$streak',
            style: PanAfricanTypography.labelMedium(context).copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
