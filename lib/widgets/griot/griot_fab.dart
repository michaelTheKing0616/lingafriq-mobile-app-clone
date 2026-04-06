import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Floating action button with the signature gradient and an ambient
/// primary-tinted shadow (15% opacity, 30px blur).
///
/// ```dart
/// GriotFab(
///   icon: Icons.add_rounded,
///   onPressed: () => _createNew(),
/// )
/// ```
class GriotFab extends StatelessWidget {
  const GriotFab({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.heroTag,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// FAB diameter. Defaults to 56.
  final double? size;

  /// Hero tag for animation across routes. Avoids conflicts with multiple FABs.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fabSize = (size ?? 56).r;

    return GestureDetector(
      onTap: onPressed != null
          ? () {
              HapticFeedback.mediumImpact();
              onPressed!();
            }
          : null,
      child: Container(
        width: fabSize,
        height: fabSize,
        decoration: BoxDecoration(
          gradient: ModernGriotGradients.signatureGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(38),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24.sp,
          color: cs.onPrimary,
        ),
      ),
    );
  }
}
