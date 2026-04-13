import 'package:flutter/material.dart';
import 'package:lingafriq/theme/stitch_theme_extensions.dart';

/// Primary FLB CTA — terracotta gradient, sharp corners per DESIGN.md.
class StitchTerracottaCta extends StatelessWidget {
  const StitchTerracottaCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final flb = context.flbEditorial;
    if (flb == null) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: flb.terracottaCtaGradient,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: flb.ambientShadow,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: flb.onTerracotta, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: flb.onTerracotta,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
