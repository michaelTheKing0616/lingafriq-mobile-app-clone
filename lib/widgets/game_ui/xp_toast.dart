import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class XpToast extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const XpToast({
    super.key,
    required this.message,
    this.icon = Icons.bolt_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? PanAfricanColors.secondary;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tint.withOpacity(0.92),
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          boxShadow: PanAfricanShadows.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: PanAfricanTypography.labelLarge(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
