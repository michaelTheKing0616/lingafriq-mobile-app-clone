import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart' show PanAfricanSpacing, PanAfricanRadius;
import 'path_scene_art.dart';

/// L10n keys (resolved in ARB): [kPathUnitBannerKey], [kPathPreviewSheetKey].
const String kPathUnitBannerKey = 'learn.f_007.unit';

/// Unit boundary banner on the learning path (P7-952 AC1).
///
/// Optionally shows a small African "path scene" illustration strip above
/// the unit title (e.g. a Yoruba drummer, a Zulu beadworker) so each unit
/// feels like a place along the journey, not just a text divider. Disabled
/// by default (`showSceneArt: false`) so existing call sites render exactly
/// as before.
class PathSectionBanner extends StatelessWidget {
  const PathSectionBanner({
    super.key,
    required this.unitName,
    required this.cefrLevel,
    required this.canDoStatement,
    this.showSceneArt = false,
    this.languageKey,
    this.unitIndex = 0,
    this.sceneDimmed = false,
    this.bundleLicensed = true,
  });

  final String unitName;
  final String cefrLevel;
  final String canDoStatement;

  /// When true, renders a [PathSceneArtSlot] strip above the title row.
  final bool showSceneArt;
  final String? languageKey;
  final int unitIndex;

  /// True when this unit is still ahead of the learner (future, dimmed art).
  final bool sceneDimmed;

  /// True once the scenery asset bundle has cleared licensing; when false,
  /// [PathSceneArtSlot] falls back to a labelled placeholder (never a blank
  /// or broken image).
  final bool bundleLicensed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$unitName. $cefrLevel. $canDoStatement',
      header: true,
      // Without this, a screen reader re-announces the unit name, CEFR
      // level, and can-do statement a second time via the nested `Text`
      // widgets below, right after reading this label — the same content
      // read twice back-to-back (mirrors the fix already applied to
      // `PathNodeWidget`'s own Semantics node).
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSceneArt)
              SizedBox(
                height: 64.h,
                width: double.infinity,
                child: PathSceneArtSlot(
                  languageKey: languageKey,
                  unitIndex: unitIndex,
                  dimmed: sceneDimmed,
                  bundleLicensed: bundleLicensed,
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm + 2.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unitName,
                          style: ModernGriotTypography.titleSmall(context: context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.xs + 2.w,
                          vertical: PanAfricanSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: PanAfricanRadius.mdBR,
                        ),
                        child: Text(
                          cefrLevel,
                          style: ModernGriotTypography.labelMedium(context: context).copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (canDoStatement.isNotEmpty) ...[
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      canDoStatement,
                      style: ModernGriotTypography.bodyMedium(context: context).copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
