import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Large rounded card that displays a game prompt or question.
///
/// Uses an xl (24) corner radius and a surface-container-low background
/// to create a soft, elevated feel. Supports an optional [subtitle],
/// [hint], and a [leading] widget (icon or image) above the question.
class GameQuestionCard extends StatelessWidget {
  /// The primary question or prompt text.
  final String question;

  /// Optional smaller text displayed below the question (e.g. translation).
  final String? subtitle;

  /// Optional hint text shown at the bottom in a muted style.
  final String? hint;

  /// Optional widget placed above the question (icon, image, or audio button).
  final Widget? leading;

  /// Minimum height for the card. Defaults to 180.
  final double? minHeight;

  const GameQuestionCard({
    super.key,
    required this.question,
    this.subtitle,
    this.hint,
    this.leading,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight ?? 180.h),
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: PanAfricanRadius.xlBR,
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(height: PanAfricanSpacing.md),
          ],
          Text(
            question,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.headlineSmall(context).copyWith(
              color: cs.onSurface,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyLarge(context).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (hint != null) ...[
            SizedBox(height: PanAfricanSpacing.md),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.sm,
                vertical: PanAfricanSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14.sp,
                    color: PanAfricanColors.secondary,
                  ),
                  SizedBox(width: PanAfricanSpacing.xxs),
                  Flexible(
                    child: Text(
                      hint!,
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
