import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Educational card surfacing cultural context during gameplay.
///
/// Styled as a "Griot's Note" / "Elder's Advice" with a warm
/// surface-container-low background. Contains a [title], a [body] text,
/// an optional leading [icon], and an optional "Read More" action.
class GameCulturalNoteCard extends StatelessWidget {
  /// Card title (e.g. "Griot's Note", "Elder's Advice", "Cultural Insight").
  final String title;

  /// The educational content.
  final String body;

  /// Leading icon displayed beside the title. Defaults to a book icon.
  final IconData? icon;

  /// Called when the "Read More" action is tapped. When null the action
  /// is hidden.
  final VoidCallback? onReadMore;

  const GameCulturalNoteCard({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIcon = icon ?? Icons.auto_stories_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: PanAfricanColors.secondary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.xs),
            decoration: BoxDecoration(
              color: PanAfricanColors.secondary.withOpacity(0.15),
              borderRadius: PanAfricanRadius.mdBR,
            ),
            child: Icon(
              effectiveIcon,
              size: 24.sp,
              color: PanAfricanColors.secondaryDark,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.titleSmall(context).copyWith(
                    color: PanAfricanColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  body,
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
                if (onReadMore != null) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  GestureDetector(
                    onTap: onReadMore,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read More',
                          style:
                              PanAfricanTypography.labelLarge(context).copyWith(
                            color: cs.primary,
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.xxxs),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16.sp,
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
